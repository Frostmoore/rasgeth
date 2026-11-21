; Rasgeth-App-Setup.exe (3.8.2; RGCompanion-Setup.exe until 3.9.0): the app on its own, «Rasgeth
; App», for a Windows computer that reaches a Rasgeth somewhere else (a server, Rasgeth OS, another
; PC) and does not run one itself. The same Flutter build Rasgeth-Setup.exe carries in app\
; (companion.yml's rasgeth-app-windows-x64), in a folder of its own: for this user only, no
; administrator rights, a Start menu entry, Windows' uninstallation. Without a launcher's handoff
; the app asks where Rasgeth is and signs in there. The full installer keeps its own copy of the
; app (app\, opened by Rasgeth.exe); the two never touch each other's folder.
;
; Built in CI next to Rasgeth.iss: iscc /DAppVersion=3.8.2 [/DAppSource=<folder>] RasgethApp.iss,
; with the app's build in app\ (rasgeth-app.exe, its DLLs and data\) unless AppSource says otherwise.
;
; 3.9.0: the AppId stays (one entry in Windows' Apps, now «Rasgeth App»); an installation over the
; app's earlier folder ({localappdata}\Programs\RGCompanion) moves to the new one and removes the
; old folder and shortcuts. The app's own data (%APPDATA%) are carried over by the app (main.cpp).

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef AppSource
  #define AppSource "app"
#endif

[Setup]
AppId={{392CA02E-DEB6-43FE-8337-B46107CC5051}
AppName=Rasgeth App
AppVersion={#AppVersion}
AppVerName=Rasgeth App {#AppVersion}
AppPublisher=Rasgeth
AppPublisherURL=https://rasgeth.it/
AppSupportURL=https://github.com/Frostmoore/rasgeth
; A folder of its own, always the same (an update finds it, the uninstaller removes it whole); not
; the previous one, so an earlier RGCompanion's folder is left for [InstallDelete] to remove.
DefaultDirName={localappdata}\Programs\Rasgeth App
UsePreviousAppDir=no
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=dist
OutputBaseFilename=Rasgeth-App-Setup
SetupIconFile=rasgeth.ico
UninstallDisplayIcon={app}\rasgeth-app.exe
UninstallDisplayName=Rasgeth App
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
MinVersion=10.0.17763
ShowLanguageDialog=auto
UsePreviousLanguage=yes
LanguageDetectionMethod=uilanguage
; The app is closed by the setup itself (PrepareToInstall), only the copy in this folder.
CloseApplications=no
RestartApplications=no

[Languages]
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#AppSource}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
; An update replaces the app whole: files the new build no longer has must not linger.
Type: filesandordirs; Name: "{app}\data"
Type: files; Name: "{app}\*.dll"
; The app's folder and shortcuts before 3.9.0 (RGCompanion): only the program was there.
Type: filesandordirs; Name: "{localappdata}\Programs\RGCompanion"
Type: files; Name: "{userprograms}\RGCompanion.lnk"
Type: files; Name: "{userdesktop}\RGCompanion.lnk"

[Icons]
Name: "{userprograms}\Rasgeth App"; Filename: "{app}\rasgeth-app.exe"; WorkingDir: "{app}"
Name: "{userdesktop}\Rasgeth App"; Filename: "{app}\rasgeth-app.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\rasgeth-app.exe"; Description: "{cm:LaunchProgram,Rasgeth App}"; Flags: nowait postinstall skipifsilent

[Code]
{ The app started from a folder (never the full installer's own copy in its app\ folder): asked
  to close, so it keeps what it saves, then stopped if it is still there after a few seconds, so
  its files can be replaced or removed. }
procedure StopAppIn(Dir, Name: String);
var
  Code: Integer;
  Cmd: String;
begin
  Cmd := '-NoProfile -NonInteractive -Command "$p = @(Get-Process ' + Name + ' -ErrorAction SilentlyContinue | ' +
    'Where-Object { $_.Path -like ''' + Dir + '\*'' }); ' +
    { 3.10.2: the app may be hidden in the tray, where its window's close only hides it: it is
      asked on its own loopback port (instance.json in its folder) to end for real first. }
    '$i = Join-Path $env:APPDATA ''Rasgeth\Rasgeth\instance.json''; $asked = -1; ' +
    'if ($p.Count -gt 0 -and (Test-Path -LiteralPath $i)) { try { $j = Get-Content -Raw -LiteralPath $i | ConvertFrom-Json; ' +
    'if (@($p | ForEach-Object { $_.Id }) -contains [int]$j.pid) { $c = New-Object Net.Sockets.TcpClient(''127.0.0.1'', [int]$j.port); ' +
    '$s = $c.GetStream(); $s.ReadTimeout = 3000; $b = [Text.Encoding]::ASCII.GetBytes(''rasgeth '' + $j.token + '' quit'' + [char]10); ' +
    '$s.Write($b, 0, $b.Length); $s.Flush(); if ($s.ReadByte() -eq 111) { $asked = [int]$j.pid }; $c.Close() } } catch { } }; ' +
    '$p | Where-Object { $_.Id -ne $asked } | ForEach-Object { [void]$_.CloseMainWindow() }; ' +
    '$p | ForEach-Object { if (-not $_.WaitForExit(5000)) { Stop-Process -Id $_.Id -Force } }"';
  Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Cmd, '', SW_HIDE, ewWaitUntilTerminated, Code);
end;

procedure StopApp();
begin
  StopAppIn(ExpandConstant('{app}'), 'rasgeth-app');
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  StopApp();
  { An earlier RGCompanion in its own folder, before that folder is removed. }
  StopAppIn(ExpandConstant('{localappdata}\Programs\RGCompanion'), 'rgcompanion');
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then StopApp();
end;
