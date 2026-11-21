
$ErrorActionPreference = "Stop"

# Paths
$BaseDir = "C:\user"
$RepoDir = Join-Path $BaseDir "BTC-Reciving-Address"
$MiningDir = Join-Path $RepoDir "windows"
$RepoURL = "https://github.com/Brij510/BTC-Reciving-Address.git"
$TaskName = "XMRig Miner"

Write-Host "`n=== XMRig Setup ===" -ForegroundColor Cyan

# 1. Create destination folder
New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

# 2. Install Git if necessary
$Git = Get-Command git -ErrorAction SilentlyContinue

if (-not $Git) {
    Write-Host "Installing Git..."
    winget install --id Git.Git -e --source winget `
        --accept-package-agreements --accept-source-agreements

    $GitExe = "C:\Program Files\Git\cmd\git.exe"

    if (Test-Path $GitExe) {
        $Git = $GitExe
    } else {
        throw "Git installation failed. Please install Git and run this script again."
    }
} else {
    $Git = $Git.Source
}

# 3. Download or update your repository
if (Test-Path (Join-Path $RepoDir ".git")) {
    Write-Host "Repository already exists. Updating..."
    & $Git -C $RepoDir pull --ff-only

    if ($LASTEXITCODE -ne 0) {
        throw "Git update failed."
    }
} else {
    if (Test-Path $RepoDir) {
        throw "Destination folder exists but is not a Git repository. Rename or inspect it first."
    }

    Write-Host "Downloading repository..."
    & $Git clone $RepoURL $RepoDir

    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed."
    }
}

# 4. Verify XMRig files
$Exe = Join-Path $MiningDir "xmrig.exe"
$Config = Join-Path $MiningDir "config.json"

if (-not (Test-Path $Exe)) {
    throw "xmrig.exe was not found in the Windows folder."
}

if (-not (Test-Path $Config)) {
    throw "config.json was not found in the Windows folder."
}

Write-Host "XMRig executable and configuration found." -ForegroundColor Green

# 5. Create a startup task
$Action = New-ScheduledTaskAction `
    -Execute $Exe `
    -WorkingDirectory $MiningDir

$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

$Principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Force | Out-Null

Write-Host "Startup task created successfully." -ForegroundColor Green

# 6. Start XMRig now
Start-ScheduledTask -TaskName $TaskName

Write-Host "`nSetup completed. Check XMRig and your mining dashboard." -ForegroundColor Green

