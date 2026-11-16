// Tests of AppWindow.cs (G40.12), a console program built like the others (ci.yml):
//
//   csc /out:AppWindowTests.exe /r:System.Web.Extensions.dll test\AppWindowTests.cs AppWindow.cs
//
// The device's name and body, the server's answer, the handoff (a file only this user opens,
// never over another), the old ones cleaned up, and the two calls to a stand-in server.
// Exit code 0 when all pass.
using System;
using System.Collections.Generic;
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

    /** A stand-in for the server: one request, its first line, headers and body kept; [answer] back. */
    sealed class OneRequest
    {
        public readonly int Port;
        public string Line, Headers, Body;
        readonly TcpListener listener;
        readonly Thread thread;

        public OneRequest(string answer)
        {
            listener = new TcpListener(IPAddress.Loopback, 0);
            listener.Start();
            Port = ((IPEndPoint)listener.LocalEndpoint).Port;
            thread = new Thread(() =>
            {
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

    static int Main()
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

        Console.WriteLine(passed + " passed, " + failed + " failed");
        return failed == 0 ? 0 : 1;
    }
}
