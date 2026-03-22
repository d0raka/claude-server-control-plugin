---
name: server-control
description: >
  Gives Claude full control over a remote macOS machine via SSH. Use when the user
  wants to run commands, check status, manage apps or services, edit files, view logs,
  or do anything on a remote Mac.
  Trigger phrases: "my mac", "check the mac", "run on my mac", "mac server".
---

# Server Control - macOS via SSH

> This is the macOS version. See SKILL.md for Linux, SKILL-windows.md for Windows.
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
    needs_setup = 'YOUR_MAC_IP' in content

print(f"SKILL_PATH={skill_path}")
print(f"NEEDS_SETUP={needs_setup}")
```

**If `NEEDS_SETUP=True`:** Ask the user for:
1. Mac's Tailscale IP (or local IP)
2. macOS username
3. Password

Then save permanently:

```python
skill_path = "REPLACE_WITH_SKILL_PATH"
server_ip  = "REPLACE_WITH_IP"
username   = "REPLACE_WITH_USERNAME"
password   = "REPLACE_WITH_PASSWORD"

content = open(skill_path).read()
content = content.replace('YOUR_MAC_IP', server_ip).replace('YOUR_USERNAME', username).replace('YOUR_PASSWORD', password)
open(skill_path, 'w').write(content)
print("configured")
```

**If `NEEDS_SETUP=False`:** Connect silently and continue.

---

## SSH Connection

```
Host     : YOUR_MAC_IP
User     : YOUR_USERNAME
Password : YOUR_PASSWORD
Port     : 22
```

Enable SSH on Mac: System Settings -> General -> Sharing -> Remote Login

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
client.connect('YOUR_MAC_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
stdin, stdout, _ = client.exec_command('echo "connected: $(hostname) | $(date)"')
print(stdout.read().decode())
client.close()
```

---

## Command Pattern

```python
import paramiko

def run(cmd, timeout=60):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect('YOUR_MAC_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    client.close()
    return out if out else err

print(run('vm_stat | head -5 && df -h && uptime'))
print(run('brew services list'))
print(run('docker ps'))
```

---

## Quick Reference

```bash
vm_stat | head -5 && df -h && uptime
brew services list
brew services restart SERVICE_NAME
launchctl list | grep -v "0.*0"
docker ps && docker logs CONTAINER --tail=50
ps aux --sort=-%cpu | head -10
log show --last 1h --predicate 'eventMessage contains "error"' | tail -20
screencapture -x ~/Desktop/screenshot.png
netstat -an | grep LISTEN | head -20
```

## Behavior Rules

1. Check setup first on every load
2. If not configured - ask for credentials, save them
3. If configured - connect silently
4. Always execute and show real output
5. Prefer `brew`, `launchctl`, `open` over Linux equivalents
