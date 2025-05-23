function CheckInstalled($cmdname) {
	return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

function PreChecks {
	# Check if this script was Run As Administrator
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	IF (!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
		Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR: This Script needs to run in admin mode"
		Start-Sleep -Seconds 5
		exit
	}
	# Also check for internet and DNS resolution
	IF (!(Test-Connection www.dropbox.com -Quiet -Count 2)) {
		Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR: This script requires internet access"
		Start-Sleep -Seconds 5
		exit
	}
}

function LicenseActivate {
	"Activating license for Windows Evaluation"
	slmgr /ato
}

function RenameComputer {
	$computerName = Read-Host 'Enter New Computer Name (Suggestion: WinXX-XCustomerX)'
	Write-Host "Renaming this computer to: " $computerName  -ForegroundColor Yellow
	Rename-Computer -NewName $computerName
}

function DisableSleeping {
	Write-Host ""
	Write-Host "Disable Sleep on AC Power..." -ForegroundColor Green
	Write-Host "------------------------------------" -ForegroundColor Green
	Powercfg /Change monitor-timeout-ac 20
	Powercfg /Change standby-timeout-ac 0
}

function SetTimeZone {
	Write-Host "Setting Time zone..." -ForegroundColor Green
	Set-TimeZone -Name "E. Australia Standard Time"
}

function AddThisPCDesktopIcon {
	Write-Host ""
	Write-Host "Add 'This PC' Desktop Icon..." -ForegroundColor Green
	Write-Host "------------------------------------" -ForegroundColor Green
	$thisPCIconRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
	$thisPCRegValname = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" 
	$item = Get-ItemProperty -Path $thisPCIconRegPath -Name $thisPCRegValname -ErrorAction SilentlyContinue 
	if ($item) { 
		Set-ItemProperty  -Path $thisPCIconRegPath -name $thisPCRegValname -Value 0  
	} 
	else { 
		New-ItemProperty -Path $thisPCIconRegPath -Name $thisPCRegValname -Value 0 -PropertyType DWORD | Out-Null  
	} 
}

function SetExplorerOptions {
	Write-Host "Applying file explorer settings..." -ForegroundColor Green
	cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f"
	cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v AutoCheckSelect /t REG_DWORD /d 0 /f"
	cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v LaunchTo /t REG_DWORD /d 1 /f"
	cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v TaskbarMn /t REG_DWORD /d 0 /f"
	cmd.exe /c "reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' /v ChatIcon /t REG_DWORD /d 3 /f"
}

function ShowChocMenu {
	Write-Host ...............................................
	Write-Host PRESS 1, 2 OR 3 to select your task, or q to QUIT.
	Write-Host ...............................................
	Write-Host .
	Write-Host 1 - Basic apps
	Write-Host 2 - PowerAdmin apps
	Write-Host 3 - Developer apps
	Write-Host u - Upgrade apps
	Write-Host q - QUIT
	Write-Host .
}

function ChocolateyInstalls {
	"Starting automatic file installation by chocolatey..."
	if (CheckInstalled -cmdname 'choco') {
		Write-Host "Choco is already installed, skipping installation." -ForegroundColor Yellow
	}
	else {
		Write-Host ""
		Write-Host "Installing Chocolate for Windows..." -ForegroundColor Green
		Write-Host "------------------------------------" -ForegroundColor Green
		Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
		[Environment]::SetEnvironmentVariable("Path", $env:Path + ";%ALLUSERSPROFILE%\chocolatey\bin", "Machine")
	}	
	choco feature enable -n allowGlobalConfirmation
	choco upgrade chocolatey
	do {
		ShowChocMenu
		$selection = Read-Host "Please make a selection"
		switch ($selection)
		{
			'1' {
				choco install -y defaultapps.config   
			}
			'2' {
				choco install -y defaultapps.config   
				pause
				choco install -y adminapps.config   
			} 
			'3' {
				choco install -y defaultapps.config   
				pause
				choco install -y adminapps.config
				pause
				choco install -y devapps.config
			}
			'u' {
				"Starting choco upgrade..."
				choco upgrade all
				RunWindowsUpdates
			}
		}
		pause
	}
	until ($selection -eq 'q')
}

function RunWindowsUpdates {
	$name = "Windows Updates"	
	$confirmation = ContinueConfirmation($name)
	if ($confirmation -eq "y") {
		Write-Host ""
		Write-Host "Checking Windows updates..." -ForegroundColor Green
		Write-Host "------------------------------------" -ForegroundColor Green
		Install-Module -Name PSWindowsUpdate -Force
		Write-Host "Installing updates... (Computer will reboot in minutes...)" -ForegroundColor Green
		Get-WindowsUpdate -AcceptAll -Install -ForceInstall
	} elseif ($confirmation -eq "n") {
		Write-Host "OK.. Skipping $name" -ForegroundColor Yellow
		Write-Host "You really shouldn't skip $name..." -ForegroundColor Red
		Write-Host "Re-Run setup to install $name" -ForegroundColor Yellow
	}
}

function InstallWindowsRSAT {
	Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State
	$title	= 'Windows Remote System Administration Tools Installation'
	$question = 'Do you want to install Windows RSAT, this will take some time...'
	$choices  = '&Yes', '&No'

	$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
	if ($decision -eq 0) {
		Write-Host 'Proceeding to install Windows RSAT... Please Wait...'
		Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
	} else {
		Write-Host 'OK.. Not installing Windows RSAT'
	}
}

function UpdateBGInfoConfig($name, $url, $filename) {
	$confirmation = ContinueConfirmation($name)
	if ($confirmation -eq "y") {
		"Configuring BGInfo Background Informaton Display..."
		"Downloading Config File..."
		$client.DownloadFile("$url","$DOWNLOADS\$filename")
		"Loading Configuration..."
		& C:\ProgramData\chocolatey\lib\bginfo\tools\Bginfo.exe $DOWNLOADS\$filename /timer:0
	} elseif ($confirmation -eq "n") {
		"OK.. Skipping $name"
	}
}

function RemoveUWPApps {
	# To list all appx packages:
	# Get-AppxPackage | Format-Table -Property Name,Version,PackageFullName
	Write-Host "Removing UWP Rubbish..." -ForegroundColor Green
	Write-Host "------------------------------------" -ForegroundColor Green
	$uwpRubbishApps = @(
		"Microsoft.Microsoft3DViewer"
		"Microsoft.ZuneMusic"
		"Microsoft.ZuneVideo"
		"Microsoft.WindowsSoundRecorder"
		"Microsoft.PowerAutomateDesktop"
		"Microsoft.BingWeather"
		"Microsoft.BingNews"
		"Microsoft.Messaging"
		"Microsoft.WindowsFeedbackHub"
		"Microsoft.MicrosoftOfficeHub"
		"Microsoft.MicrosoftSolitaireCollection"
		"Microsoft.GetHelp"
		"Microsoft.People"
		"Microsoft.YourPhone"
		"Microsoft.Getstarted"
		"Microsoft.Microsoft3DViewer"
		"Microsoft.WindowsMaps"
		"Microsoft.MixedReality.Portal"
		"Microsoft.SkypeApp"
	)
	foreach ($uwp in $uwpRubbishApps) {
		Remove-UWP $uwp
	}
}

function Remove-UWP {
	param (
		[string]$name
	)
	Write-Host "Removing UWP $name..." -ForegroundColor Yellow
	Get-AppxPackage $name | Remove-AppxPackage
	Get-AppxPackage $name | Remove-AppxPackage -AllUsers
}

function OpenBrowserPage($name, $url) {
	$confirmation = ContinueConfirmation($name)
	if ($confirmation -eq "y") {
		Write-Host "Going to $name..." -ForegroundColor Green
		start-process -FilePath 'C:\Program Files\Google\Chrome\Application\chrome.exe' -ArgumentList "$url"
	} elseif ($confirmation -eq "n") {
		Write-Host "OK.. Skipping $name" -ForegroundColor Yellow
	}
}

function DownloadInstall($name, $url, $filename) {
	$confirmation = ContinueConfirmation($name)
	if ($confirmation -eq "y") {
		Write-Host "Downloading $name..." -ForegroundColor Green
		$client.DownloadFile("$url","$DOWNLOADS\$filename")
		Write-Host "Installing $name..." -ForegroundColor Green
		& $DOWNLOADS\$filename
	} elseif ($confirmation -eq "n") {
		Write-Host "OK.. Skipping $name" -ForegroundColor Yellow
	}
}

function ContinueConfirmation($name) {
	$title	= $name
	$question = "Do you want to install $name?"
	$choices  = '&Yes', '&No'

	$decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)
	if ($decision -eq 0) {
		return "y"
	} else {
		return "n"
	}
}

