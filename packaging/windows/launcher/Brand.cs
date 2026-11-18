// The product's name on Windows in one place (3.9.0: RedGiant became Rasgeth; the protocol's
// PRODUCT_NAME and DESKTOP_APP_NAME say the same). Everything a person sees takes it from here:
// the program, its windows and tray, the release's files. What nobody sees keeps its old name:
// the registry key HKCU\Software\RedGiant (DataDir, Version, ModelDirs), the mutex and events
// RedGiant.Launcher.*, the REDGIANT_* variables.
using System;
using System.IO;

static class Brand
{
    public const string Name = "Rasgeth";
    /** The app's own name where both live on one computer (Windows' Apps, the Start menu). */
    public const string AppName = "Rasgeth App";
    /** The launcher, next to node\, server\, web\ and app\ (Rasgeth.iss). */
    public const string Exe = "Rasgeth.exe";
    /** The app's program inside the installation's app\ folder (the Flutter build's BINARY_NAME). */
    public const string AppExe = "rasgeth-app.exe";
    /** The tray's silhouettes (N8): black on a light taskbar, white on a dark one. */
    public const string TrayLight = "rasgeth-tray-light.ico";
    public const string TrayDark = "rasgeth-tray-dark.ico";
    /** The release's files the launcher looks for (the plan's table «Chi cerca i file per nome»). */
    public const string Setup = "Rasgeth-Setup.exe";
    public const string ManifestAsset = "Rasgeth-win-x64.manifest.json";
    public const string ArchiveAsset = "Rasgeth-win-x64.zip";

    /**
     * A folder of this user's own (engine\, handoff\, data\): %LOCALAPPDATA%\Rasgeth\<sub>, or the
     * one a RedGiant before 3.9.0 made, %LOCALAPPDATA%\RedGiant\<sub>, when only that one is there,
     * so models downloaded and data kept are found again and never moved.
     */
    public static string LocalDir(string sub)
    {
        string local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        return LocalDir(local, sub);
    }

    public static string LocalDir(string local, string sub)
    {
        string now = Path.Combine(Path.Combine(local, Name), sub);
        string before = Path.Combine(Path.Combine(local, "RedGiant"), sub);
        try { if (!Directory.Exists(now) && Directory.Exists(before)) return before; }
        catch (Exception) { }
        return now;
    }
}
