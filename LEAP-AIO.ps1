# Function to check and request administrative privileges
function Request-AdminPrivileges {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Output "Not running with administrative privileges. Requesting elevation..."
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iex (irm )`""
        return $false
    }
    
    Write-Output "Running with administrative privileges, moving on..."
    return $true
}

# Function to uninstall LEAP
function Uninstall-LEAP {
    $leapProducts = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                    Where-Object {$_.DisplayName -like "*LEAP*"}
    
    if ($leapProducts) {
        foreach ($product in $leapProducts) {
            $displayName = $product.DisplayName
            $productCode = $product.PSChildName
            
            if ($productCode -match '^{[A-F0-9-]+}$') {
                Write-Host "Uninstalling $displayName with Product Code: $productCode"
                
                try {
                    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/X $productCode /qn" -PassThru -Wait -NoNewWindow
                    
                    if ($process.ExitCode -eq 0) {
                        Write-Host "$displayName uninstalled successfully."
                    } else {
                        Write-Host "Failed to uninstall $displayName. Exit code: $($process.ExitCode)"
                    }
                } catch {
                    Write-Host "Error uninstalling {$displayName}: $_"
                }
            } else {
                Write-Host "Invalid Product Code format for {$displayName}: $productCode"
            }
        }
    } else {
        Write-Host "No LEAP products found to uninstall."
    }

    # Delete folders
    $foldersToDelete = @(
        "$env:APPDATA\4D",
        "$env:APPDATA\LEAP*",
        "$env:LOCALAPPDATA\LEAP*",
        "$env:PROGRAMDATA\LEAP*",
        "$env:ProgramFiles\LEAP*",
        "$env:ProgramFiles(x86)\LEAP*",
        "$env:TEMP\4D",
        "$env:TEMP\LEAP*",
        "$env:LOCALAPPDATA\Microsoft_Corporation\LEAP*"
    )
    
    foreach ($folderPattern in $foldersToDelete) {
        Get-ChildItem -Path $folderPattern -Directory -ErrorAction SilentlyContinue | 
        ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to install LEAP
function Install-LEAP {
    $installerUrl = "https://github.com/Hebbins/LEAP-Fix/raw/main/LEAPDesktopX64Setup.exe"
    $installerPath = "$env:TEMP\LEAPDesktopX64Setup.exe"
    
    Write-Host "Downloading LEAP installer from GitHub..."
    
    try {
        # Use TLS 1.2 for GitHub API compatibility
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        
        if (Test-Path $installerPath) {
            Write-Host "Download successful. Installing LEAP..."
            Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
            
            # Clean up the installer
            Remove-Item -Path $installerPath -Force
            Write-Host "LEAP installation completed."
        } else {
            Write-Host "Error: Installer download failed. File not found."
        }
    } catch {
        Write-Host "Error downloading or installing LEAP: $_"
    }
}

# Main script
if (Request-AdminPrivileges) {
    $action = Read-Host "Do you want to (I)nstall, (U)ninstall, or do (B)oth? Enter I, U, or B"
    
    switch ($action.ToUpper()) {
        "I" {
            Write-Host "Installing LEAP..."
            Install-LEAP
        }
        "U" {
            Write-Host "Uninstalling LEAP..."
            Uninstall-LEAP
        }
        "B" {
            Write-Host "Uninstalling and then installing LEAP..."
            Uninstall-LEAP
            Install-LEAP
        }
        default {
            Write-Host "Invalid option. Please run the script again and choose I, U, or B."
        }
    }
    
    Write-Host "Operation completed."
}