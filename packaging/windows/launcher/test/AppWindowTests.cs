// Tests of AppWindow.cs (G40.12), a console program built like the others (ci.yml):
//
//   csc /out:AppWindowTests.exe /r:System.Web.Extensions.dll test\AppWindowTests.cs AppWindow.cs
//   AppWindowTests.exe [AppStub.exe]   with the stand-in app: the whole opening, end to end
//
// The device's name and body, the server's answer, the handoff (a file only this user opens,
// never over another), the old ones cleaned up, and the two calls to a stand-in server.
// Exit code 0 when all pass.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

static class AppWindowTests
{
    static int failed, passed;

    static void Check(bool ok, string what)
    {
        if (ok) passed++;
        else { failed++; Console.WriteLine("FAIL " + what); }
    }

    /** A stand-in for the server: one request per answer, the last one's line, headers and body kept. */
    sealed class OneRequest
    {
        public readonly int Port;
        public string Line, Headers, Body;
        public readonly List<string> Lines = new List<string>();
        readonly TcpListener listener;
        readonly Thread thread;

        public OneRequest(params string[] answers)
        {
            listener = new TcpListener(IPAddress.Loopback, 0);
            listener.Start();
            Port = ((IPEndPoint)listener.LocalEndpoint).Port;
            thread = new Thread(() =>
            {
                foreach (var answer in answers)
                using (var c = listener.AcceptTcpClient())
                using (var s = c.GetStream())
                {
                    var head = new StringBuilder();
                    while (!head.ToString().EndsWith("\r\n\r\n"))
                    {
                        int b = s.ReadByte();
                        if (b < 0) break;
                        head.Append((char)b);
                    }
                    string h = head.ToString();
                    Line = h.Substring(0, h.IndexOf("\r\n", StringComparison.Ordinal));
                    Lines.Add(Line);
                    Headers = h;
                    int length = 0;
                    foreach (var l in h.Split(new[] { "\r\n" }, StringSplitOptions.None))
                        if (l.StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase)) length = int.Parse(l.Substring(15).Trim());
                    var body = new byte[length];
                    for (int got = 0; got < length;) got += s.Read(body, got, length - got);
                    Body = Encoding.UTF8.GetString(body);
                    var data = Encoding.UTF8.GetBytes(answer);
                    var reply = Encoding.ASCII.GetBytes("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " + data.Length + "\r\nConnection: close\r\n\r\n");
                    s.Write(reply, 0, reply.Length);
                    s.Write(data, 0, data.Length);
                }
                listener.Stop();
            }) { IsBackground = true };
            thread.Start();
        }