# Chocolately Apps Selection Groups
$defaultApps = @"
<?xml version="1.0" encoding="utf-8"?>
	<packages>
	<package id="virtualbox-guest-additions-guest.install" />
	<package id="googlechrome" />
	<package id="7zip" />
	<package id="jre8" />
	<package id="notepadplusplus" />
	<package id="dropbox" />  
	<package id="zoom" />
	<package id="bginfo" />
	</packages>
"@
$adminApps = @"									  
<?xml version="1.0" encoding="utf-8"?>
	<packages>
	<package id="putty" />
	<package id="filezilla" />
	<package id="procexp" />
	<package id="openssh" />  
	<package id="winscp" />
	<package id="wireshark" />
	<package id="curl" />
	<package id="chocolateygui" />
	<package id="windirstat" />
	<package id="openvpn" />
	<package id="sysinternals" />
	<package id="nmap" />
	<package id="mobaxterm" />
	<package id="teracopy" />
	</packages>
"@
$devApps = @"									  
<?xml version="1.0" encoding="utf-8"?>
	<packages>
	<package id="firefox" />
	<package id="python3" />
	<package id="dotnetfx" />
	<package id="git" />
	<package id="silverlight" />  
	<package id="vscode" />
	</packages>
"@

## START OF MAIN SCRIPT ##
$client = new-object System.Net.WebClient
$DOWNLOADS="$Home\Downloads"
Set-Location $DOWNLOADS

