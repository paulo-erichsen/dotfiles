###############################################################################
# script to setup windows after initial installation
#
# to allow windows to run this script, first run this command:
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
###############################################################################

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    echo "This script needs to run in an admin shell"
    exit 1
}

# add a local user
$username = "lacey"
$op = Get-LocalUser | where-Object Name -eq "$username" | Measure
if ($op.Count -eq 0) {
    echo "Creating user: $username"
    $password = ConvertTo-SecureString $username -AsPlainText -Force
    New-LocalUser -Name $username -Password $password
    Add-LocalGroupMember -Group "Users" -Member "$username"
}

# set power plan to High Performance
echo "*** setting power plan to High Performance"
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

#  disable fast boot - helps with dual boot into linux
powercfg /hibernate off
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /f /t REG_DWORD /v HiberbootEnabled /d 0

# set the hw clock to UTC - helps with dual boot into linux since linux uses UTC hw clock
echo "*** setting hw clock to UTC"
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f

# set the timezone
echo "*** setting timezone to MST"
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /f /t REG_SZ /v TimeZoneKeyName /d "Mountain Standard Time"

# install packages
echo "*** installing packages"
winget import packages.json

# install user.js on the firefox default profile
echo "*** installing firefox user.js"
$firefox_profile_path = (Get-ChildItem "$env:APPDATA/Mozilla/Firefox/Profiles/*.default-release/").FullName
Invoke-WebRequest -Uri https://raw.githubusercontent.com/paulo-erichsen/user.js/master/user.js -OutFile "$firefox_profile_path/user.js"

# uninstall apps
echo "*** uninstalling apps"
Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay | Remove-AppxPackage
reg add HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR /f /t REG_DWORD /v "AppCaptureEnabled" /d 0
reg add HKEY_CURRENT_USER\System\GameConfigStore /f /t REG_DWORD /v "GameDVR_Enabled" /d 0
Get-AppxPackage -AllUsers *xbox* | Remove-AppxPackage
sc delete XblAuthManager
sc delete XblGameSave
sc delete XboxNetApiSvc
sc delete XboxGipSvc
# reg delete "HKLM\SYSTEM\CurrentControlSet\Services\xbgm" /f
schtasks /Change /TN "Microsoft\XblGameSave\XblGameSaveTask" /disable
schtasks /Change /TN "Microsoft\XblGameSave\XblGameSaveTaskLogon" /disable
# reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f

Get-AppxPackage -AllUsers *comm* | Remove-AppxPackage # mail, calendar
Get-AppxPackage -AllUsers *mess* | Remove-AppxPackage # mail, calendar
Get-AppxPackage -AllUsers *camera* | Remove-AppxPackage # camera
# install_wim_tweak /o /c Microsoft-PPIProjection-Package /r # connect - this command doesn't work on powershell
Get-AppxPackage -AllUsers *zune* | Remove-AppxPackage # music, tv
Get-AppxPackage -AllUsers *spotify* | Remove-AppxPackage # spotify
Get-WindowsPackage -Online | Where PackageName -like *MediaPlayer* | Remove-WindowsPackage -Online -NoRestart # music, tv
Get-AppxPackage -AllUsers *Microsoft.MicrosoftSolitaireCollection* | Remove-AppxPackage # solitaire
Get-AppxPackage -AllUsers *Microsoft.MicrosoftOfficeHub* | Remove-AppxPackage # office
Get-AppxPackage -AllUsers *Microsoft.Office.Sway* | Remove-AppxPackage # office
Get-AppxPackage -AllUsers *Microsoft.Office.Desktop* | Remove-AppxPackage # office
Get-AppxPackage -AllUsers *Microsoft.WindowsFeedbackHub* | Remove-AppxPackage # feedback hub
Get-AppxPackage -AllUsers *sticky* | Remove-AppxPackage # sticky notes
Get-AppxPackage -AllUsers *maps* | Remove-AppxPackage # maps
Get-AppxPackage -AllUsers *onenote* | Remove-AppxPackage # onenote
Get-AppxPackage -AllUsers *bing* | Remove-AppxPackage # weather, news
Get-AppxPackage -AllUsers *phone* | Remove-AppxPackage # your phone
Get-WindowsPackage -Online | Where PackageName -like *Hello-Face* | Remove-WindowsPackage -Online -NoRestart # hello face
schtasks /Change /TN "\Microsoft\Windows\HelloFace\FODCleanupTask" /Disable # hello face

