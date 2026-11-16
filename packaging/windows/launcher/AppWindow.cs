// RGCompanion's window on Windows (G40.12): «Open RedGiant», the icon and the start open the app
// that came with the installer (app\rgcompanion.exe, the Flutter build) instead of the browser,
// already signed in to this RedGiant. The launcher makes a device token for it (POST /api/devices
// with the installation's token: Settings › Devices lists it) and hands it over without the
// command line, which every process can read: a file in the user's own folder whose ACL lets only
// this user in, named by RGCOMPANION_HANDOFF_FILE in the app's environment. The app reads it and
// deletes it at once; a file still there after a minute (the app did not start) is deleted here
// and its device revoked. With the app already open the launcher only brings it to the front
// (no token); without the app, or when something fails, the browser opens as before.
//
// The parts without Windows' windows are tested in test/AppWindowTests.cs.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

static class AppWindow
{
    public const string FileVar = "RGCOMPANION_HANDOFF_FILE";
    /** How long a handoff waits for the app before it is deleted (and its device revoked). */
    public const int HandoffSeconds = 60;

    /** The launcher's log (Diag.Log in RedGiant.exe); never handed a token. */
    public static Action<string> Log = (s) => { };

    public static string Exe(string appDir) { return Path.Combine(appDir, "app", "rgcompanion.exe"); }

    public static bool Present(string appDir) { return File.Exists(Exe(appDir)); }

