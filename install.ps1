# Claude Server Control Plugin - Windows Installer
# Run this in PowerShell on your computer (the one with Claude Cowork)
# Usage: irm https://raw.githubusercontent.com/d0raka/claude-server-control-plugin/main/install.ps1 | iex

$RepoUrl = "https://github.com/d0raka/claude-server-control-plugin"
$InstallDir = "$env:USERPROFILE\claude-server-control-plugin"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Claude Server Control Plugin - Installer   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check for git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing via winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget
    $env:PATH += ";C:\Program Files\Git\bin"
}

# Clone or update
if (Test-Path $InstallDir) {
    Write-Host "Found existing install - updating..." -ForegroundColor Yellow
    git -C $InstallDir pull -q
} else {
    Write-Host "Downloading plugin..."
    git clone -q $RepoUrl $InstallDir
}

Write-Host ""
Write-Host "Which machine do you want to control?" -ForegroundColor Cyan
Write-Host "  1) Linux (Ubuntu, Debian, Raspberry Pi, etc.)"
Write-Host "  2) macOS"
Write-Host "  3) Windows"
Write-Host ""
$Platform = Read-Host "Enter 1, 2 or 3"

switch ($Platform) {
    "1" { $SkillSrc = "SKILL.md";         $PlatformName = "Linux" }
    "2" { $SkillSrc = "SKILL-mac.md";     $PlatformName = "macOS" }
    "3" { $SkillSrc = "SKILL-windows.md"; $PlatformName = "Windows" }
    default { $SkillSrc = "SKILL.md";     $PlatformName = "Linux" }
}

$SkillsDir = "$InstallDir\skills\server-control"

Write-Host ""
Write-Host "Enter your $PlatformName machine details:" -ForegroundColor Cyan
Write-Host "(These will be saved into the plugin - keep this folder private)"
Write-Host ""
$ServerIP  = Read-Host "  IP address (e.g. 100.64.0.5)"
$SshUser   = Read-Host "  SSH username (e.g. ubuntu)"
$SshPass   = Read-Host "  SSH password" -AsSecureString
$SshPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SshPass)
)

# Activate the right SKILL file
$ActiveSkill = "$SkillsDir\SKILL.md"
if ($SkillSrc -ne "SKILL.md") {
    if (Test-Path $ActiveSkill) {
        Rename-Item $ActiveSkill "$SkillsDir\SKILL-backup.md" -Force -ErrorAction SilentlyContinue
    }
    Copy-Item "$SkillsDir\$SkillSrc" $ActiveSkill
}

# Fill in credentials
$content = Get-Content $ActiveSkill -Raw
$content = $content `
    -replace "YOUR_SERVER_IP",   $ServerIP `
    -replace "YOUR_MAC_IP",      $ServerIP `
    -replace "YOUR_WINDOWS_IP",  $ServerIP `
    -replace "YOUR_USERNAME",    $SshUser `
    -replace "YOUR_PASSWORD",    $SshPassPlain
Set-Content $ActiveSkill $content -Encoding UTF8

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Done! One step left:                       ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║                                               ║" -ForegroundColor Green
Write-Host "║   Open Claude Cowork and:                    ║" -ForegroundColor Green
Write-Host "║   Settings -> Plugins -> Load local plugin   ║" -ForegroundColor Green
Write-Host "║                                               ║" -ForegroundColor Green
Write-Host "║   Select this folder:                        ║" -ForegroundColor Green
Write-Host "║   $InstallDir" -ForegroundColor Green
Write-Host "║                                               ║" -ForegroundColor Green
Write-Host "║   Then start a new chat - Claude will         ║" -ForegroundColor Green
Write-Host "║   connect to your machine automatically.      ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Opening folder now..."
Start-Process explorer.exe $InstallDir