# disable cortana
echo "*** disabling cortana"
Get-AppxPackage -AllUsers Microsoft.549981C3F5F10 | Remove-AppxPackage # cortana
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules"  /v "{2765E0F4-2918-4A46-B9C9-43CDD8FCBA2B}" /t REG_SZ /d  "BlockCortana|Action=Block|Active=TRUE|Dir=Out|App=C:\windows\systemapps\microsoft.windows.cortana_cw5n1h2txyewy\searchui.exe|Name=Search  and Cortana  application|AppPkgId=S-1-15-2-1861897761-1695161497-2927542615-642690995-327840285-2659745135-2630312742|" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f

# uninstall onedrive
echo "*** uninstalling onedrive"
Start-Process -FilePath uninstall_onedrive.bat -Wait

# turn off error reporting
echo "*** turning off error reporting"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f

# disable sync
echo "*** disabling sync"
reg add "HKLM\Software\Policies\Microsoft\Windows\SettingSync" /v DisableSettingSync /t REG_DWORD /d 2 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\SettingSync" /v DisableSettingSyncUserOverride /t REG_DWORD /d 1 /f

# disable web search
echo "*** disabling web search"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /d 0 /t REG_DWORD /f

# remove telemetry and unnecessary services
echo "*** disabling telemetry and unnecessary services"
Start-Process -FilePath remove_telemetry.bat -Wait

# disable useless scheduled tasks
echo "*** disabling useless scheduled tasks"
schtasks /Change /TN "Microsoft\Windows\AppID\SmartScreenSpecific" /disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\AitAgent" /disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\StartupAppTask" /disable
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /disable
schtasks /Change /TN "Microsoft\Windows\CloudExperienceHost\CreateObjectTask" /disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\BthSQM" /disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Uploader" /disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /disable
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable
schtasks /Change /TN "Microsoft\Windows\DiskFootprint\Diagnostics" /disable
schtasks /Change /TN "Microsoft\Windows\FileHistory\File History (maintenance mode)" /disable
schtasks /Change /TN "Microsoft\Windows\Maintenance\WinSAT" /disable
schtasks /Change /TN "Microsoft\Windows\PI\Sqm-Tasks" /disable
schtasks /Change /TN "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyMonitor" /disable
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyRefresh" /disable
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyUpload" /disable
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /disable
schtasks /Change /TN "Microsoft\Windows\WindowsUpdate\Automatic App Update" /disable
schtasks /Change /TN "Microsoft\Windows\License Manager\TempSignedLicenseExchange" /disable
schtasks /Change /TN "Microsoft\Windows\Clip\License Validation" /disable
schtasks /Change /TN "\Microsoft\Windows\ApplicationData\DsSvcCleanup" /disable
schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /disable
schtasks /Change /TN "\Microsoft\Windows\PushToInstall\LoginCheck" /disable
schtasks /Change /TN "\Microsoft\Windows\PushToInstall\Registration" /disable
schtasks /Change /TN "\Microsoft\Windows\Shell\FamilySafetyMonitor" /disable
schtasks /Change /TN "\Microsoft\Windows\Shell\FamilySafetyMonitorToastTask" /disable
schtasks /Change /TN "\Microsoft\Windows\Shell\FamilySafetyRefreshTask" /disable
schtasks /Change /TN "\Microsoft\Windows\Subscription\EnableLicenseAcquisition" /disable
schtasks /Change /TN "\Microsoft\Windows\Subscription\LicenseAcquisition" /disable
schtasks /Change /TN "\Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner" /disable
schtasks /Change /TN "\Microsoft\Windows\Diagnosis\Scheduled" /disable
schtasks /Change /TN "\Microsoft\Windows\NetTrace\GatherNetworkInfo" /disable
Remove-Item -Force -Recurse -Path "C:\Windows\System32\Tasks\Microsoft\Windows\SettingSync\*"

# gaming optimization: disable core isolation - memory integrity
echo "*** disabling memory integrity"
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -v Enabled /t REG_DWORD /d 0 /f

# windows explorer: show file name extensions
echo "*** configuring windows explorer to show file extensions"
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -v HideFileExt /t REG_DWORD /d 0 /f

# maybe download
# https://raw.githubusercontent.com/paulo-erichsen/dotfiles/master/steam/cs2/autoexec.cfg
# C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\core\cfg\autoexec.cfg
# and also practice.cfg
