# Windows 10 Test/Project Machine Setup

This is the script to setup a new test VM.

## Prerequisites

- A clean install of Windows 10 Pro v21H1 en-us or above.

> This script has not been tested on other version of Windows, please be careful if you are using it on other Windows versions.
## One-key install

Open Windows PowerShell(Admin)

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/thewhitehouse007/auto-installer/master/installer.ps1'))
```

### Workflow for installer.ps1

- Set a New Computer Name
- Disable Sleep on AC Power
- Add 'This PC' Desktop Icon
- Install Chocolate for Windows
    - 7-Zip
    - Google Chrome
    - Microsoft Teams
    - FileZilla
    - Notepad++
    - Chocolatey GUI
    - VirtualBox GuestAdditions
    - Anydesk
    - Teamviewer
    - Putty
    - Wireshark
    - Fortinet VPN Client
    - Cisco VPN Client
    - Pulse VPN Client
    - Webex
- Not yet setup but consider the following
    - Visual Studio Code
    - Git
    - GitHub for Windows
    - OpenSSL
    - Beyond Compare
    - PowerShell 7
- Remove a few pre-installed UWP applications
    - Messaging
    - Bing News
    - Solitaire
    - People
    - Feedback Hub
    - Your Phone
    - My Office
