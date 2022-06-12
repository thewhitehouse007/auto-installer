function Check-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

function PreChecks {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    IF (!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR: This Script needs to run in admin mode"
        Start-Sleep -Seconds 5
        exit
    }
    IF (!(Test-Connection www.dropbox.com -Quiet -Count 2)) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR: This script requires internet access"
        Start-Sleep -Seconds 5
        exit
    }
}

function LicenseActivate {
	"Activating license for Windows Evaluation"
	slmgr /ato
	ContinueConfirmation
}

function RenameComputer {
	$computerName = Read-Host 'Enter New Computer Name (Suggestion: WinXX-XCustomerX'
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
}

function ShowChocMenu {
    Write-Host ...............................................
    Write-Host PRESS 1, 2 OR 3 to select your task, or q to QUIT.
    Write-Host IF this is the FIRST RUN press 3!
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
    if (Check-Command -cmdname 'choco') {
		Write-Host "Choco is already installed, skip installation."
	}
	else {
		Write-Host ""
		Write-Host "Installing Chocolate for Windows..." -ForegroundColor Green
		Write-Host "------------------------------------" -ForegroundColor Green
		Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
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
                choco install -y adminapps.config   
            } 
	    '3' {
	    	choco install -y defaultapps.config   
                choco install -y adminapps.config
		choco install -y devapps.config
	    }
            'u' {
                "Starting choco upgrade..."
                choco upgrade all
            }
        }
        pause
    }
    until ($selection -eq 'q')

    ContinueConfirmation
}

function RunWindowsUpdates {	
	Write-Host ""
	Write-Host "Checking Windows updates..." -ForegroundColor Green
	Write-Host "------------------------------------" -ForegroundColor Green
	Install-Module -Name PSWindowsUpdate -Force
	Write-Host "Installing updates... (Computer will reboot in minutes...)" -ForegroundColor Green
	Get-WindowsUpdate -AcceptAll -Install -ForceInstall -AutoReboot
}

function RemoveUWPApps {
	# To list all appx packages:
	# Get-AppxPackage | Format-Table -Property Name,Version,PackageFullName
	Write-Host "Removing UWP Rubbish..." -ForegroundColor Green
	Write-Host "------------------------------------" -ForegroundColor Green
	$uwpRubbishApps = @(
		"Microsoft.MSPaint"
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
	"Installing $name..."
    	start-process -FilePath 'C:\Program Files\Google\Chrome\Application\chrome.exe' -ArgumentList "$url"
	ContinueConfirmation
}

function DownloadInstall($name, $url, $filename) {
	"Downloading $name..."
	$client.DownloadFile("$url","$DOWNLOADS\$filename")
	"Installing $name..."
	& $DOWNLOADS\$filename
	ContinueConfirmation
}

function ContinueConfirmation {
	$Confirmation = Read-Host "Done... Continue? [y/n]"
	while($Confirmation -ne "y")
	{
		if ($Confirmation -eq 'n') {exit}
		$Confirmation = Read-Host "Done... Continue? [y/n]"
	}
}



$client = new-object System.Net.WebClient
$DOWNLOADS="$Home\Downloads"
cd $DOWNLOADS

"Starting automatic file installation"
#Check if this script was Run As Administrator
#Also check for internet and DNS resolution
PreChecks

"This will download and install all packages to build a system from a fresh Windows install"
ContinueConfirmation

LicenseActivate

RenameComputer

DisableSleeping

SetTimeZone

AddThisPCDesktopIcon

SetExplorerOptions

RemoveUWPApps

DownloadInstall "PSTools" "https://dl.dropbox.com/s/jhj653f2iuz2x59/pstools.exe?dl=1" pstools.exe
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";c:\pstools\pstools\;c:\pstools\putty\", "Machine")

$defaultApps = @"
<?xml version="1.0" encoding="utf-8"?>
    <packages>
	  <package id="virtualbox-guest-additions-guest.install" />
	  <package id="googlechrome" />
	  <package id="7zip" />
	  <package id="jre8" />
	  <package id="notepadplusplus" />
	  <package id="dropbox" />  
	  <package id="teamviewer" />
	  <package id="zoom" />
	  <package id="avastfreeantivirus" />
	  <package id="anydesk" />
    </packages>
"@
$adminApps = @"	                                  
<?xml version="1.0" encoding="utf-8"?>
    <packages>
	  <package id="putty" />
	  <package id="filezilla" />
	  <package id="dotnet4.5" />
	  <package id="procexp" />
	  <package id="openssh" />  
	  <package id="winscp" />
	  <package id="wireshark" />
	  <package id="curl" />
	  <package id="chocolateygui" />
	  <package id="windirstat" />
	  <package id="openvpn" />
	  <package id="sysinternals" />
	  <package id="forticlientvpn" />
	  <package id="nmap" />
	  <package id="mobaxterm" />
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
	  <package id="pycharm" />
    </packages>
"@
Set-Content -Path defaultapps.config -Value $defaultApps -Verbose 
Set-Content -Path adminapps.config -Value $adminApps -Verbose 
Set-Content -Path devapps.config -Value $devApps -Verbose 


ChocolateyInstalls

OpenBrowserPage "Webex Meeting Tools" "https://www.webex.com/downloads.html"

DownloadInstall "Cisco AnyConnect VPN Client" "https://dl.dropbox.com/s/zhqmaxzwxsqm2g6/anyconnect-win-3.1.05152-pre-deploy-k9.msi?dl=1" anyconnect.msi

DownloadInstall "Pulse Secure VPN Client" "https://dl.dropbox.com/s/dow6lsv0wfsalgs/JunosPulse.x64.msi?dl=1" pulse.msi

OpenBrowserPage "Remote Server Administration Tools" "https://www.microsoft.com/en-au/download/details.aspx?id=45520"

Enable-WindowsOptionalFeature -Online -FeatureName "TelnetClient" -All

RunWindowsUpdates

"Installations are now completed!!!" 
ContinueConfirmation
Restart-Computer -Confirm