"Starting automatic file installation script"
PreChecks
"This will download and install selected packages to build a system for a Windows Developer VM"

if (Test-Path -Path BGCONFIG.BGI -PathType Leaf) {
	Write-Host "Detected that the script has been run before... Skipping pre-installation tasks" -ForegroundColor Yellow
	ChocolateyInstalls
}
else {
	"First time running this script... Running pre-installation tasks"
	LicenseActivate

	RenameComputer

	DisableSleeping

	SetTimeZone

	AddThisPCDesktopIcon

	SetExplorerOptions

	RemoveUWPApps

	DownloadInstall "PSTools" "https://dl.dropbox.com/s/jhj653f2iuz2x59/pstools.exe?dl=1" pstools.exe
	[Environment]::SetEnvironmentVariable("Path", $env:Path + ";c:\pstools\pstools\;c:\pstools\putty\", "Machine")

	Set-Content -Path defaultapps.config -Value $defaultApps -Verbose 
	Set-Content -Path adminapps.config -Value $adminApps -Verbose 
	Set-Content -Path devapps.config -Value $devApps -Verbose 

	ChocolateyInstalls

	OpenBrowserPage "Webex Meeting Tools" "https://www.webex.com/downloads.html"

	DownloadInstall "Cisco Secure Client" "https://dl.dropbox.com/scl/fi/em9zx2actqp4dibke94ol/cisco-secure-client-win-5.0.03076-core-vpn-webdeploy-k9.msi?rlkey=juuv585h1gxzgrttyg504ik8d&dl=1" anyconnect.msi

	DownloadInstall "Juniper Secure Connect VPN Client" "https://dl.dropbox.com/scl/fi/tjswqwdaxjdimwceybm4d/Juniper-Secure-Connect_Windows_x86-64_23.4.13.16_29678.exe?rlkey=5dfo20vycqyeqzvet9dkc0n91&dl=1" jsc.exe

	OpenBrowserPage "FortiClient VPN" "https://links.fortinet.com/forticlient/win/vpnagent"

	Enable-WindowsOptionalFeature -Online -FeatureName "TelnetClient" -All -NoRestart

	InstallWindowsRSAT

	UpdateBGInfoConfig "Background Info Configuration" "https://dl.dropbox.com/scl/fi/lkq4ahv9slokspw801p4i/BGCONFIG.BGI?rlkey=43q6yhzwi9ko55c4ni7e99w5h&dl=1" BGCONFIG.BGI

	RunWindowsUpdates
}
Write-Host "Installations are now completed!!!" -ForegroundColor Green
Write-Host "Restarting..." -ForegroundColor Yellow
Restart-Computer -Confirm
