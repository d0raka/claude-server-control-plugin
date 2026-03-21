# Claude Server Control Plugin — Windows Setup
# Run this as Administrator in PowerShell on the Windows machine you want to control

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Claude Server Control — Windows Setup   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. Install and enable OpenSSH Server
Write-Host "→ Checking OpenSSH Server..." -ForegroundColor Yellow

$sshFeature = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server*" }
if ($sshFeature.State -ne "Installed") {
    Write-Host "  Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "  ✓ OpenSSH Server installed"
} else {
    Write-Host "  ✓ OpenSSH Server already installed"
}

# Start and enable the service
$sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
if ($sshdService.Status -ne "Running") {
    Start-Service sshd
    Write-Host "  ✓ sshd service started"
} else {
    Write-Host "  ✓ sshd service already running"
}
Set-Service -Name sshd -StartupType Automatic

# 2. Set PowerShell as default SSH shell
Write-Host ""
Write-Host "→ Setting PowerShell as default SSH shell..." -ForegroundColor Yellow
$psPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
if (Test-Path $psPath) {
    $registryPath = "HKLM:\SOFTWARE\OpenSSH"
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    New-ItemProperty -Path $registryPath -Name DefaultShell -Value $psPath `
        -PropertyType String -Force | Out-Null
    Write-Host "  ✓ PowerShell set as default SSH shell"
} else {
    Write-Host "  ✗ Could not find PowerShell at $psPath" -ForegroundColor Red
}

# 3. Allow SSH through firewall
Write-Host ""
Write-Host "→ Configuring Windows Firewall..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    New-NetFirewallRule -Name sshd -DisplayName "OpenSSH Server (sshd)" `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    Write-Host "  ✓ Firewall rule created (port 22)"
} else {
    Write-Host "  ✓ Firewall rule already exists"
}

# 4. Check Tailscale
Write-Host ""
Write-Host "→ Checking Tailscale..." -ForegroundColor Yellow
$tailscale = Get-Command tailscale -ErrorAction SilentlyContinue
if ($tailscale) {
    $tailscaleIP = (tailscale ip -4 2>$null)
    if ($tailscaleIP) {
        Write-Host "  ✓ Tailscale IP: $tailscaleIP"
    } else {
        Write-Host "  ! Tailscale installed but not connected. Open Tailscale and sign in."
    }
} else {
    Write-Host "  ! Tailscale not found." -ForegroundColor Yellow
    Write-Host "    Install from: https://tailscale.com/download/windows"
}

# 5. Print summary
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  Paste these into your SKILL-windows.md: ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor Green

$tsIP = (tailscale ip -4 2>$null) ?? (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty IPAddress) ?? "unknown"
$username = $env:USERNAME
$osVersion = (Get-CimInstance Win32_OperatingSystem).Caption

Write-Host ("║  YOUR_WINDOWS_IP = {0,-21}║" -f $tsIP) -ForegroundColor Green
Write-Host ("║  YOUR_USERNAME   = {0,-21}║" -f $username) -ForegroundColor Green
Write-Host ("║  OS              = {0,-21}║" -f ($osVersion.Substring(0, [Math]::Min(21, $osVersion.Length)))) -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Skill to use: SKILL-windows.md          ║" -ForegroundColor Green
Write-Host "║  → Rename it to SKILL.md to activate     ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Edit skills/server-control/SKILL-windows.md with your details"
Write-Host "      Rename SKILL-windows.md → SKILL.md (and rename SKILL.md → SKILL-linux.md)"
Write-Host "Then: Load the plugin in Claude Cowork → Settings → Plugins"
