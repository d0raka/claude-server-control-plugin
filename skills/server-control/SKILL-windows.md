---
name: server-control
description: >
  Gives Claude full control over a remote Windows machine via SSH and PowerShell.
  Use when the user wants to run commands, check status, manage services, edit files,
  or do anything on a remote Windows machine.
  Trigger phrases: "my windows", "check the pc", "run on windows", "windows server".
---

# Server Control - Windows via SSH + PowerShell

> This is the Windows version. See SKILL.md for Linux, SKILL-mac.md for macOS.
> To activate: rename this file to SKILL.md.

## FIRST ACTION - run this before responding to the user

```python
import subprocess, sys

result = subprocess.run(
    ['find', '/sessions', '-name', 'SKILL.md', '-path', '*/server-control/SKILL.md'],
    capture_output=True, text=True
)
skill_paths = [p for p in result.stdout.strip().split('\n') if p]
skill_path = skill_paths[0] if skill_paths else None

needs_setup = True
if skill_path:
    content = open(skill_path).read()
    needs_setup = 'YOUR_WINDOWS_IP' in content

print(f"SKILL_PATH={skill_path}")
print(f"NEEDS_SETUP={needs_setup}")
```

**If `NEEDS_SETUP=True`:** Ask the user for:
1. Windows machine's Tailscale IP
2. Windows username
3. Password

Then save permanently:

```python
skill_path = "REPLACE_WITH_SKILL_PATH"
server_ip  = "REPLACE_WITH_IP"
username   = "REPLACE_WITH_USERNAME"
password   = "REPLACE_WITH_PASSWORD"

content = open(skill_path).read()
content = content.replace('YOUR_WINDOWS_IP', server_ip).replace('YOUR_USERNAME', username).replace('YOUR_PASSWORD', password)
open(skill_path, 'w').write(content)
print("configured")
```

**If `NEEDS_SETUP=False`:** Connect silently and continue.

---

## SSH Connection

```
Host     : YOUR_WINDOWS_IP
User     : YOUR_USERNAME
Password : YOUR_PASSWORD
Port     : 22
Shell    : PowerShell (set as default)
```

Enable SSH on Windows (run as Admin in PowerShell):
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
```

Connect silently:

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

---

## Command Pattern - always use PowerShell

```python
import paramiko

def run(cmd, timeout=60):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect('YOUR_WINDOWS_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
    ps_cmd = f'powershell -NonInteractive -Command "{cmd}"' if not cmd.startswith('powershell') else cmd
    stdin, stdout, stderr = client.exec_command(ps_cmd, timeout=timeout)
    out = stdout.read().decode('utf-8', errors='replace').strip()
    err = stderr.read().decode('utf-8', errors='replace').strip()
    client.close()
    return out if out else err

print(run('Get-Process | Sort-Object CPU -Descending | Select-Object -First 10'))
print(run('Get-Service | Where-Object {$_.Status -eq "Running"}'))
```

---

## Quick Reference

```powershell
Get-ComputerInfo | Select-Object WindowsVersion, TotalPhysicalMemory
Get-PSDrive C | Select-Object Used, Free
Get-Service | Where-Object {$_.Status -eq 'Running'} | Sort-Object DisplayName
Restart-Service SERVICE_NAME
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
Get-EventLog -LogName System -EntryType Error -Newest 20
netstat -ano | Select-String LISTENING
docker ps
```

## Behavior Rules

1. Check setup first on every load
2. If not configured - ask for credentials, save them
3. If configured - connect silently
4. Always wrap commands in PowerShell
5. Always execute and show real output
