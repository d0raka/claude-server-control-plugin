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

# ── 1. Install git if missing ────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing git via winget..."
    winget install --id Git.Git -e --source winget --silent
    $env:PATH += ";C:\Program Files\Git\bin"
}

# ── 2. Clone or update ───────────────────────────────────────────────────────
if (Test-Path "$InstallDir\.git") {
    Write-Host "Updating existing install..."
    git -C $InstallDir pull -q
} else {
    Write-Host "Downloading plugin..."
    git clone -q $RepoUrl $InstallDir
}

# ── 3. Choose platform ──────────────────────────────────────────────────────
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

# ── 4. Get credentials ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "Enter your $PlatformName machine details:" -ForegroundColor Cyan
Write-Host ""
$ServerIP = Read-Host "  IP address (e.g. 100.64.0.5)"
$SshUser  = Read-Host "  SSH username (e.g. ubuntu)"
$SshPassSec = Read-Host "  SSH password" -AsSecureString
$SshPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SshPassSec)
)

# ── 5. Activate the right SKILL file ────────────────────────────────────────
$ActiveSkill = "$SkillsDir\SKILL.md"
if ($SkillSrc -ne "SKILL.md") {
    if (Test-Path $ActiveSkill) {
        Rename-Item $ActiveSkill "$SkillsDir\SKILL-linux.md" -Force -ErrorAction SilentlyContinue
    }
    Copy-Item "$SkillsDir\$SkillSrc" $ActiveSkill
}

# ── 6. Fill in credentials ──────────────────────────────────────────────────
$content = Get-Content $ActiveSkill -Raw
$content = $content `
    -replace [regex]::Escape("YOUR_SERVER_IP"),  $ServerIP `
    -replace [regex]::Escape("YOUR_MAC_IP"),     $ServerIP `
    -replace [regex]::Escape("YOUR_WINDOWS_IP"), $ServerIP `
    -replace [regex]::Escape("YOUR_USERNAME"),   $SshUser `
    -replace [regex]::Escape("YOUR_PASSWORD"),   $SshPass
Set-Content $ActiveSkill $content -Encoding UTF8

# ── 7. Auto-register in Claude Cowork ───────────────────────────────────────
Write-Host ""
Write-Host "Registering plugin in Claude Cowork..." -ForegroundColor Yellow

$Registered = $false

$ClaudeSessions = "$env:APPDATA\Claude\local-agent-mode-sessions"

if (Test-Path $ClaudeSessions) {
    # Find the most recently modified installed_plugins.json
    $PluginsJson = Get-ChildItem $ClaudeSessions -Recurse -Filter "installed_plugins.json" -ErrorAction SilentlyContinue `
        | Sort-Object LastWriteTime -Descending `
        | Select-Object -First 1

    if ($PluginsJson) {
        $MarketplaceDir = Join-Path (Split-Path $PluginsJson.FullName) "marketplaces\local-desktop-app-uploads"
        $PluginDest     = Join-Path $MarketplaceDir $PluginName

        # Copy plugin to Claude's marketplace folder
        if (-not (Test-Path $MarketplaceDir)) { New-Item -ItemType Directory -Path $MarketplaceDir -Force | Out-Null }
        if (Test-Path $PluginDest) { Remove-Item $PluginDest -Recurse -Force }
        Copy-Item $InstallDir $PluginDest -Recurse

        # Update installed_plugins.json
        $Now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $JsonData = Get-Content $PluginsJson.FullName -Raw | ConvertFrom-Json

        $PluginKey = "${PluginName}@local-desktop-app-uploads"

        $NewEntry = [PSCustomObject]@{
            scope       = "user"
            installPath = $PluginDest
            version     = "2.0.0"
            installedAt = $Now
            lastUpdated = $Now
        }

        if (-not $JsonData.plugins) {
            $JsonData | Add-Member -MemberType NoteProperty -Name "plugins" -Value ([PSCustomObject]@{})
        }

        $JsonData.plugins | Add-Member -MemberType NoteProperty -Name $PluginKey -Value @($NewEntry) -Force

        $JsonData | ConvertTo-Json -Depth 10 | Set-Content $PluginsJson.FullName -Encoding UTF8

        $Registered = $true
        Write-Host "  Plugin registered successfully." -ForegroundColor Green
    }
}

# ── 8. Done ──────────────────────────────────────────────────────────────────
Write-Host ""
if ($Registered) {
    Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  All done!                                   ║" -ForegroundColor Green
    Write-Host "╠═══════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║                                               ║" -ForegroundColor Green
    Write-Host "║  The plugin was installed automatically.      ║" -ForegroundColor Green
    Write-Host "║  Just restart Claude Cowork and start         ║" -ForegroundColor Green
    Write-Host "║  a new chat - Claude connects automatically.  ║" -ForegroundColor Green
    Write-Host "║                                               ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  One manual step needed:                     ║" -ForegroundColor Yellow
    Write-Host "╠═══════════════════════════════════════════════╣" -ForegroundColor Yellow
    Write-Host "║                                               ║" -ForegroundColor Yellow
    Write-Host "║  Open Claude Cowork:                         ║" -ForegroundColor Yellow
    Write-Host "║  Settings -> Plugins -> Load local plugin    ║" -ForegroundColor Yellow
    Write-Host "║                                               ║" -ForegroundColor Yellow
    Write-Host "║  Select: $InstallDir" -ForegroundColor Yellow
    Write-Host "║                                               ║" -ForegroundColor Yellow
    Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Start-Process explorer.exe $InstallDir
}
Write-Host ""
