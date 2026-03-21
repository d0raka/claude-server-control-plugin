---
name: server-control
description: >
  Gives Claude full control over a remote Linux machine via SSH. Use when the user asks to
  run commands, check server status, manage services, edit files, control Docker,
  restart services, view logs, or do anything else on the remote machine.
  Trigger phrases: "run on server", "check the server", "restart", "deploy",
  "server status", "what's running", "fix it", "edit file on server".
---

# Server Control - Linux via SSH

> **Other platforms:** See `SKILL-mac.md` for macOS, `SKILL-windows.md` for Windows.
> To activate a different platform, rename its file to `SKILL.md`.

---

## ⚙️ SETUP - Fill in your details

| Placeholder | Replace with |
|------------|--------------|
| `YOUR_SERVER_IP` | Tailscale IP recommended (e.g. `100.64.0.5`) |
| `YOUR_USERNAME` | SSH user (e.g. `ubuntu`, `pi`, `myuser`) |
| `YOUR_PASSWORD` | SSH password - or use key auth below |

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
client.connect('YOUR_SERVER_IP', username='YOUR_USERNAME', password='YOUR_PASSWORD', timeout=10)
stdin, stdout, _ = client.exec_command('echo "connected: $(hostname) | $(date)"')
print(stdout.read().decode())
client.close()
```

✅ Success → continue normally.
❌ Failure → tell user: "Can't connect. Check that Tailscale is running and the server is online."

---

## SSH Details

```
Host     : YOUR_SERVER_IP
User     : YOUR_USERNAME
Password : YOUR_PASSWORD
Port     : 22
```

**Key-based auth (more secure):**
```python
client.connect('YOUR_SERVER_IP', username='YOUR_USERNAME',
               key_filename='/path/to/private_key', timeout=10)
```

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
print(run('docker ps'))
print(run('systemctl status nginx'))
```

---

## Server Info

```
OS   : Ubuntu / Debian / Arch / (fill in)
IP   : YOUR_SERVER_IP
User : YOUR_USERNAME
CPU  : ...
RAM  : ...
```

---

## My Services

> Edit this table

| Service | Port | Restart command |
|---------|------|-----------------|
| Nginx | 80 | `systemctl restart nginx` |
| PostgreSQL | 5432 | `systemctl restart postgresql` |
| Redis | 6379 | `systemctl restart redis` |
| Docker | - | `systemctl restart docker` |
| (add yours) | | |

---

## tmux Sessions

```bash
tmux list-sessions
tmux new-session -d -s myapp "cd ~/myapp && python3 app.py"
tmux kill-session -t myapp
```

---

## Key Paths

```
~/           - home
~/projects/  - code
~/logs/      - logs
```

---

## Behavior Rules

1. **Connect silently first** - run SSH check at skill load, before responding
2. **Always execute** - never just describe, always run the actual command
3. **Show real output** - paste results, not summaries
4. **Auto-retry** - if it fails, try an alternative approach
5. **Full access** - docker, systemctl, files, all services - just do it

---

## Quick Reference

```bash
# Health
free -h && df -h && uptime && who

# Services
systemctl list-units --type=service --state=running
systemctl restart SERVICE_NAME
journalctl -u SERVICE_NAME -n 50 --no-pager

# Docker
docker ps
docker logs CONTAINER --tail=50
docker restart CONTAINER

# Network
ss -tlnp
curl -s localhost:PORT/health

# Disk
du -sh /* 2>/dev/null | sort -rh | head -20
find / -size +500M -type f 2>/dev/null

# Process
ps aux --sort=-%cpu | head -10
top -bn1 | head -20

# Logs
tail -f /var/log/syslog
journalctl -n 100 --no-pager
```
