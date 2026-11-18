// A stand-in for the app in the CI (G40.12), where the Flutter app is built only on version
// branches: installed as app\rasgeth-app.exe, it does what the app does with the launcher's
// handoff (reads the file named by RGCOMPANION_HANDOFF_FILE and deletes it), signs in with the
// token it carried and writes GET /api/app/hello's answer (never the token) into RG_STUB_OUT.
// Then it stays open a minute, so a second «Open Rasgeth» finds it running.
// For AppWindow.CloseAll (3.8.2, closing the app before an update): `--window <file>` opens a
// window that, when asked to close, writes <file> and leaves; `--stubborn` has no window and
// only waits, so it has to be stopped.
//
//   csc /out:AppStub.exe /r:System.Web.Extensions.dll /r:System.Windows.Forms.dll test\AppStub.cs
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;

static class AppStub
{
    static int Main(string[] args)
    {
        if (args.Length == 2 && args[0] == "--window")
        {
            var form = new Form { Text = "Rasgeth stand-in", ShowInTaskbar = false, Width = 200, Height = 100 };
            form.FormClosed += (s, e) => File.WriteAllText(args[1], "closed");
            Application.Run(form);
            return 0;
        }
        if (args.Length == 1 && args[0] == "--stubborn")
        {
            Thread.Sleep(120000);
            return 0;
        }
        string path = Environment.GetEnvironmentVariable("RGCOMPANION_HANDOFF_FILE");
        string output = Environment.GetEnvironmentVariable("RG_STUB_OUT");
        if (string.IsNullOrEmpty(path) || string.IsNullOrEmpty(output)) return 2;
        string text = File.ReadAllText(path, Encoding.UTF8);
        File.Delete(path);
        var h = (Dictionary<string, object>)new JavaScriptSerializer().DeserializeObject(text);
        var req = (HttpWebRequest)WebRequest.Create((string)h["address"] + "/api/app/hello");
        req.Headers[HttpRequestHeader.Authorization] = "Bearer " + (string)h["token"];
        req.Timeout = 5000;
        using (var r = (HttpWebResponse)req.GetResponse())
        using (var reader = new StreamReader(r.GetResponseStream(), Encoding.UTF8))
            File.WriteAllText(output, reader.ReadToEnd());
        Thread.Sleep(60000);
        return 0;
    }
}
