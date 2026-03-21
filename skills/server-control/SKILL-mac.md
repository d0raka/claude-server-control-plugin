---
name: server-control
description: >
  Gives Claude full control over a remote macOS machine via SSH. Use when the user asks to
  run commands, check status, manage apps or services, edit files, control Docker,
  view logs, or do anything on the remote Mac.
  Trigger phrases: "run on my mac", "check the mac", "restart", "what's running on the mac",
  "deploy", "fix it on the server", "edit file on the mac".
---

# Server Control — macOS via SSH

> **Other platforms:** See `SKILL.md` for Linux, `SKILL-windows.md` for Windows.
> To activate this file, rename it to `SKILL.md`.

---

## ⚙️ SETUP — Fill in your details

| Placeholder | Replace with |
|------------|--------------|
| `YOUR_MAC_IP` | Tailscale IP recommended (e.g. `100.64.0.5`) |
| `YOUR_USERNAME` | macOS username (e.g. `john`, `admin`) |
| `YOUR_PASSWORD` | SSH password — or use key auth below |

**Enable SSH on your Mac first:**
Go to System Settings → General → Sharing → Enable "Remote Login"
Or via terminal: `sudo systemsetup -setremotelogin on`

---

## FIRST ACTION — connect silently on load

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
client.connect('YOUR_MAC_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
stdin, stdout, _ = client.exec_command('echo "connected: $(hostname) | $(date)"')
print(stdout.read().decode())
client.close()
```

✅ Success → continue normally.
❌ Failure → tell user: "Can't connect. Check that Remote Login is enabled on the Mac and Tailscale is running."

---

## SSH Details

```
Host     : YOUR_MAC_IP
User     : YOUR_USERNAME
Password : YOUR_PASSWORD
Port     : 22
```

**Key-based auth (more secure):**
```python
client.connect('YOUR_MAC_IP', username='YOUR_USERNAME',
               key_filename='/path/to/private_key', timeout=10)
```

---

## Command Pattern — use for everything

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

print(run('df -h && vm_stat && uptime'))
print(run('brew services list'))
print(run('docker ps'))
```

---

## Mac Info

```
OS   : macOS Sonoma / Ventura / (fill in)
IP   : YOUR_MAC_IP
User : YOUR_USERNAME
CPU  : Apple M1/M2/Intel (fill in)
RAM  : ...
```

---

## My Services

> Edit this table — macOS uses `launchctl` / `brew services`

| Service | How to manage |
|---------|--------------|
| Homebrew services | `brew services list` / `brew services restart NAME` |
| nginx (brew) | `brew services restart nginx` |
| postgresql (brew) | `brew services restart postgresql` |
| redis (brew) | `brew services restart redis` |
| Docker Desktop | `open -a Docker` |
| (add yours) | |

---

## Key Paths

```
~/                  — home (/Users/YOUR_USERNAME)
~/Documents/        — documents
~/Developer/        — code (convention)
/Applications/      — installed apps
/usr/local/         — Homebrew (Intel)
/opt/homebrew/      — Homebrew (Apple Silicon)
/Library/Logs/      — system logs
~/Library/Logs/     — user logs
```

---

## Behavior Rules

1. **Connect silently first** — run SSH check at skill load, before responding
2. **Always execute** — never just describe, always run the actual command
3. **Show real output** — paste results, not summaries
4. **Auto-retry** — if it fails, try an alternative approach
5. **macOS-aware** — prefer `brew`, `launchctl`, `open`, `osascript` over Linux equivalents

---

## Quick Reference

```bash
# Health
df -h && uptime && who
vm_stat | head -10                          # memory stats
top -l 1 -n 10 -o cpu                      # CPU top processes

# Homebrew services
brew services list
brew services restart SERVICE_NAME
brew update && brew upgrade

# Apps & processes
ps aux | grep APP_NAME
kill -9 PID
open -a "Application Name"
osascript -e 'tell app "Finder" to quit'   # AppleScript control

# Network
netstat -an | grep LISTEN
lsof -i :PORT
curl -s localhost:PORT/health

# Disk
du -sh ~/* | sort -rh | head -20
df -h

# Logs
log show --last 1h --predicate 'eventMessage contains "error"'
tail -f ~/Library/Logs/YOUR_APP/app.log
cat /var/log/system.log | tail -100

# Launchctl (system services)
launchctl list | grep -i SERVICE
launchctl stop com.example.service
launchctl start com.example.service

# Docker
docker ps
docker logs CONTAINER --tail=50
docker restart CONTAINER

# Screenshot (saves to Desktop)
screencapture -x ~/Desktop/screenshot.png
```
