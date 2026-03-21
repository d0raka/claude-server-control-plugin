#!/bin/bash
# Claude Server Control Plugin — macOS Setup
# Run this on your MAC (the machine you want Claude to control)

set -e

echo "╔══════════════════════════════════════════╗"
echo "║  Claude Server Control — macOS Setup     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Enable SSH (Remote Login)
echo "→ Checking SSH (Remote Login)..."
SSH_STATUS=$(sudo systemsetup -getremotelogin 2>/dev/null | awk '{print $NF}')
if [ "$SSH_STATUS" != "On" ]; then
    echo "  Enabling Remote Login..."
    sudo systemsetup -setremotelogin on
    echo "  ✓ Remote Login enabled"
else
    echo "  ✓ Remote Login already enabled"
fi

# 2. Install Tailscale if not present
echo ""
echo "→ Checking Tailscale..."
if ! command -v tailscale &> /dev/null; then
    echo "  Tailscale not found."
    echo "  Install it from: https://tailscale.com/download/mac"
    echo "  Or via Homebrew: brew install --cask tailscale"
else
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "not connected — open Tailscale app to connect")
    echo "  ✓ Tailscale IP: $TAILSCALE_IP"
fi

# 3. Check Homebrew
echo ""
echo "→ Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "  Homebrew not found."
    echo "  Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
else
    echo "  ✓ Homebrew installed: $(brew --version | head -1)"
fi

# 4. Print Mac details
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Paste these into your SKILL-mac.md:     ║"
echo "╠══════════════════════════════════════════╣"
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || ipconfig getifaddr en0 2>/dev/null || "unknown")
printf "║  YOUR_MAC_IP    = %-22s║\n" "$TAILSCALE_IP"
printf "║  YOUR_USERNAME  = %-22s║\n" "$(whoami)"
printf "║  OS             = %-22s║\n" "$(sw_vers -productVersion)"
echo "╠══════════════════════════════════════════╣"
echo "║  Skill to use: SKILL-mac.md              ║"
echo "║  → Rename it to SKILL.md to activate     ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next: Edit skills/server-control/SKILL-mac.md with your details"
echo "      Rename SKILL-mac.md → SKILL.md (and rename SKILL.md → SKILL-linux.md)"
echo "Then: Load the plugin in Claude Cowork → Settings → Plugins"
