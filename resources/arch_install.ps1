$archus_b_ver = "1.00"
$script_path1 = $PSScriptRoot
$script_path2 = Split-Path -Path $PSScriptRoot -Parent
$script_path = $PSScriptRoot -replace '\\', '/'
$path2_init_script = "/$script_path/arch_install/resources/scripts/init_wsl_deb.sh" -replace '/C:/', '/mnt/c/'
$path2script = "/$script_path/arch_install/arch_main_win.sh" -replace '/C:/', '/mnt/c/'
$path2inf = "$script_path1\arch_install\resources\Files\progress.inf"
$path_after_restart = $script_path2
$postRebootScript = [Environment]::GetFolderPath('Startup')
$postRebootScript = "$postRebootScript\after_reboot.bat"

cls
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
 Write-host "This script must be run as Administrator. Exiting..." -ForegroundColor RED
 Exit(0)
}

function Test-InternetConnection {
    return Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
}

# Loop until internet is connected
while (-not ($null = Test-InternetConnection)) {
 Write-Host "No internet connection." -ForegroundColor RED
    Write-Host "Turn ON and hit enter" -ForegroundColor Yellow
    Read-Host
    $null = Test-InternetConnection
}

function Set-IniValue {
 param (
 [string]$FilePath,
 [string]$Key,
 [string]$Value
 )

 # Read all lines from the file
if (Test-Path $path2inf) {
	$lines = Get-Content $FilePath
}
 $newLine = "[$Key]=$Value"
 $found = $false

 # Search for the key and update if found
 for ($i = 0; $i -lt $lines.Count; $i++) {
	if ($lines[$i] -match "^\[$Key\]=") {
		$lines[$i] = $newLine
		$found = $true
		break
	}
 }

 # Append if not found
 if (-not $found) {
	$lines += "`r`n$newLine"
 }

 # Write back in ASCII encoding
 [System.IO.File]::WriteAllLines($FilePath, $lines, [System.Text.Encoding]::ASCII)
}

function logo {
	
# Define the ASCII logo (6 lines)
$logo = @(
"    ____                             ______	    ",
"   / __ \____ _____ ____  ____  ____/ / __ \_____  ",
"  / /_/ / __ `/ __ `/ _ \/ __ \/ __  / / / / ___/  ",
" / ____/ /_/ / /_/ /  __/ / / / /_/ / /_/ (__  )   ",
"/_/    \__,_/\__, /\___/_/ /_/\__,_/\____/____/    ",
"            /____/				    "
)

	# Tagline
	$tagline = "Arch Boot stick creation. Version: $archus_b_ver"

	# Calculate the maximum width of the logo
	$maxLogoWidth = ($logo + $tagline | Measure-Object -Property Length -Maximum).Maximum
	$startOffset = -$maxLogoWidth
	$endOffset = 0

	# Animate the logo sliding in from the left
	for ($i = $startOffset; $i -le $endOffset; $i++) {
 	Clear-Host
 	foreach ($line in $logo) {
 	if ($i -lt 0) {
 	$startIndex = -$i
 	$visibleLine = if ($startIndex -lt $line.Length) { $line.Substring($startIndex) } else { "" }
 	Write-Host $visibleLine
 	} else {
 	Write-Host (" " * $i + $line)
 	}
 	}

 	if ($i -lt 0) {
 	$startIndex = -$i
 	$visibleTagline = if ($startIndex -lt $tagline.Length) { $tagline.Substring($startIndex) } else { "" }
 	Write-Host $visibleTagline
 	} else {
 	Write-Host (" " * $i + $tagline) -ForegroundColor Magenta
 	}

 	Start-Sleep -Milliseconds 25
	}	
}
if ( -not (Test-Path $path2inf)) {
	logo
}
Write-Host "Internet is connected!" -ForegroundColor Green

function set_keyboard {
    . "$script_path1\arch_install\resources\scripts\set_keymapping.ps1"

    $keyboard_layout = Get-Content -Path "$script_path1\resources\Files\keyboard_layout.inf"
    Write-Host "Keyboard layout is setted to: $keyboard_layout" -ForegroundColor YELLOW
	Set-IniValue -FilePath "$path2inf" -Key "keyboard" -Value 1
    sleep 2
}

