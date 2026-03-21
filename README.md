# 🖥️ Claude Server Control Plugin

Control any computer remotely from Claude — **Linux, macOS, or Windows** — using natural conversation.

Run commands, manage services, deploy code, monitor health, edit files — all through Claude, without touching a terminal yourself.

Built with [Claude Cowork](https://claude.ai) + SSH via `paramiko`.

---

## Supported Platforms

| Platform | SKILL file | Setup script |
|----------|-----------|--------------|
| 🐧 Linux (Ubuntu, Debian, Arch…) | `SKILL.md` | `setup/setup-linux.sh` |
| 🍎 macOS | `SKILL-mac.md` | `setup/setup-mac.sh` |
| 🪟 Windows 10/11 / Server | `SKILL-windows.md` | `setup/setup-windows.ps1` |

---

## How it works

Claude connects to your machine via **SSH** using Python's `paramiko` library, which runs inside Claude's secure sandbox. No agents running in the background — Claude SSHes in and runs commands only when you ask.

```
Your Computer (Claude Cowork)
        │
        │  SSH over Tailscale VPN
        ▼
Your Remote Machine (Linux / Mac / Windows)
```

**Tailscale** is used for networking — it gives your machine a stable private IP that works from anywhere, without exposing ports to the internet.

---

## Requirements

- A machine you want to control (Linux, macOS, or Windows)
- SSH enabled on that machine
- [Tailscale](https://tailscale.com) on both machines (recommended)
- [Claude Cowork](https://claude.ai) desktop app

---

## Quick Start

### Step 1 — Run the setup script on your remote machine

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

The script will install SSH, set up Tailscale, and print your connection details.

---

### Step 2 — Activate the right SKILL file

Only one `SKILL.md` can be active at a time. Rename the file for your platform:

**Linux** — already active by default (`SKILL.md`)

**macOS:**
```bash
mv skills/server-control/SKILL.md skills/server-control/SKILL-linux.md
mv skills/server-control/SKILL-mac.md skills/server-control/SKILL.md
```

**Windows:**
```bash
mv skills/server-control/SKILL.md skills/server-control/SKILL-linux.md
mv skills/server-control/SKILL-windows.md skills/server-control/SKILL.md
```

---

### Step 3 — Edit SKILL.md with your details

Open `skills/server-control/SKILL.md` and fill in:

| Placeholder | Replace with |
|------------|--------------|
| `YOUR_SERVER_IP` / `YOUR_MAC_IP` / `YOUR_WINDOWS_IP` | Your Tailscale IP (e.g. `100.64.0.5`) |
| `YOUR_USERNAME` | SSH username |
| `YOUR_PASSWORD` | SSH password |

Also customize:
- **My Services** table → list your running services
- **Key Paths** → where your projects live
- **tmux Sessions** (Linux/Mac) → your background sessions

---

### Step 4 — Load the plugin in Claude Cowork

1. Open Claude Cowork
2. Go to **Settings → Plugins → Load local plugin**
3. Select the `claude-server-control-plugin` folder
4. Start a new chat — Claude connects automatically

---

## Example Conversations

> "What's the CPU and memory usage?"

> "Restart the nginx service"

> "Show me the last 50 lines of the app log"

> "Is the database running?"

> "Deploy the latest version from git"

> "What docker containers are running?"

> "Find all files larger than 1GB on the disk"

> "What's in the Windows Event Log — any errors in the last hour?"

---

## Tailscale Setup (recommended)

Tailscale creates a private VPN between your devices — no port forwarding, no exposed IPs.

**On your remote machine:**

Linux:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
tailscale ip -4   # ← use this as YOUR_SERVER_IP
```

macOS / Windows: Download from [tailscale.com/download](https://tailscale.com/download)

**On your computer (where Claude runs):** Same — install Tailscale and sign in with the same account.

---

## Security

⚠️ This plugin gives Claude full SSH access to your machine. Use it responsibly.

**Best practices:**
- Use Tailscale — don't expose port 22 to the internet
- Use SSH key authentication instead of passwords:
  ```bash
  ssh-keygen -t ed25519 -C "claude-plugin"
  ssh-copy-id user@YOUR_IP
  ```
  Then in SKILL.md, replace the password parameter with `key_filename='/path/to/key'`
- Create a dedicated user with limited permissions instead of using root/admin
- **Never push a SKILL.md with real credentials to a public repo**

**Add to .gitignore if you fork this:**
```
skills/server-control/SKILL.md
.mcp.json
```

---

## File Structure

```
claude-server-control-plugin/
├── .claude-plugin/
│   └── plugin.json               # Plugin metadata
├── skills/
│   └── server-control/
│       ├── SKILL.md              # ← ACTIVE skill (edit this)
│       ├── SKILL-mac.md          # macOS version
│       └── SKILL-windows.md      # Windows version
├── setup/
│   ├── setup-linux.sh            # Linux setup script
│   ├── setup-mac.sh              # macOS setup script
│   └── setup-windows.ps1         # Windows setup (run as Admin)
├── .mcp.json                     # Optional: MCP server connection
├── .gitignore
└── README.md
```

---

## Optional: MCP Server

If you run an MCP-compatible server on your machine, you can also connect via `.mcp.json` for additional tool access. Edit the file with your IP and port:

```json
{
  "mcpServers": {
    "my-server": {
      "type": "sse",
      "url": "http://YOUR_IP:YOUR_MCP_PORT/sse"
    }
  }
}
```

---

## Troubleshooting

**Can't connect:**
- Tailscale running on both machines? → `tailscale status`
- SSH service running? → Linux: `systemctl status ssh` / Mac: check System Settings → Sharing / Windows: `Get-Service sshd`
- Test manually: `ssh YOUR_USERNAME@YOUR_IP`
- Wrong username? On Windows it's case-sensitive and must match exactly

**paramiko install fails:**
- The SKILL.md handles this automatically with `--break-system-packages`

**Windows: shell is CMD instead of PowerShell:**
- Re-run `setup-windows.ps1` as Administrator — it sets PowerShell as default

**Permission denied:**
- Double-check username and password in SKILL.md
- On Linux/Mac, confirm the user has SSH access

---

## Credits

Originally built for a home Linux server + Claude Cowork setup. Open-sourced so anyone can connect Claude to their own machine.

---

## License

MIT — fork it, adapt it, make it yours.
