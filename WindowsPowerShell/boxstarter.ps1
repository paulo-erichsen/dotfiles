# Description: Boxstarter Script
#      
# Run this boxstarter by calling the following from an **elevated** powershell command-prompt:
# Note that you may need to lift the execution policy restriction:
#      Set-ExecutionPolicy Unrestricted -Force
# 1) start/install boxstarter
#      . { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force
# 2) run boxstarter
#      Install-BoxstarterPackage -PackageName <URL-TO-RAW-GIST>
#      example: Install-BoxstarterPackage -PackageName https://raw.githubusercontent.com/paulohefagundes/dotfiles/master/WindowsPowerShell/boxstarter.ps1
#
# Learn more: http://boxstarter.org/Learn/WebLauncher

$Boxstarter.RebootOk=$true # Allow reboots?
$Boxstarter.NoPassword=$false # Is this a machine with no login password?
$Boxstarter.AutoLogin=$true # Save my password securely and auto-login after a reboot

#---- TEMPORARY ---
Disable-UAC

#--- Windows Settings ---
Disable-BingSearch
Disable-GameBarTips
# Change Explorer home screen back to "This PC"
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Type DWord -Value 1

Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions
Set-TaskbarOptions -Size Small -Dock Bottom -Combine Full -Lock
Set-TaskbarOptions -Size Small -Dock Bottom -Combine Full -AlwaysShowIconsOn

# Disable the Lock Screen (the one before password prompt - to prevent dropping the first character)
If (-Not (Test-Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization)) {
	New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows -Name Personalization | Out-Null
}
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization -Name NoLockScreen -Type DWord -Value 1

#--- Windows Subsystems/Features ---
choco install Microsoft-Windows-Subsystem-Linux -source windowsfeatures
choco install Microsoft-Hyper-V-All -source windowsFeatures

#--- Tools ---
choco install git -params '"/GitAndUnixToolsOnPath /WindowsTerminal"' -y
choco install poshgit
# choco install git-credential-manager-for-windows
# choco install p4v
choco install windows-sdk-10
choco install windowsdriverkit10
choco install emacs64
choco install ripgrep
choco install docker-for-windows
choco install javaruntime
choco install vcxsrv

#--- Apps ---
choco install 7zip.install
choco install keepass
choco install zoom
choco install firefox

#--- Privacy ---
# Privacy: Let apps use my advertising ID: Disable
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo -Name Enabled -Type DWord -Value 0
# Privacy: SmartScreen Filter for Store Apps: Disable
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost -Name EnableWebContentEvaluation -Type DWord -Value 0
# WiFi Sense: HotSpot Sharing: Disable
Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting -Name value -Type DWord -Value 0
# WiFi Sense: Shared HotSpot Auto-Connect: Disable
Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots -Name value -Type DWord -Value 0
# Disable Telemetry (requires a reboot to take effect)
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection -Name AllowTelemetry -Type DWord -Value 0
Get-Service DiagTrack,Dmwappushservice | Stop-Service | Set-Service -StartupType Disabled

#--- Restore Temporary Settings ---
Enable-UAC
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula
