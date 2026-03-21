#!/bin/bash
# Claude Server Control Plugin - Linux Setup
# Run this on your LINUX SERVER (not your computer)

set -e

echo "╔══════════════════════════════════════════╗"
echo "║  Claude Server Control - Linux Setup     ║"
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
    echo "  ✓ Tailscale installed. Connect it with:"
    echo "    sudo tailscale up"
else
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "not connected - run: sudo tailscale up")
    echo "  ✓ Tailscale IP: $TAILSCALE_IP"
fi

# 3. Print server details
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Paste these into your SKILL.md:         ║"
echo "╠══════════════════════════════════════════╣"
printf "║  YOUR_SERVER_IP  = %-22s║\n" "$(tailscale ip -4 2>/dev/null || hostname -I | awk '{print $1}')"
printf "║  YOUR_USERNAME   = %-22s║\n" "$(whoami)"
printf "║  OS              = %-22s║\n" "$(lsb_release -ds 2>/dev/null || uname -s)"
echo "╠══════════════════════════════════════════╣"
echo "║  Skill to use: SKILL.md (Linux)          ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next: Edit skills/server-control/SKILL.md with your details"
echo "Then: Load the plugin in Claude Cowork → Settings → Plugins"
