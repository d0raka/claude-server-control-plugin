#!/bin/bash
# Claude Linux Server Plugin — Quick Setup
# Run this on your LINUX SERVER (not your computer)

set -e

echo "╔══════════════════════════════════════════╗"
echo "║  Claude Linux Server Plugin — Setup      ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Install SSH server if not present
echo "→ Checking SSH..."
if ! systemctl is-active --quiet ssh 2>/dev/null && ! systemctl is-active --quiet sshd 2>/dev/null; then
    echo "  Installing openssh-server..."
    sudo apt-get update -qq && sudo apt-get install -y openssh-server
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo "  ✓ SSH installed and started"
else
    echo "  ✓ SSH already running"
fi

# 2. Install Tailscale if not present
echo ""
echo "→ Checking Tailscale..."
if ! command -v tailscale &> /dev/null; then
    echo "  Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo ""
    echo "  ✓ Tailscale installed. Now connect it:"
    echo "    sudo tailscale up"
    echo ""
    echo "  After running tailscale up, get your IP with:"
    echo "    tailscale ip -4"
else
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "not connected")
    echo "  ✓ Tailscale installed — IP: $TAILSCALE_IP"
fi

# 3. Show current user and IP info
echo ""
echo "→ Your server details:"
echo "  Username : $(whoami)"
echo "  Hostname : $(hostname)"
echo "  Local IP : $(hostname -I | awk '{print $1}')"
if command -v tailscale &> /dev/null; then
    echo "  Tailscale: $(tailscale ip -4 2>/dev/null || echo 'not connected — run: sudo tailscale up')"
fi

# 4. Remind to edit SKILL.md
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Next steps:                             ║"
echo "╠══════════════════════════════════════════╣"
echo "║  1. Edit skills/server-control/SKILL.md  ║"
echo "║     with the details shown above         ║"
echo "║                                          ║"
echo "║  2. Load the plugin in Claude Cowork:    ║"
echo "║     Settings → Plugins → Load local      ║"
echo "║                                          ║"
echo "║  3. Start a new chat and ask Claude      ║"
echo "║     to check your server status!         ║"
echo "╚══════════════════════════════════════════╝"
echo ""
