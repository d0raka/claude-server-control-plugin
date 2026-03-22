---
name: server-control
description: >
  Gives Claude full control over a remote computer via SSH. Use when the user asks to
  run commands, check server status, manage services, edit files, control Docker,
  restart services, view logs, or do anything on a remote machine.
  Trigger phrases: "run on server", "check the server", "restart", "deploy",
  "server status", "what's running", "fix it", "ssh", "remote machine",
  "connect to my server", "run on my computer", "check my mac", "check my pc".
---

# Server Control - Remote Machine via SSH

## FIRST ACTION - run this before responding to the user

```python
import subprocess, sys

# Find this SKILL.md on disk to check if configured
result = subprocess.run(
    ['find', '/sessions', '-name', 'SKILL.md', '-path', '*/server-control/SKILL.md'],
    capture_output=True, text=True
)
skill_paths = [p for p in result.stdout.strip().split('\n') if p]
skill_path = skill_paths[0] if skill_paths else None

needs_setup = True
if skill_path:
    content = open(skill_path).read()
    needs_setup = 'YOUR_SERVER_IP' in content

print(f"SKILL_PATH={skill_path}")
print(f"NEEDS_SETUP={needs_setup}")
```

**If `NEEDS_SETUP=True`:** Do NOT attempt to SSH. Tell the user:

> "Hi! First time setup - I need a few details to connect to your machine. What OS is it running? (Linux / macOS / Windows)"

Then ask for:
1. IP address (recommend Tailscale - explain it's a free private VPN)
2. SSH username
3. SSH password

After getting all details, run this to save them permanently:

```python
skill_path = "REPLACE_WITH_SKILL_PATH_FROM_ABOVE"
server_ip  = "REPLACE_WITH_USER_IP"
username   = "REPLACE_WITH_USER_USERNAME"
password   = "REPLACE_WITH_USER_PASSWORD"
platform   = "REPLACE_WITH_linux_OR_mac_OR_windows"

content = open(skill_path).read()
content = content.replace('YOUR_SERVER_IP',  server_ip)
content = content.replace('YOUR_MAC_IP',     server_ip)
content = content.replace('YOUR_WINDOWS_IP', server_ip)
content = content.replace('YOUR_USERNAME',   username)
content = content.replace('YOUR_PASSWORD',   password)
content = content.replace('ACTIVE_PLATFORM', platform)
open(skill_path, 'w').write(content)
print("Plugin configured successfully!")
```

Then connect and continue normally.

**If `NEEDS_SETUP=False`:** Connect silently (see below) and continue normally.

---

## SSH Connection

```
Host     : YOUR_SERVER_IP
User     : YOUR_USERNAME
Password : YOUR_PASSWORD
Port     : 22
Platform : ACTIVE_PLATFORM
```

Connect silently before every response:

```python
import subprocess, sys
try:
    import paramiko
except ImportError:
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'paramiko', '--break-system-packages', '-q'])
    import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('YOUR_SERVER_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
stdin, stdout, _ = client.exec_command('echo "connected: $(hostname) | $(date)"')
print(stdout.read().decode())
client.close()
```

If it fails: "Can't connect. Is Tailscale running and the machine online?"

---

## Command Pattern - use for everything

```python
import paramiko

def run(cmd, timeout=60):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect('YOUR_SERVER_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    client.close()
    return out if out else err

print(run('df -h && free -h && uptime'))
```

---

## Platform Commands

**Linux:**
```bash
free -h && df -h && uptime
systemctl list-units --type=service --state=running
systemctl restart SERVICE_NAME
journalctl -u SERVICE_NAME -n 50 --no-pager
docker ps
tmux list-sessions
```

**macOS:**
```bash
vm_stat | head -5 && df -h && uptime
brew services list
brew services restart SERVICE_NAME
docker ps
```

**Windows - wrap all commands in PowerShell:**
```python
run('powershell -Command "Get-Service | Where-Object {$_.Status -eq \'Running\'}"')
run('powershell -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10"')
run('powershell -Command "Get-EventLog -LogName System -EntryType Error -Newest 20"')
```

---

## Behavior Rules

1. **Check setup first** - run the FIRST ACTION block before anything else
2. **If not configured** - ask for credentials, save them, then connect
3. **If configured** - connect silently, never announce it
4. **Always execute** - run the command and show real output, never just describe
5. **Auto-retry** - if something fails, try an alternative approach
6. **Re-configure** - if user says "connect to a different machine", run setup again
