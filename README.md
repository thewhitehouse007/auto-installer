# Windows 10 & 11 Test/Project Machine Setup

This is the script to setup a new test VM.

## Prerequisites

- A clean install of Windows 10 Pro v21H1 en-us or above.
- Internet Access

> This script has been designed to run on Windows Development images of Windows 10 and 11. Which can be found here...
> https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/
> It not been tested on other version of Windows, please be careful if you are using it on other Windows versions.
## One-Step install

Open Windows PowerShell(Admin)

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/thewhitehouse007/auto-installer/master/installer.ps1'))
```

### Workflow for installer.ps1

- Activates the Dev License
- Set a New Computer Name
- Disable Sleep on AC Power
- Sets the Timezone
- Add 'This PC' Desktop Icon
- Install Chocolatey for Windows
- Default Applications installed
    - VirtualBox GuestAdditions
    - Google Chrome
    - 7-Zip
    - Notepad++
    - Dropbox
    - Teamviewer
    - Zoom
    - Anydesk
    - PSTools
    - Webex
    - Cisco VPN Client
    - Pulse VPN Client
    - Fortinet VPN Client
    - Telnet Client
    - bgInfo
- Optional Administratior install, includes...
    - Putty
    - FileZilla
    - OpenSSH
    - WinSCP
    - Wireshark
    - cURL
    - Chocolatey GUI
    - WinDirStat
    - OpenVPN
    - SysInternals
    - Nmap
    - Mobaxterm
- Optional Dev install, includes...
    - Firefox
    - Python
    - dotNetFX
    - Git
    - Silverlight
    - Visual Studio Code
- Removes a few pre-installed UWP applications
    - 3DViewer
    - Zune
    - Bing Weather
    - Bing News
    - Messaging
    - Solitaire
    - GetHelp
    - People
    - Your Phone
    - Office Hub
    - Feedback Hub
    - Windows Maps
    - SkypeApp
    - Mixed Reality Portal
    - etc.
- Installs Windows Remote System Administration Tools (Optional Prompt)
- Performs a Windows Update

Running the Script a second time runs the chocolatey installer, this will prompt you if you would like to install additional software options or upgrade your already installed apps.