        public void Done() { thread.Join(10000); }
    }

    static int Main(string[] args)
    {
        // The device's name: what Settings › Devices shows, within the server's 60 characters.
        Check(AppWindow.DeviceName("RIG") == "RGCompanion (RIG)", "the computer's name");
        Check(AppWindow.DeviceName("") == "RGCompanion (Windows)", "no name: Windows");
        Check(AppWindow.DeviceName("A\u0001B\tC") == "RGCompanion (ABC)", "no control characters");
        string longName = AppWindow.DeviceName(new string('x', 200));
        Check(longName.Length <= 60 && longName.EndsWith(")"), "60 characters at most: " + longName.Length);

        var json = new JavaScriptSerializer();
        var body = (Dictionary<string, object>)json.DeserializeObject(AppWindow.DeviceBody("RGCompanion (\"Rig\")"));
        Check((string)body["name"] == "RGCompanion (\"Rig\")" && (string)body["platform"] == "windows", "the body, quotes escaped");

        // The server's answer.
        string token, id;
        Check(AppWindow.ParseCreated("{\"token\":\"rgd_0123456789abcdef\",\"device\":{\"id\":\"d42\",\"name\":\"x\"}}", out token, out id)
            && token == "rgd_0123456789abcdef" && id == "d42", "a device's answer");
        Check(!AppWindow.ParseCreated("{\"error\":\"A device cannot make another\"}", out token, out id), "an error is not a device");
        Check(!AppWindow.ParseCreated("{\"token\":\"short\",\"device\":{\"id\":\"d1\"}}", out token, out id), "a token too short");
        Check(!AppWindow.ParseCreated("not json", out token, out id), "not JSON");
        Check(!AppWindow.ParseCreated("{\"token\":\"rgd_0123456789abcdef\"}", out token, out id), "no device");

        // What the app reads: this computer only.
        var h = (Dictionary<string, object>)json.DeserializeObject(AppWindow.HandoffJson(7601, "rgd_0123456789abcdef", "d42", "RIG"));
        Check((int)h["v"] == 1 && (string)h["address"] == "http://127.0.0.1:7601" && (string)h["token"] == "rgd_0123456789abcdef"
            && (string)h["deviceId"] == "d42" && (string)h["machine"] == "RIG", "the handoff");

        // The file: only this user, never over another, read back as written.
        string dir = Path.Combine(Path.GetTempPath(), "rg-handoff-tests-" + Guid.NewGuid().ToString("N"));
        string a = AppWindow.WriteHandoff(dir, "{\"v\":1,\"x\":\"àé\"}");
        string b = AppWindow.WriteHandoff(dir, "{}");
        Check(a != b, "a new name each time");
        Check(File.ReadAllText(a, Encoding.UTF8) == "{\"v\":1,\"x\":\"àé\"}", "the text, UTF-8 without BOM");
        Check(File.ReadAllBytes(a)[0] == (byte)'{', "no byte order mark");
        Check(AppWindow.OnlyMine(a), "only this user may open it (no inherited rules)");
        Check(File.GetAccessControl(a).AreAccessRulesProtected, "inheritance cut");
        File.Delete(b);
        Check(!File.Exists(b), "this user deletes it (the app does)");
        // Old ones go: a minute without the app.
        File.SetLastWriteTimeUtc(a, DateTime.UtcNow.AddMinutes(-5));
        string fresh = AppWindow.WriteHandoff(dir, "{}");
        Check(AppWindow.CleanOld(dir, TimeSpan.FromSeconds(AppWindow.HandoffSeconds)) == 1, "one old handoff deleted");
        Check(!File.Exists(a) && File.Exists(fresh), "the old one gone, the new one kept");
        Directory.Delete(dir, true);
        Check(AppWindow.CleanOld(dir, TimeSpan.Zero) == 0, "no folder: nothing to clean");

        // The calls: the installation's token, the body, the answer; the revocation.
        var server = new OneRequest("{\"token\":\"rgd_fromtheserver_0123\",\"device\":{\"id\":\"d7\"}}");
        string device;
        string made = AppWindow.CreateDevice(server.Port, "installation-token-0123456789abcdef", "RGCompanion (RIG)", out device);
        server.Done();
        Check(made == "rgd_fromtheserver_0123" && device == "d7", "the device made: " + made + " " + device);
        Check(server.Line == "POST /api/devices HTTP/1.1", "POST /api/devices: " + server.Line);
        Check(server.Headers.Contains("Authorization: Bearer installation-token-0123456789abcdef"), "with the installation's token");
        Check(server.Body.Contains("\"platform\":\"windows\"") && server.Body.Contains("RGCompanion (RIG)"), "the body: " + server.Body);
        var refused = new OneRequest("{\"error\":\"no\"}");
        Check(AppWindow.CreateDevice(refused.Port, "t", "n", out device) == null, "a refusal: no token (the browser then)");
        refused.Done();
        var revoke = new OneRequest("{\"ok\":true}");
        AppWindow.RevokeDevice(revoke.Port, "installation-token", "d 7");
        revoke.Done();
        Check(revoke.Line == "DELETE /api/devices/d%207 HTTP/1.1", "the revocation: " + revoke.Line);
        // Nobody listening: no token, no exception.
        var closed = new TcpListener(IPAddress.Loopback, 0);
        closed.Start();
        int none = ((IPEndPoint)closed.LocalEndpoint).Port;
        closed.Stop();
        Check(AppWindow.CreateDevice(none, "t", "n", out device) == null, "no server: no token");

        // Without the app the browser opens (false), and nothing is asked of the server.
        string empty = Path.Combine(Path.GetTempPath(), "rg-noapp-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(empty);
        Check(!AppWindow.Present(empty) && !AppWindow.Open(empty, none, "t"), "no app: the browser");
        Directory.Delete(empty, true);

        // The whole opening with the stand-in app (AppStub.cs): a device made, the handoff taken and
        // deleted by the app, which signs in with it; a second opening only brings it forward.
        if (args.Length > 0)
        {
            string root = Path.Combine(Path.GetTempPath(), "rg-open-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(Path.Combine(root, "app"));
            File.Copy(args[0], AppWindow.Exe(root));
            string seen = Path.Combine(root, "hello.json");
            Environment.SetEnvironmentVariable("RG_STUB_OUT", seen);
            var both = new OneRequest(
                "{\"token\":\"rgd_fromtheserver_0123\",\"device\":{\"id\":\"d8\"}}",
                "{\"app\":\"redgiant\",\"signedIn\":true}");
            Check(AppWindow.Open(root, both.Port, "installation-token-0123456789abcdef"), "opened");
            both.Done();
            for (int i = 0; i < 100 && !File.Exists(seen); i++) Thread.Sleep(100);
            Check(both.Lines.Count == 2 && both.Lines[0].StartsWith("POST /api/devices") && both.Lines[1].StartsWith("GET /api/app/hello"),
                "the device, then the app signing in: " + string.Join(" | ", both.Lines.ToArray()));
            Check(both.Headers.Contains("Authorization: Bearer rgd_fromtheserver_0123"), "the app used its own token");
            Check(File.Exists(seen) && File.ReadAllText(seen).Contains("signedIn"), "the app signed in");
            Check(Directory.GetFiles(AppWindow.HandoffDir, "*.json").Length == 0, "the handoff was deleted by the app");
            var p = AppWindow.Running(AppWindow.Exe(root));
            Check(p != null, "the app runs");
            // Nobody listening now: a second opening must not ask for a token.
            Check(AppWindow.Open(root, none, "t"), "a second opening: brought to the front, no token");
            if (p != null) { p.Kill(); p.WaitForExit(5000); }
            Directory.Delete(root, true);

            CloseBeforeUpdate(args[0]);
        }

        Console.WriteLine(passed + " passed, " + failed + " failed");
        return failed == 0 ? 0 : 1;
    }

    static Process Start(string exe, string args)
    {
        return Process.Start(new ProcessStartInfo(exe, args) { UseShellExecute = false, WorkingDirectory = Path.GetDirectoryName(exe) });
    }

    /**
     * Before an update replaces app\ (3.8.2): the app is asked to close and closes (its window
     * gets the close), one that does not is stopped, and app\ can then be moved; the same program
     * in another folder (RGCompanion installed on its own) is left running.
     */
    static void CloseBeforeUpdate(string stub)
    {
        string root = Path.Combine(Path.GetTempPath(), "rg-close-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(Path.Combine(root, "app"));
        string exe = AppWindow.Exe(root);
        File.Copy(stub, exe);
        Check(AppWindow.CloseAll(root, 1000) == 0, "nothing running: nothing closed");

        // With a window: closed the proper way, not stopped.
        string closedFile = Path.Combine(root, "closed.txt");
        var polite = Start(exe, "--window \"" + closedFile + "\"");
        for (int i = 0; i < 100; i++)
        {
            polite.Refresh();
            if (polite.MainWindowHandle != IntPtr.Zero) break;
            Thread.Sleep(100);
        }
        // Without a desktop (a service, an SSH session) windows get no handle: nothing to ask, so
        // the app is stopped like one without a window, and that is what is checked then.
        bool desktop = polite.MainWindowHandle != IntPtr.Zero;
        if (!desktop) Console.WriteLine("no desktop here: the proper close is not tried, only the stop");
        Check(!polite.HasExited, "the stand-in with a window runs");
        Check(AppWindow.CloseAll(root, desktop ? 10000 : 500) == 1, "one app closed");
        Check(polite.HasExited, "the app with a window has left");
        if (desktop) Check(File.Exists(closedFile), "it closed by itself (its window was closed, it was not stopped)");

        // Without a window it cannot be asked: stopped after the grace time. Elsewhere: left alone.
        string other = Path.Combine(root, "other", "rgcompanion.exe");
        Directory.CreateDirectory(Path.GetDirectoryName(other));
        File.Copy(stub, other);
        var stubborn = Start(exe, "--stubborn");
        var alone = Start(other, "--stubborn");
        for (int i = 0; i < 50 && AppWindow.Running(exe) == null; i++) Thread.Sleep(100);
        var started = DateTime.UtcNow;
        Check(AppWindow.CloseAll(root, 500) == 1, "only the app in app\\ counts");
        Check(stubborn.HasExited, "the app that would not close was stopped");
        Check((DateTime.UtcNow - started).TotalSeconds < 15, "within the grace time and the wait");
        Check(!alone.HasExited, "the app installed elsewhere still runs");

        // Nothing holds app\ now: the update can move it.
        bool moved = false;
        try { Directory.Move(Path.Combine(root, "app"), Path.Combine(root, "app-old")); moved = true; }
        catch (Exception e) { Console.WriteLine("move: " + e.Message); }
        Check(moved, "app\\ can be moved once the app is closed");

        try { alone.Kill(); alone.WaitForExit(5000); } catch (Exception) { }
        for (int i = 0; i < 20; i++)
        {
            try { Directory.Delete(root, true); break; } catch (Exception) { Thread.Sleep(250); }
        }
    }
}
