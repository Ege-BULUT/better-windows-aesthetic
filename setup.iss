; Better Windows Aesthetic: one wizard that installs and configures the whole desktop setup.
; Build: iscc setup.iss  (output: Output\BetterWindowsAesthetic-Setup.exe)

#define AppName "Better Windows Aesthetic"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId={{6F1C2A54-9D3B-4E7A-8C21-5B0E7F3A9D42}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Ege BULUT
AppPublisherURL=https://github.com/Ege-BULUT/better-windows-aesthetic
; Nothing is installed into an app folder: every component is its own app with its own uninstaller
CreateAppDir=no
Uninstallable=no
DisableProgramGroupPage=yes
DisableReadyPage=no
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.22000
OutputBaseFilename=BetterWindowsAesthetic-Setup
WizardStyle=modern
Compression=lzma2
SolidCompression=yes

[Languages]
Name: "tr"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
tr.CompTheme=Koyu tema + şeffaf Başlat menüsü
en.CompTheme=Dark theme + translucent Start menu
tr.CompTaskbar=Şeffaf görev çubuğu (TranslucentTB)
en.CompTaskbar=Transparent taskbar (TranslucentTB)
tr.CompLively=Lively Wallpaper (animasyonlu duvar kağıdı)
en.CompLively=Lively Wallpaper (animated wallpaper)
tr.CompBliss=Windows XP Bliss Night duvar kağıdı
en.CompBliss=Windows XP Bliss Night wallpaper
tr.CompZen=Zen Browser
en.CompZen=Zen Browser
tr.CompZenMod=Transparent Zen eklentisi + şeffaf arayüz
en.CompZenMod=Transparent Zen extension + transparent UI
tr.CompWidgets=Saat ve takvim widget'ı (WinWidgets)
en.CompWidgets=Clock and calendar widget (WinWidgets)
tr.CompFlow=Flow Launcher arama çubuğu (Alt+Space)
en.CompFlow=Flow Launcher search bar (Alt+Space)
tr.Working=Kuruluyor: %1 (internetten indiriliyor, birkaç dakika sürebilir)
en.Working=Installing: %1 (downloading, this can take a few minutes)
tr.Failed=Şu adımlar başarısız oldu:%n%n%1%nAyrıntılar: %2
en.Failed=These steps failed:%n%n%1%nDetails: %2

[Types]
Name: "full"; Description: "Full"; Flags: iscustom

[Components]
Name: "theme"; Description: "{cm:CompTheme}"; Types: full
Name: "taskbar"; Description: "{cm:CompTaskbar}"; Types: full
Name: "lively"; Description: "{cm:CompLively}"; Types: full
Name: "lively\bliss"; Description: "{cm:CompBliss}"; Types: full
Name: "zen"; Description: "{cm:CompZen}"; Types: full
Name: "zen\mod"; Description: "{cm:CompZenMod}"; Types: full
Name: "widgets"; Description: "{cm:CompWidgets}"; Types: full
Name: "flow"; Description: "{cm:CompFlow}"; Types: full

[Files]
Source: "install.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "assets\*"; DestDir: "{tmp}\assets"; Flags: recursesubdirs deleteafterinstall

[Code]
var
  Failed: String;

// Elevated steps install into Program Files, the rest run as the signed-in user so HKCU and AppData are theirs
procedure RunStep(Step, Title: String; Elevated: Boolean);
var
  Params: String;
  Code: Integer;
  Ok: Boolean;
begin
  WizardForm.StatusLabel.Caption := FmtMessage(CustomMessage('Working'), [Title]);
  Params := '-NoProfile -ExecutionPolicy Bypass -File "' + ExpandConstant('{tmp}\install.ps1') + '" -Step ' + Step;
  if Elevated then
    Ok := Exec('powershell.exe', Params, '', SW_HIDE, ewWaitUntilTerminated, Code)
  else
    Ok := ExecAsOriginalUser('powershell.exe', Params, '', SW_HIDE, ewWaitUntilTerminated, Code);
  if not Ok or (Code <> 0) then
    Failed := Failed + '- ' + Title + #13#10;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep <> ssPostInstall then Exit;
  WizardForm.ProgressGauge.Style := npbstMarquee;
  if WizardIsComponentSelected('theme') then RunStep('theme', CustomMessage('CompTheme'), False);
  if WizardIsComponentSelected('taskbar') then RunStep('translucenttb', CustomMessage('CompTaskbar'), False);
  if WizardIsComponentSelected('lively') then RunStep('lively-install', CustomMessage('CompLively'), True);
  if WizardIsComponentSelected('lively\bliss') then RunStep('lively-config', CustomMessage('CompBliss'), False);
  if WizardIsComponentSelected('zen') then RunStep('zen-install', CustomMessage('CompZen'), True);
  if WizardIsComponentSelected('zen\mod') then RunStep('zen-config', CustomMessage('CompZenMod'), False);
  if WizardIsComponentSelected('widgets') then RunStep('widgets', CustomMessage('CompWidgets'), False);
  if WizardIsComponentSelected('flow') then RunStep('flow', CustomMessage('CompFlow'), False);
  WizardForm.ProgressGauge.Style := npbstNormal;
  if Failed <> '' then
    MsgBox(FmtMessage(CustomMessage('Failed'), [Failed, ExpandConstant('{%TEMP}\better-windows-aesthetic.log')]), mbError, MB_OK);
end;
