# Claude Server Control Plugin - Windows Installer
# Usage: irm https://raw.githubusercontent.com/d0raka/claude-server-control-plugin/main/install.ps1 | iex

$RepoUrl    = "https://github.com/d0raka/claude-server-control-plugin"
$PluginName = "server-control"
$InstallDir = "$env:USERPROFILE\claude-server-control-plugin"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Claude Server Control Plugin - Installer    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# -- 1. Install git if missing ------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing git via winget..."
    winget install --id Git.Git -e --source winget --silent
    $env:PATH += ";C:\Program Files\Git\bin"
}

# -- 2. Clone or update -------------------------------------------------------
if (Test-Path "$InstallDir\.git") {
    Write-Host "Updating existing install..."
    git -C $InstallDir pull -q
} else {
    Write-Host "Downloading plugin..."
    git clone -q $RepoUrl $InstallDir
}

# -- 3. Choose platform -------------------------------------------------------
Write-Host ""
Write-Host "Which machine do you want to control?" -ForegroundColor Cyan
Write-Host "  1) Linux (Ubuntu, Debian, Raspberry Pi, etc.)"
Write-Host "  2) macOS"
Write-Host "  3) Windows"
Write-Host ""
$Platform = Read-Host "Enter 1, 2 or 3"

switch ($Platform) {
    "2" { $SkillSrc = "SKILL-mac.md";     $PlatformName = "macOS" }
    "3" { $SkillSrc = "SKILL-windows.md"; $PlatformName = "Windows" }
    default { $SkillSrc = "SKILL.md";     $PlatformName = "Linux" }
}

$SkillsDir = "$InstallDir\skills\server-control"

# -- 4. Get credentials -------------------------------------------------------
Write-Host ""
Write-Host "Enter your $PlatformName machine details:" -ForegroundColor Cyan
Write-Host ""
$ServerIP = Read-Host "  IP address (e.g. 100.64.0.5)"
$SshUser  = Read-Host "  SSH username (e.g. ubuntu)"
$SshPassSec = Read-Host "  SSH password" -AsSecureString
$SshPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SshPassSec)
)

# -- 5. Build plugin in a temp folder -----------------------------------------
$TempPlugin = "$env:TEMP\server-control-plugin-build"
if (Test-Path $TempPlugin) { Remove-Item $TempPlugin -Recurse -Force }
Copy-Item $InstallDir $TempPlugin -Recurse -Force

# -- 6. Activate the right SKILL file -----------------------------------------
$ActiveSkill = "$TempPlugin\skills\server-control\SKILL.md"
if ($SkillSrc -ne "SKILL.md") {
    if (Test-Path $ActiveSkill) {
        Rename-Item $ActiveSkill "$TempPlugin\skills\server-control\SKILL-linux.md" -Force -ErrorAction SilentlyContinue
    }
    Copy-Item "$TempPlugin\skills\server-control\$SkillSrc" $ActiveSkill
}

# -- 7. Fill in credentials ---------------------------------------------------
$content = Get-Content $ActiveSkill -Raw
$content = $content `
    -replace [regex]::Escape("YOUR_SERVER_IP"),  $ServerIP `
    -replace [regex]::Escape("YOUR_MAC_IP"),     $ServerIP `
    -replace [regex]::Escape("YOUR_WINDOWS_IP"), $ServerIP `
    -replace [regex]::Escape("YOUR_USERNAME"),   $SshUser `
    -replace [regex]::Escape("YOUR_PASSWORD"),   $SshPass
Set-Content $ActiveSkill $content -Encoding UTF8

# -- 8. Package as .plugin file (zip) -----------------------------------------
Write-Host ""
Write-Host "Creating your personalized .plugin file..." -ForegroundColor Yellow

$Desktop    = [Environment]::GetFolderPath("Desktop")
$PluginFile = "$Desktop\server-control.plugin"

if (Test-Path $PluginFile) { Remove-Item $PluginFile -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($TempPlugin, $PluginFile)

# Cleanup temp build
Remove-Item $TempPlugin -Recurse -Force

# -- 9. Done ------------------------------------------------------------------
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  Your plugin is ready!                       ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║                                               ║" -ForegroundColor Green
Write-Host "║  File saved to your Desktop:                 ║" -ForegroundColor Green
Write-Host "║    server-control.plugin                     ║" -ForegroundColor Green
Write-Host "║                                               ║" -ForegroundColor Green
Write-Host "║  To activate:                                ║" -ForegroundColor Green
Write-Host "║  Open Claude Cowork ->                       ║" -ForegroundColor Green
Write-Host "║  Customize -> Upload plugin                  ║" -ForegroundColor Green
Write-Host "║  Select: server-control.plugin               ║" -ForegroundColor Green
Write-Host "║                                               ║" -ForegroundColor Green
Write-Host "║  Start a new chat and Claude will connect    ║" -ForegroundColor Green
Write-Host "║  to your $PlatformName machine automatically.         ║" -ForegroundColor Green
Write-Host "║                                               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
