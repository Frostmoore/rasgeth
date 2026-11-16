; RGCompanion-Setup.exe (3.8.2): RGCompanion on its own, for a Windows computer that reaches a
; RedGiant somewhere else (a server, RedGiant OS, another PC) and does not run one itself. The same
; Flutter build RedGiant-Setup.exe carries in app\ (companion.yml's rgcompanion-windows-x64), in a
; folder of its own: for this user only, no administrator rights, a Start menu entry, Windows'
; uninstallation. Without a launcher's handoff the app asks where RedGiant is and signs in there.
; RedGiant's installer keeps its own copy of the app (app\, opened by RedGiant.exe); the two never
; touch each other's folder.
;
; Built in CI next to RedGiant.iss: iscc /DAppVersion=3.8.2 [/DAppSource=<folder>] RGCompanion.iss,
; with the app's build in app\ (rgcompanion.exe, its DLLs and data\) unless AppSource says otherwise.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef AppSource
  #define AppSource "app"
#endif

[Setup]
AppId={{392CA02E-DEB6-43FE-8337-B46107CC5051}
AppName=RGCompanion
AppVersion={#AppVersion}
AppVerName=RGCompanion {#AppVersion}
AppPublisher=RedGiant
AppPublisherURL=https://smpdigital.it/redgiant/
AppSupportURL=https://github.com/Frostmoore/redgiant2
; A folder of its own, always the same (an update finds it, the uninstaller removes it whole).
DefaultDirName={localappdata}\Programs\RGCompanion
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=dist
OutputBaseFilename=RGCompanion-Setup
SetupIconFile=redgiant.ico
UninstallDisplayIcon={app}\rgcompanion.exe
UninstallDisplayName=RGCompanion
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

[Icons]
Name: "{userprograms}\RGCompanion"; Filename: "{app}\rgcompanion.exe"; WorkingDir: "{app}"
Name: "{userdesktop}\RGCompanion"; Filename: "{app}\rgcompanion.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\rgcompanion.exe"; Description: "{cm:LaunchProgram,RGCompanion}"; Flags: nowait postinstall skipifsilent

[Code]
{ RGCompanion started from this folder (never RedGiant's own copy in its app\ folder): asked to
  close, so it keeps what it saves, then stopped if it is still there after a few seconds, so
  its files can be replaced or removed. }
procedure StopApp();
var
  Code: Integer;
  Cmd: String;
begin
  Cmd := '-NoProfile -NonInteractive -Command "$p = @(Get-Process rgcompanion -ErrorAction SilentlyContinue | ' +
    'Where-Object { $_.Path -like ''' + ExpandConstant('{app}') + '\*'' }); ' +
    '$p | ForEach-Object { [void]$_.CloseMainWindow() }; ' +
    '$p | ForEach-Object { if (-not $_.WaitForExit(5000)) { Stop-Process -Id $_.Id -Force } }"';
  Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Cmd, '', SW_HIDE, ewWaitUntilTerminated, Code);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  StopApp();
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then StopApp();
end;