function check_usbipd {
    write-host "Checking usbipd.." -ForegroundColor YELLOW
    if (Get-Command "usbipd" -ErrorAction SilentlyContinue) {
        Write-Host "usbipd is installed" -ForegroundColor YELLOW
        Set-IniValue -FilePath "$path2inf" -Key "keyboard" -Value 1
        sleep 2
    } else {
       
        # GitHub API for latest release
        $apiUrl = "https://api.github.com/repos/dorssel/usbipd-win/releases/latest"

        # Get release info
        $response = Invoke-RestMethod -Uri $apiUrl

        # Extract the .msi download URL
        $msiUrl = ($response.assets | Where-Object { $_.name -like "*x64.msi" }).browser_download_url

        $outputPath = "$script_path1\arch_install\resources\Files\usbipd.msi"

        Write-Host "Doanloading usbipd from $msiUrl" -ForegroundColor YELLOW
        curl -o $outputPath $msiUrl

        Write-Host "Installing usbipd" -ForegroundColor YELLOW
        Start-Process "msiexec.exe" -ArgumentList "/i `"$outputPath`" /quiet /norestart" -Wait
		
		$usbipd_path = "C:\Program Files\usbipd-win\usbipd.exe"

		if (Test-Path $usbipd_path) {
			Write-Host "USBIPD installed successfully" -ForegroundColor Green
			Set-IniValue -FilePath "$path2inf" -Key "keyboard" -Value 1
		} else {
			Write-Host "Something when wrong, path after installation not found. Retrying.." -ForegroundColor Yellow
			Start-Process "msiexec.exe" -ArgumentList "/i `"$outputPath`" /quiet /norestart" -Wait
				if (Test-Path $usbipd_path) {
					Write-Host "USBIPD installed successfully" -ForegroundColor Green
					Set-IniValue -FilePath "$path2inf" -Key "keyboard" -Value 1Set-IniValue -FilePath "$path2inf" -Key "keyboard" -Value 1
				} else {
					Write-Host "Something when wrong, path after installation not found. Try to install USBIPD manually." -ForegroundColor RED
					Set-IniValue -FilePath "$path2inf" -Key "keyboard" -Value 0
				}
		}
    }
	Set-IniValue -FilePath "$path2inf" -Key "usbipd" -Value 1
}
function check_WindowsOptionalFeature  {
	$features = @(
 "Microsoft-Windows-Subsystem-Linux",
 "VirtualMachinePlatform",
 "HypervisorPlatform"
)
foreach ($feature in $features) {
 	$status = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
 	if ($status -eq "Disabled") {
		Write-Host "Enabling feature: $feature" -ForegroundColor Yellow
		Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
        }
        $status = ((Get-WindowsOptionalFeature -Online -FeatureName $feature).State)
	if ($status -eq "Enabled") {
		write-host "Feature $feature is active" -ForegroundColor Green
		Set-IniValue -FilePath "$path2inf" -Key "WinFeature_$feature" -Value 1
	} elseif ($status -eq "Disabled") {
		Write-host "Failed: Feature $feature is not activated" -ForegroundColor RED
		Set-IniValue -FilePath "$path2inf" -Key "WinFeature_$feature" -Value 0
	} else {
			Write-host "Status unknown: $($status)" -ForegroundColor YELLOW
			Set-IniValue -FilePath "$path2inf" -Key "WinFeature_$feature" -Value 0
	}
}

#SET NAT to avoid usbipd error: networking mode 'virtioproxy' is not supported 
# Define the path to the .wslconfig file
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
# Define the content to enforce NAT networking mode
$wslConfigContent = @"
[wsl2]
networkingMode = nat
"@
# Write or overwrite the .wslconfig file
Set-Content -Path $wslConfigPath -Value $wslConfigContent -Encoding ASCII
Write-Host "WSL networking mode set to - nat" -ForegroundColor Yellow
sleep 2     
}

function restart_sys {
@"
@echo off
echo Continuing script after reboot...
cmd.exe /c "$path_after_restart\arch_install_win.bat"
pushd %~dp0
del "%~dp0after_reboot.bat"
"@ | Set-Content -Path $postRebootScript -Encoding Ascii

	# Prompt user for reboot confirmation
	Write-Host "=== Some features may require a reboot.  ===" -ForegroundColor Yellow
    	$confirmation = Read-Host "Do you want to proceed and reboot the system? (Y/N): "
	if ($confirmation -ne "Y" -and $confirmation -ne "y") {
		Write-Host "Operation cancelled by user."
		Set-IniValue -FilePath "$path2inf" -Key "Restart" -Value 0
    		exit(0)
	}
	Set-IniValue -FilePath "$path2inf" -Key "Restart" -Value 1
	# Restart the system
	Write-Host "System will restart in 10 seconds..."
	Start-Sleep -Seconds 10
	Restart-Computer
}

