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
	slmgr /dlv
	slmgr /rearm
	ContinueConfirmation
}

function ShowChocMenu {
    Clear-Host
    Write-Host ...............................................
    Write-Host PRESS 1, 2 OR 3 to select your task, or q to QUIT.
    Write-Host IF this is the FIRST RUN press 3!
    Write-Host ...............................................
    Write-Host .
    Write-Host 1 - Basic apps
    Write-Host 2 - PowerAdmin apps
    Write-Host 3 - Upgrade apps
    Write-Host q - QUIT
    Write-Host .
}

function ChocolateyInstalls {
    "Starting automatic file installation by chocolatey..."
    powershell.exe -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";%ALLUSERSPROFILE%\chocolatey\bin", "Machine")
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
                "Starting choco upgrade..."
                choco upgrade all
            }
        }
        pause
    }
    until ($selection -eq 'q')

    ContinueConfirmation
}

function OpenBrowserPage($name, $url) {
	"Installing $name..."
    start-process -FilePath 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -ArgumentList '$url'
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

"This will download and install all packages to build a system from scratch"
ContinueConfirmation

LicenseActivate

DownloadInstall "PSTools" "https://dl.dropbox.com/s/jhj653f2iuz2x59/pstools.exe?dl=1" pstools.exe
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";c:\pstools\pstools\;c:\pstools\putty\", "Machine")


$defaultApps = @"
<?xml version="1.0" encoding="utf-8"?>
    <packages>
	  <package id="virtualbox-guest-additions-guest.install" />
      <package id="flashplayerplugin" />
	  <package id="googlechrome" />
	  <package id="7zip" />
	  <package id="jre8" />
	  <package id="notepadplusplus" />
	  <package id="dropbox" />  
	  <package id="teamviewer" />
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
	  <package id="rsat" />
	  <package id="forticlientvpn" />
	  <package id="nmap" />
	  <package id="mobaxterm" />
    </packages>
"@
Set-Content -Path defaultapps.config -Value $defaultApps -Verbose 
Set-Content -Path adminapps.config -Value $adminApps -Verbose 

ChocolateyInstalls

OpenBrowserPage "Webex Meeting Tools" "https://www.webex.com/downloads.html"

DownloadInstall "Cisco AnyConnect VPN Client" "https://dl.dropbox.com/s/zhqmaxzwxsqm2g6/anyconnect-win-3.1.05152-pre-deploy-k9.msi?dl=1" anyconnect.msi

DownloadInstall "Pulse Secure VPN Client" "https://dl.dropbox.com/s/dow6lsv0wfsalgs/JunosPulse.x64.msi?dl=1" pulse.msi

Enable-WindowsOptionalFeature -Online -FeatureName "TelnetClient" -All


"Installations are now completed!!!" 
ContinueConfirmation
Restart-Computer -Confirm
