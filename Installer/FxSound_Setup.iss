; Inno Setup Script for FxSound (1.2.18-pourih)
; Standalone Windows Installer with Microsoft WHQL-signed audio driver and headless CLI support

#define MyAppName "FxSound"
#define MyAppVersion "1.2.18-pourih"
#define MyAppPublisher "FxSound LLC / pourih"
#define MyAppURL "https://github.com/pourih/fxsound-windows-build"
#define MyAppExeName "FxSound.exe"

[Setup]
AppId={{7DBC465F-A506-4CDC-A9E1-63C41E4AD4F2}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\FxSound LLC\FxSound
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\installer_output
OutputBaseFilename=fxsound_setup_{#MyAppVersion}
SetupIconFile=Resources\fxsound.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "installdriver"; Description: "Install FxSound Audio Enhancer virtual audio driver (Required for system audio enhancement)"; GroupDescription: "Audio Driver Configuration:"
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startup"; Description: "Automatically launch FxSound on Windows login"; GroupDescription: "Startup Settings:"

[Files]
; Main application binaries and presets
Source: "..\src\bin\x64\FxSound.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\bin\x64\FxSound.pdb"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\bin\x64\Factsoft\*"; DestDir: "{app}\Factsoft"; Flags: ignoreversion recursesubdirs createallsubdirs

; WHQL-signed virtual audio driver
Source: "..\src\Installer\Drivers\Version14\win10\x64\*"; DestDir: "{app}\Drivers"; Flags: ignoreversion

; Driver helper configuration utilities
Source: "..\src\Installer\Apps\Version14\*"; DestDir: "{app}\Apps"; Flags: ignoreversion

; Application icon
Source: "Resources\fxsound.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Windows startup entry
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "FxSound"; ValueData: """{app}\{#MyAppExeName}"" --run_minimized"; Flags: uninsdeletevalue; Tasks: startup

[Run]
; 1. Driver Installation (only when user selects the driver task)
Filename: "{app}\Drivers\fxdevcon64.exe"; Parameters: "install fxvad.inf root\fxvad"; WorkingDir: "{app}\Drivers"; Flags: runhidden waituntilterminated; Tasks: installdriver; StatusMsg: "Installing FxSound virtual audio driver..."
; 2. Audio endpoint GUID configuration
Filename: "{app}\Apps\DfxSetupDrv.exe"; Parameters: "getguid"; WorkingDir: "{app}\Apps"; Flags: runhidden waituntilterminated; Tasks: installdriver
; 3. Device friendly name configuration
Filename: "{app}\Apps\DfxSetupDrv.exe"; Parameters: "setname"; WorkingDir: "{app}\Apps"; Flags: runhidden waituntilterminated; Tasks: installdriver
; 4. Default buffer size configuration
Filename: "{app}\Apps\DfxSetupDrv.exe"; Parameters: "defaultbuffersize"; WorkingDir: "{app}\Apps"; Flags: runhidden waituntilterminated; Tasks: installdriver
; 5. Power request override
Filename: "powercfg.exe"; Parameters: "-REQUESTSOVERRIDE DRIVER ""FxSound Audio Enhancer"" SYSTEM"; Flags: runhidden; Tasks: installdriver
; 6. Finish page option to launch FxSound
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Terminate process before uninstall
Filename: "taskkill.exe"; Parameters: "/f /im {#MyAppExeName}"; Flags: runhidden
; Remove driver on uninstall
Filename: "{app}\Drivers\fxdevcon64.exe"; Parameters: "remove root\fxvad"; WorkingDir: "{app}\Drivers"; Flags: runhidden waituntilterminated

[UninstallDelete]
Type: filesandordirs; Name: "{app}\Factsoft"
Type: filesandordirs; Name: "{app}\Drivers"
Type: filesandordirs; Name: "{app}\Apps"