function check_debian {
	write-host "Checking wsl and Debian.." -ForegroundColor YELLOW
	$distroName = "Debian"
	wsl.exe --update
	$installedDistros = wsl.exe --list --quiet
 
    	if ($installedDistros -ccontains $distroName) {
        	Write-Host "Debian is installed." -ForegroundColor YELLOW
    	} else {
        	Write-Host "Installing Debian. This can take some time..." -ForegroundColor Yellow
        	wsl --install -d Debian --no-launch
        	Write-Host "Insallation done." -ForegroundColor Yellow
    	}
}

function attach_usb2wsl {
    # Get the list of USB devices
    $check_if_usb_is_recognized = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2}

    while ($check_if_usb_is_recognized -eq $null) {
        $check_if_usb_is_recognized = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2}
	Write-Host "No USB device found. Maybe is not recognized by system." -ForegroundColor Red
        write-host "Try to format or attach pther one." -ForegroundColor Yellow
        Write-Host "Attach and hit enter" -ForegroundColor Yellow
        Read-Host
        $null = Test-InternetConnection
    }

    $usbDevices = & "C:\Program Files\usbipd-win\usbipd.exe"  list | Where-Object { $_ -match '^\d{1,2}-\d+' }
    # Check if any devices were found
    if ($usbDevices.Count -eq 0) {
	Write-Host "No USB devices found." -ForegroundColor RED
    }

    # Display devices with index
    $indexedDevices = @()
    $i = 0
    Write-Host ""
    Write-Host ""
    write-host "Enter the number of the USB device to attach. Search for === USB Mass Storage Device ===" -ForegroundColor Yellow
    foreach ($device in $usbDevices) {
	Write-Host "[$i] $device" -ForegroundColor Magenta
	$indexedDevices += @{ Index = $i; Line = $device }
	$i++
    }

    # Prompt user to select a device
    Write-Host ""
    $selection = Read-Host "Enter the number: "

    # Validate selection
    if ($selection -match '^\d+$' -and $selection -lt $indexedDevices.Count) {
	$selectedLine = $indexedDevices[$selection].Line
	$busId = ($selectedLine -split '\s+')[0]
        $wslprocess = start-process -WindowStyle Minimized -FilePath "wsl.exe" -ArgumentList 'sudo bash $path2_init_script' -PassThru
        $wsl_pid = $wslprocess.Id
        Start-Sleep 2
	Write-Host "Selected BUSID: $busId" -ForegroundColor YELLOW
	Write-Host "Attaching device to WSL..." -ForegroundColor YELLOW
        usbipd bind --busid $busId
	usbipd attach --busid $busId --wsl Debian
        Start-Sleep 2
        taskkill /F /PID $wsl_pid    
    } else {
	Write-Host "Invalid selection." -ForegroundColor RED
    }
}

if (Test-Path  $path2inf) {
	$iniPath = "$path2inf"
	if (!(Test-Path $postRebootScript )) {
		Set-IniValue -FilePath "$path2inf" -Key "Restart" -Value 1
	}
	$get_progress = Get-Content $iniPath | Select-String "0"
	# Read the file and extract numbers
	Get-Content $iniPath | ForEach-Object {
		if ($_ -match '=\s*(\d+)') {
			$progress += [int]$matches[1]
		}
	}

	if ( $progress -eq 6) {
        	if (Test-Path $postRebootScript) {
			Remove-Item $postRebootScript -ErrorAction SilentlyContinue
        	}
	Write-Host "Starting Debian.." -ForegroundColor Yellow
	check_debian
	attach_usb2wsl
	wsl sudo bash "$path2script" --log-level debug
        Write-Host "Detach usb from Debian" -ForegroundColor Yellow
        usbipd detach --all
        Write-Host "Unbind $busId from WSL" -ForegroundColor Yellow
        usbipd unbind --all
	Exit(0)       
    } elseif (!($get_progress -eq $null )) {
		foreach ($line in $get_progress) {		
			write-host "Essential function is missing: $line " -ForegroundColor RED
			if ($line -like "*usbipd*") {
				check_usbipd
			}		
			if ($line -like "*WinFeature*") { 
				check_WindowsOptionalFeature
			}
			if ($line -like "*Restart*") { 
				write-host "After installing the features and usbipd, a system restart is required!" -ForegroundColor YELLOW
				restart_sys
			}			
		}
		restart_sys
	}
} else {
    set_keyboard
    check_usbipd
    check_WindowsOptionalFeature
    restart_sys
    Exit(0)
}
