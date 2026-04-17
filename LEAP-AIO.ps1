# --- Logging Function ---
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

# --- Admin Escalation Logic ---
function Request-AdminPrivileges {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Log "Action requires elevation. Requesting Administrative privileges..." "Yellow"
        try {
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            exit # Close the non-admin window
        } catch {
            Write-Log "User declined or failed elevation. Cannot proceed with this task." "Red"
            Read-Host "Press Enter to exit..."
            exit
        }
    }
}

# --- Cleanup User AppData (Run before elevation) ---
function Uninstall-UserFolders {
    Write-Log "Starting User-level cleanup (No Admin required)..." "Cyan"
    $userFolders = @(
        "$env:APPDATA\4D",
        "$env:APPDATA\LEAP*",
        "$env:LOCALAPPDATA\LEAP*",
        "$env:TEMP\4D",
        "$env:TEMP\LEAP*",
        "$env:LOCALAPPDATA\Microsoft_Corporation\LEAP*"
    )
    
    foreach ($folderPattern in $userFolders) {
        Get-ChildItem -Path $folderPattern -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Log "Deleting user folder: $($_.FullName)" "Gray"
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "User-level folder cleanup complete." "Green"
}

# --- Uninstall System Components (Requires Admin) ---
function Uninstall-LEAP-System {
    Request-AdminPrivileges
    Write-Log "Searching registry for LEAP product codes..." "Cyan"
    
    $leapProducts = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, 
                                     HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                    Where-Object {$_.DisplayName -like "*LEAP*"}
    
    if ($leapProducts) {
        foreach ($product in $leapProducts) {
            $displayName = $product.DisplayName
            $productCode = $product.PSChildName
            
            if ($productCode -match '^{[A-F0-9-]+}$') {
                Write-Log "Invoking MSIExec for $displayName..." "Yellow"
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/X $productCode /qn" -PassThru -Wait -NoNewWindow
                if ($process.ExitCode -eq 0) { Write-Log "Successfully uninstalled $displayName" "Green" }
                else { Write-Log "Uninstaller failed for $displayName (Code: $($process.ExitCode))" "Red" }
            }
        }
    }

    Write-Log "Cleaning up System-protected folders..." "Cyan"
    $systemFolders = @(
        "$env:PROGRAMDATA\LEAP*",
        "$env:ProgramFiles\LEAP*",
        "$env:ProgramFiles(x86)\LEAP*"
    )
    foreach ($folderPattern in $systemFolders) {
        Get-ChildItem -Path $folderPattern -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Log "Deleting system folder: $($_.FullName)" "Gray"
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# --- Acrobat Integration Fix ---
function Acrobat-IntegrationFix {
    Request-AdminPrivileges
    $adobeProcesses = @("AcroRd32", "Acrobat")
    $installerPath = "C:\ProgramData\LEAP Office\Cloud\Extras\Acrobat Extras\InstallLauncher.exe"

    Write-Log "Monitoring Adobe processes..." "Cyan"
    while (Get-Process | Where-Object { $adobeProcesses -contains $_.ProcessName }) {
        Write-Log "Adobe is currently open. Please close it to proceed." "Yellow"
        Read-Host "Press Enter after closing Adobe..."
    }

    if (Test-Path $installerPath) {
        Write-Log "Launching Integration Installer..." "Cyan"
        Start-Process -FilePath $installerPath -Wait
        Write-Log "Integration Fix complete." "Green"
    } else {
        Write-Log "Error: Installer not found at $installerPath" "Red"
    }
}

# --- LEAP Installer ---
function Install-LEAP {
    Request-AdminPrivileges
    $installerUrl = "https://github.com/Hebbins/LEAP-Fix/raw/main/LEAPDesktopX64Setup.exe"
    $installerPath = "$env:TEMP\LEAPDesktopX64Setup.exe"
    
    Write-Log "Connecting to GitHub for latest installer..." "Cyan"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Write-Log "Download finished. Starting silent installation..." "Cyan"
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        Remove-Item $installerPath -Force
        Write-Log "LEAP Installation finished successfully." "Green"
    } catch {
        Write-Log "Installation failed: $($_.Exception.Message)" "Red"
    }
}

# --- Printer Fix (Runs as User) ---
function PrinterFix {
    Write-Log "Scanning for network-pathed (poisoned) printers..." "Cyan"
    $PoisonedPrinters = Get-Printer | Where-Object { $_.Name -like "\\*" }

    if (-not $PoisonedPrinters) {
        Write-Log "No poisoned printers found. System is clean." "Green"
        return
    }

    foreach ($Printer in $PoisonedPrinters) {
        Write-Log "Found: $($Printer.Name)" "Yellow"
        $Choice = Read-Host "Convert to Local Port fix? [Y/N]"
        if ($Choice -eq 'y') {
            Request-AdminPrivileges
            # Logic continues after elevation if user selects Y
            if (-not (Get-PrinterPort -Name $Printer.Name -ErrorAction SilentlyContinue)) {
                Add-PrinterPort -Name $Printer.Name
            }
            Add-Printer -Name ($Printer.Name.Replace("\\", "").Replace("\", "_") + " (Fixed)") -DriverName $Printer.DriverName -PortName $Printer.Name
            Remove-Printer -Name $Printer.Name
            Write-Log "Printer converted successfully." "Green"
        }
    }
}

# --- MAIN INTERFACE ---
Clear-Host
Write-Host "=================================== [ LEAP TOOLBOX ] ==================================="
Write-Host "(I)nstall LEAP           - Requires Admin"
Write-Host "(U)ninstall LEAP         - Cleans User AppData THEN requests Admin"
Write-Host "(B)oth (Reinstall)       - Performs full clean and fresh install"
Write-Host "(P)rint Crash Fix        - Run as User"
Write-Host "(A)crobat Integration    - Requires Admin"
Write-Host "========================================================================================"

$action = Read-Host "Select an option"

switch ($action.ToUpper()) {
    "I" { Install-LEAP }
    "U" { 
        Uninstall-UserFolders
        Uninstall-LEAP-System 
    }
    "B" { 
        Uninstall-UserFolders
        Uninstall-LEAP-System
        Install-LEAP 
    }
    "P" { PrinterFix }
    "A" { Acrobat-IntegrationFix }
    default { Write-Log "Invalid selection." "Red" }
}

Write-Log "Task Finished." "Green"
Read-Host "Press Enter to exit..."