<#
============================================================
 Auto-Subfolders.ps1
 Watches a parent folder and automatically creates subfolders
 inside each new folder created in it.
============================================================

How to add more subfolders in the future:
    Edit the $Subfolders list below. Add, remove, or
    reorder entries freely.

How to test it manually:
    powershell.exe -ExecutionPolicy Bypass -File .\Auto-Subfolders.ps1
============================================================
#>

# ============================================================
# CONFIGURATION - Edit here
# ============================================================

# Parent folder to watch. Can be local (C:\Projects) or a
# network path (\\Server\Projects) if the computer has access.
$WatchedFolder = "C:\PROGRAMAS\Visual Studio\Visual Studio Code\Proyectos"

# Subfolders to create inside each new folder.
$Subfolders = @(
    "01 - Documentation",
    "02 - WIP",
    "03 - Testing",
    "04 - Working",
    "05 - Resources"
    # "06 - Future folder"
)

# Log file path
$LogFile = "C:\Scripts\logs\AutoSubfolders\auto_subfolders.log"

# ============================================================
# LOGIC - normally no changes are needed below this line
# ============================================================

$LogDir = Split-Path $LogFile
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

if (-not (Test-Path $WatchedFolder)) {
    Write-Log "ERROR: The watched folder does not exist: $WatchedFolder"
    Write-Host "ERROR: The watched folder does not exist: $WatchedFolder" -ForegroundColor Red
    exit 1
}

$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path = $WatchedFolder
$fsw.IncludeSubdirectories = $false   # first level only
$fsw.NotifyFilter = [System.IO.NotifyFilters]'DirectoryName'
$fsw.Filter = "*"

$action = {
    $newPath = $Event.SourceEventArgs.FullPath
    $subfolders = $Event.MessageData.Subfolders
    $logFile = $Event.MessageData.LogFile

    function Log($message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $message" | Out-File -FilePath $logFile -Append -Encoding UTF8
        Write-Host "$timestamp - $message" -ForegroundColor Cyan
    }

    Log "New folder detected: $newPath"

    # Only act on directories (ignore individual files)
    $isDirectory = $false
    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        if (Test-Path $newPath -PathType Container) {
            $isDirectory = $true
            break
        }
        Start-Sleep -Milliseconds 300
    }
    if (-not $isDirectory) { return }

    foreach ($name in $subfolders) {
        $subPath = Join-Path $newPath $name
        try {
            if (-not (Test-Path $subPath)) {
                New-Item -ItemType Directory -Path $subPath -Force | Out-Null
                Log "Created: $subPath"
            }
        } catch {
            Log "ERROR creating $subPath : $_"
        }
    }
}

Register-ObjectEvent -InputObject $fsw -EventName Created -Action $action `
    -MessageData @{ Subfolders = $Subfolders; LogFile = $LogFile } | Out-Null
$fsw.EnableRaisingEvents = $true

Write-Log "Watching started in: $WatchedFolder"
Write-Host "Watching started in: $WatchedFolder" -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Green
Write-Host "Waiting for new folders... (Ctrl+C to stop)" -ForegroundColor Green

# Keep the process running indefinitely (it runs as a scheduled
# background task, so this loop never ends)
while ($true) {
    Wait-Event -Timeout 5 | Out-Null
}