---
name: server-control
description: >
  Gives Claude full control over a remote Windows machine via SSH and PowerShell. Use when
  the user asks to run commands, check status, manage Windows services, edit files,
  control Docker, view event logs, or do anything on the remote Windows machine.
  Trigger phrases: "run on my PC", "check the windows server", "restart the service",
  "what's running", "deploy", "fix it on the server", "edit file on windows".
---

# Server Control - Windows via SSH + PowerShell

> **Other platforms:** See `SKILL.md` for Linux, `SKILL-mac.md` for macOS.
> To activate this file, rename it to `SKILL.md`.

---

## ⚙️ SETUP - Fill in your details

| Placeholder | Replace with |
|------------|--------------|
| `YOUR_WINDOWS_IP` | Tailscale IP recommended (e.g. `100.64.0.5`) |
| `YOUR_USERNAME` | Windows username (e.g. `Administrator`, `john`) |
| `YOUR_PASSWORD` | Windows account password |

**Enable SSH on your Windows machine first** (run as Administrator in PowerShell):
```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and enable the service
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Set PowerShell as default shell (recommended)
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
  -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -PropertyType String -Force

# Allow through firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' `
  -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

---

## FIRST ACTION - connect silently on load

Run this before responding to the user:

```python
import subprocess, sys
try:
    import paramiko
except ImportError:
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'paramiko', '--break-system-packages', '-q'])
    import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('YOUR_WINDOWS_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
stdin, stdout, _ = client.exec_command('powershell -Command "hostname; Get-Date"')
print(stdout.read().decode())
client.close()
```

✅ Success → continue normally.
❌ Failure → tell user: "Can't connect. Check that OpenSSH Server service is running and Tailscale is active."

---

## SSH Details

```
Host     : YOUR_WINDOWS_IP
User     : YOUR_USERNAME
Password : YOUR_PASSWORD
Port     : 22
Shell    : PowerShell (set as default above)
```

**Key-based auth (more secure):**
```python
client.connect('YOUR_WINDOWS_IP', username='YOUR_USERNAME',
               key_filename='/path/to/private_key', timeout=10)
```

---

## Command Pattern - use for everything

> ⚠️ All commands go through PowerShell. Wrap them with `powershell -Command "..."` if needed.

```python
import paramiko

def run(cmd, timeout=60):
    """Run a PowerShell command on the Windows machine."""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect('YOUR_WINDOWS_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
    # Wrap in powershell if not already
    ps_cmd = f'powershell -NonInteractive -Command "{cmd}"' if not cmd.startswith('powershell') else cmd
    stdin, stdout, stderr = client.exec_command(ps_cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace').strip()
    err = stderr.read().decode('utf-8', errors='replace').strip()
    client.close()
    return out if out else err

# Examples:
print(run('Get-Process | Sort-Object CPU -Descending | Select-Object -First 10'))
print(run('Get-Service | Where-Object {$_.Status -eq "Running"}'))
print(run('Get-PSDrive C | Select-Object Used,Free'))
print(run('docker ps'))
```

---

## Windows Info

```
OS   : Windows 11 / Windows Server 2022 / (fill in)
IP   : YOUR_WINDOWS_IP
User : YOUR_USERNAME
CPU  : ...
RAM  : ...
```

---

## My Services

> Edit this table - Windows uses `Get-Service` / `sc.exe`

| Service | Display Name | Manage |
|---------|-------------|--------|
| IIS | World Wide Web | `Restart-Service W3SVC` |
| SQL Server | MSSQLSERVER | `Restart-Service MSSQLSERVER` |
| (your service) | | `Restart-Service SERVICE_NAME` |

---

## Key Paths

```
C:\Users\YOUR_USERNAME\    - home
C:\Users\YOUR_USERNAME\Desktop\
C:\Program Files\          - installed programs
C:\Windows\System32\       - system
C:\inetpub\wwwroot\        - IIS web root (if applicable)
```

---

## Behavior Rules

1. **Connect silently first** - run SSH check at skill load, before responding
2. **Always execute** - never just describe, always run the actual command
3. **Use PowerShell** - all commands through PowerShell, not CMD
4. **Show real output** - paste results, not summaries
5. **Auto-retry** - if it fails, try an alternative PowerShell approach
6. **Escape properly** - use single quotes inside PowerShell strings when possible

---

## Quick Reference

```powershell
# Health
Get-ComputerInfo | Select-Object WindowsVersion, TotalPhysicalMemory
Get-PSDrive C | Select-Object @{N='UsedGB';E={[math]::Round($_.Used/1GB,1)}}, @{N='FreeGB';E={[math]::Round($_.Free/1GB,1)}}
Get-Uptime
whoami

# Processes & CPU
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, CPU, WorkingSet
Stop-Process -Name PROCESS_NAME -Force
tasklist

# Services
Get-Service | Where-Object {$_.Status -eq 'Running'} | Sort-Object DisplayName
Get-Service -Name SERVICE_NAME
Start-Service SERVICE_NAME
Stop-Service SERVICE_NAME
Restart-Service SERVICE_NAME

# Network
netstat -ano | Select-String LISTENING
Get-NetTCPConnection -State Listen | Select-Object LocalPort, OwningProcess
Test-NetConnection -ComputerName google.com -Port 443

# Files & Disk
Get-ChildItem C:\ | Sort-Object Length -Descending | Select-Object -First 20 Name, Length
Get-ChildItem -Path C:\ -Recurse -File | Sort-Object Length -Descending | Select-Object -First 10

# Event Logs (last 50 errors)
Get-EventLog -LogName Application -EntryType Error -Newest 50
Get-EventLog -LogName System -EntryType Error -Newest 20

# Windows Update
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10

# Docker (if installed)
docker ps
docker logs CONTAINER --tail=50
docker restart CONTAINER

# Firewall
Get-NetFirewallRule | Where-Object {$_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound'} | Select-Object DisplayName, LocalPort
New-NetFirewallRule -DisplayName "Allow PORT" -Direction Inbound -Protocol TCP -LocalPort PORT -Action Allow

# Registry (example)
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName

# Scheduled Tasks
Get-ScheduledTask | Where-Object {$_.State -ne 'Disabled'} | Select-Object TaskName, State
```
