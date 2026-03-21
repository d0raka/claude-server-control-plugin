# Claude Server Control Plugin

Control any computer remotely from Claude - **Linux, macOS, or Windows** - using natural conversation.

Run commands, manage services, deploy code, monitor health, edit files - all through Claude, without touching a terminal yourself.

---

## Install in 2 steps

### Step 1 - Run the installer on your computer (where Claude is)

**Linux or macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/d0raka/claude-server-control-plugin/main/install.sh | bash
```

**Windows** (PowerShell):
```powershell
irm https://raw.githubusercontent.com/d0raka/claude-server-control-plugin/main/install.ps1 | iex
```

The installer asks which platform you want to control (Linux / Mac / Windows), then asks for the IP, username, and password. It fills everything in automatically.

### Step 2 - Load the plugin in Claude Cowork

1. Open Claude Cowork
2. Go to **Settings -> Plugins -> Load local plugin**
3. Select the `claude-server-control-plugin` folder (saved to your home directory)
4. Start a new chat - Claude connects to your machine automatically

That's it.

---

## Supported platforms

| Platform | SKILL file |
|----------|-----------|
| Linux (Ubuntu, Debian, Arch...) | `SKILL.md` |
| macOS | `SKILL-mac.md` |
| Windows 10/11 / Server | `SKILL-windows.md` |

---

## How it works

Claude connects to your machine via **SSH** using Python's `paramiko` library, which runs inside Claude's secure sandbox. No agents running in the background - Claude SSHes in and runs commands only when you ask.

```
Your Computer (Claude Cowork)
        |
        |  SSH over Tailscale VPN
        v
Your Remote Machine (Linux / Mac / Windows)
```

**Tailscale** is used for networking - it gives your machine a stable private IP that works from anywhere, without exposing ports to the internet.

---

## Requirements

- A machine you want to control (Linux, macOS, or Windows)
- SSH enabled on that machine
- [Tailscale](https://tailscale.com) on both machines (recommended)
- [Claude Cowork](https://claude.ai) desktop app

---

## Set up the remote machine

If SSH or Tailscale aren't set up yet on the machine you want to control, run the matching script on that machine:

**Linux:**
```bash
bash setup/setup-linux.sh
```

**macOS:**
```bash
bash setup/setup-mac.sh
```

**Windows** (PowerShell as Administrator):
```powershell
.\setup\setup-windows.ps1
```

Each script installs SSH, sets up Tailscale, and prints the exact IP and username you need for the installer.

---

## Tailscale setup

Tailscale creates a private VPN between your devices - no port forwarding, no exposed IPs.

On your remote machine (Linux):
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
tailscale ip -4   # use this IP in the installer
```

macOS / Windows: Download from [tailscale.com/download](https://tailscale.com/download)

On your own computer: same - install Tailscale and sign in with the same account.

---

## Example conversations

> "What's the CPU and memory usage?"

> "Restart nginx"

> "Show me the last 50 lines of the app log"

> "Is the database running?"

> "Deploy the latest version from git"

> "What docker containers are running?"

> "Find all files larger than 1GB"

> "What's in the Windows Event Log - any errors in the last hour?"

---

## Security

This plugin gives Claude SSH access to your machine. A few things to keep in mind:

- **Use Tailscale** - don't expose port 22 to the public internet
- **Use SSH key auth** instead of passwords for better security:
  ```bash
  ssh-keygen -t ed25519 -C "claude-plugin"
  ssh-copy-id user@YOUR_IP
  ```
  Then edit `SKILL.md` and replace the password line with `key_filename='/path/to/key'`
- **Keep the plugin folder private** - it contains your credentials after install
- **Never push your filled-in SKILL.md** to a public repo

---

## File structure

```
claude-server-control-plugin/
├── install.sh                    # Linux/Mac one-liner installer
├── install.ps1                   # Windows one-liner installer
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── server-control/
│       ├── SKILL.md              # Active skill (filled in by installer)
│       ├── SKILL-mac.md          # macOS version
│       └── SKILL-windows.md      # Windows version
├── setup/
│   ├── setup-linux.sh            # Run on the remote Linux machine
│   ├── setup-mac.sh              # Run on the remote Mac
│   └── setup-windows.ps1         # Run on the remote Windows machine (as Admin)
├── .mcp.json
├── .gitignore
└── README.md
```

---

## Troubleshooting

**Can't connect:**
- Is Tailscale running on both machines? Run `tailscale status`
- Is SSH running? Linux: `systemctl status ssh` / Mac: System Settings -> Sharing -> Remote Login / Windows: `Get-Service sshd`
- Test manually from your terminal: `ssh YOUR_USERNAME@YOUR_IP`

**Wrong credentials after install:**
- Re-run the installer - it updates SKILL.md for you
- Or edit `skills/server-control/SKILL.md` directly

**Windows: Claude is using CMD instead of PowerShell:**
- Re-run `setup/setup-windows.ps1` as Administrator

---

## License

MIT - fork it, adapt it, make it yours.