    /** Where handoffs are written: the user's own local folder, never the program's. */
    public static string HandoffDir
    {
        get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "RedGiant", "handoff"); }
    }

    /** The device's name in Settings › Devices: "RGCompanion (<computer>)", 60 characters at most. */
    public static string DeviceName(string computer)
    {
        var sb = new StringBuilder();
        foreach (char c in computer ?? "")
            if (c >= 32 && c != 127) sb.Append(c);
        string name = sb.ToString().Trim();
        if (name.Length == 0) name = "Windows";
        const string head = "RGCompanion (";
        int room = 60 - head.Length - 1;
        if (name.Length > room) name = name.Substring(0, room).TrimEnd();
        return head + name + ")";
    }

    static readonly JavaScriptSerializer json = new JavaScriptSerializer();

    /** POST /api/devices's body. */
    public static string DeviceBody(string name)
    {
        return json.Serialize(new Dictionary<string, object> { { "name", name }, { "platform", "windows" } });
    }

    /** The token and the device's id in POST /api/devices's answer; false when it is not one. */
    public static bool ParseCreated(string answer, out string token, out string deviceId)
    {
        token = null;
        deviceId = null;
        try
        {
            var root = json.DeserializeObject(answer) as Dictionary<string, object>;
            if (root == null) return false;
            object t, d, id;
            if (!root.TryGetValue("token", out t) || !(t is string) || ((string)t).Length < 16) return false;
            if (!root.TryGetValue("device", out d) || !(d is Dictionary<string, object>)) return false;
            if (!((Dictionary<string, object>)d).TryGetValue("id", out id) || !(id is string)) return false;
            token = (string)t;
            deviceId = (string)id;
            return true;
        }
        catch (Exception) { return false; }
    }

    /** What the app reads (lib/desktop/handoff.dart): this computer's server, always. */
    public static string HandoffJson(int port, string token, string deviceId, string machine)
    {
        return json.Serialize(new Dictionary<string, object>
        {
            { "v", 1 },
            { "address", "http://127.0.0.1:" + port.ToString(CultureInfo.InvariantCulture) },
            { "token", token },
            { "deviceId", deviceId },
            { "machine", machine },
        });
    }

    /**
     * Writes [text] into a new file of [dir] that only this user may open (inheritance cut, one
     * rule: this user, full control) and returns its path. Never over an existing file.
     */
    public static string WriteHandoff(string dir, string text)
    {
        Directory.CreateDirectory(dir);
        var bytes = new byte[16];
        using (var rng = System.Security.Cryptography.RandomNumberGenerator.Create()) rng.GetBytes(bytes);
        string path = Path.Combine(dir, BitConverter.ToString(bytes).Replace("-", "").ToLowerInvariant() + ".json");
        var security = new FileSecurity();
        security.SetAccessRuleProtection(true, false);
        security.AddAccessRule(new FileSystemAccessRule(WindowsIdentity.GetCurrent().User, FileSystemRights.FullControl, AccessControlType.Allow));
        var data = new UTF8Encoding(false).GetBytes(text);
        using (var f = new FileStream(path, FileMode.CreateNew, FileSystemRights.Write, FileShare.None, 4096, FileOptions.None, security))
            f.Write(data, 0, data.Length);
        return path;
    }

    /** Whether only the current user may open [path] (what WriteHandoff promises). */
    public static bool OnlyMine(string path)
    {
        var me = WindowsIdentity.GetCurrent().User;
        var rules = File.GetAccessControl(path).GetAccessRules(true, true, typeof(SecurityIdentifier));
        if (rules.Count == 0) return false;
        foreach (FileSystemAccessRule r in rules)
            if (r.AccessControlType == AccessControlType.Allow && !me.Equals(r.IdentityReference)) return false;
        return true;
    }

    /** Handoffs older than [age] (an app that never started, a launcher stopped halfway). */
    public static int CleanOld(string dir, TimeSpan age)
    {
        int n = 0;
        try
        {
            if (!Directory.Exists(dir)) return 0;
            foreach (var f in Directory.GetFiles(dir, "*.json"))
                try
                {
                    if (DateTime.UtcNow - File.GetLastWriteTimeUtc(f) > age) { File.Delete(f); n++; }
                }
                catch (Exception) { }
        }
        catch (Exception) { }
        return n;
    }

    static string Call(string method, string url, string token, string body)
    {
        var req = (HttpWebRequest)WebRequest.Create(url);
        req.Method = method;
        req.Timeout = 5000;
        // No «Expect: 100-continue» pause before the body.
        req.ServicePoint.Expect100Continue = false;
        req.Headers[HttpRequestHeader.Authorization] = "Bearer " + token;
        if (body != null)
        {
            var data = Encoding.UTF8.GetBytes(body);
            req.ContentType = "application/json";
            req.ContentLength = data.Length;
            using (var s = req.GetRequestStream()) s.Write(data, 0, data.Length);
        }
        using (var r = (HttpWebResponse)req.GetResponse())
        using (var reader = new StreamReader(r.GetResponseStream(), Encoding.UTF8))
            return reader.ReadToEnd();
    }

    /** A device token for the app; null when the server says no (the browser then). */
    public static string CreateDevice(int port, string installationToken, string name, out string deviceId)
    {
        deviceId = null;
        try
        {
            string answer = Call("POST", "http://127.0.0.1:" + port + "/api/devices", installationToken, DeviceBody(name));
            string token;
            if (ParseCreated(answer, out token, out deviceId)) return token;
            Log("the server's answer for the app's device was not one");
        }
        catch (Exception e) { Log("no device for the app: " + e.Message); }
        return null;
    }

    public static void RevokeDevice(int port, string installationToken, string deviceId)
    {
        try { Call("DELETE", "http://127.0.0.1:" + port + "/api/devices/" + Uri.EscapeDataString(deviceId), installationToken, null); }
        catch (Exception e) { Log("the app's unused device was not revoked: " + e.Message); }
    }

    /** The app started from [exe], when it runs (this user's processes only). */
    public static Process Running(string exe)
    {
        foreach (var p in Process.GetProcessesByName(Path.GetFileNameWithoutExtension(exe)))
        {
            try
            {
                if (string.Equals(p.MainModule.FileName, exe, StringComparison.OrdinalIgnoreCase)) return p;
            }
            catch (Exception) { }
        }
        return null;
    }

    /**
     * Before an update replaces (or a rollback puts back) app\ (3.8.2): every program started from
     * the installation's app\ folder is asked to close (its window's close, so it can save what it
     * keeps), stopped by force after [graceMs], and waited for, so no file of app\ stays open and
     * the folder can be moved. This user's processes only; an app installed on its own
     * (RGCompanion-Setup.exe, another folder) is left alone. Returns how many were running.
     */
    public static int CloseAll(string appDir, int graceMs)
    {
        string dir = Path.Combine(appDir, "app") + "\\";
        int self = Process.GetCurrentProcess().Id;
        var mine = new List<Process>();
        foreach (var p in Process.GetProcesses())
        {
            try
            {
                if (p.Id != self && p.MainModule.FileName.StartsWith(dir, StringComparison.OrdinalIgnoreCase)) mine.Add(p);
            }
            catch (Exception) { }
        }
        if (mine.Count == 0) return 0;
        foreach (var p in mine)
        {
            try { if (!p.HasExited) p.CloseMainWindow(); } catch (Exception) { }
        }
        var until = DateTime.UtcNow.AddMilliseconds(graceMs);
        foreach (var p in mine)
        {
            try
            {
                int left = (int)Math.Max(0, (until - DateTime.UtcNow).TotalMilliseconds);
                if (p.WaitForExit(left)) { Log("closed before the update: " + p.ProcessName); continue; }
                p.Kill();
                p.WaitForExit(10000);
                Log("stopped before the update (it did not close in time): " + p.ProcessName);
            }
            catch (Exception e) { Log("the app could not be stopped: " + e.Message); }
        }
        return mine.Count;
    }

    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr hWnd);

    static void Front(Process p)
    {
        try
        {
            IntPtr h = p.MainWindowHandle;
            if (h == IntPtr.Zero) return;
            if (IsIconic(h)) ShowWindow(h, 9); // SW_RESTORE
            SetForegroundWindow(h);
        }
        catch (Exception) { }
    }

    /**
     * Opens the app on this RedGiant (any thread but the UI's: it talks to the server). False when
     * the browser must open instead: no app, no token, the app would not start.
     */
    public static bool Open(string appDir, int port, string installationToken)
    {
        string exe = Exe(appDir);
        if (!File.Exists(exe)) return false;
        var running = Running(exe);
        if (running != null)
        {
            Log("the app is open: brought to the front");
            Front(running);
            return true;
        }
        CleanOld(HandoffDir, TimeSpan.FromSeconds(HandoffSeconds));
        string deviceId;
        string token = CreateDevice(port, installationToken, DeviceName(Environment.MachineName), out deviceId);
        if (token == null) return false;
        string file;
        try { file = WriteHandoff(HandoffDir, HandoffJson(port, token, deviceId, Environment.MachineName)); }
        catch (Exception e)
        {
            Log("the handoff could not be written: " + e.Message);
            RevokeDevice(port, installationToken, deviceId);
            return false;
        }
        try
        {
            var info = new ProcessStartInfo(exe) { UseShellExecute = false, WorkingDirectory = Path.GetDirectoryName(exe) };
            info.EnvironmentVariables[FileVar] = file;
            Process.Start(info);
            Log("the app started with its handoff");
        }
        catch (Exception e)
        {
            Log("the app did not start: " + e.Message);
            try { File.Delete(file); } catch (Exception) { }
            RevokeDevice(port, installationToken, deviceId);
            return false;
        }
        // Not taken within the minute: deleted, and the device it was for revoked.
        var watch = new Thread(() =>
        {
            Thread.Sleep(HandoffSeconds * 1000);
            if (!File.Exists(file)) return;
            try { File.Delete(file); } catch (Exception) { }
            Log("the app did not take its handoff: deleted, its device revoked");
            RevokeDevice(port, installationToken, deviceId);
        }) { IsBackground = true };
        watch.Start();
        return true;
    }
}
