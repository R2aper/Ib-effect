; Скрипт сборки инсталлятора Inno Setup для Net ROSI Calculator
[Setup]
AppName=Net ROSI Calculator
AppVersion=1.0
AppPublisher=Shalapai
DefaultDirName={autopf}\NetROSI
DefaultGroupName=Net ROSI Calculator
OutputDir=.\installer_output
OutputBaseFilename=NetRosiCalculator_Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Копируем всю установленную автономную папку dist со всеми DLL, QML и bdu.sqlite
Source: "dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Net ROSI Calculator"; Filename: "{app}\bin\appNew.exe"
Name: "{autodesktop}\Net ROSI Calculator"; Filename: "{app}\bin\appNew.exe"
Name: "{group}\Удалить программу"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\bin\appNew.exe"; Description: "Запустить Net ROSI Calculator"; Flags: nowait postinstall skipifsilent
