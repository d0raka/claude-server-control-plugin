#!/bin/bash
# Claude Server Control Plugin - Installer
# Run this on your computer (the one with Claude Cowork)
# Usage: curl -fsSL https://raw.githubusercontent.com/d0raka/claude-server-control-plugin/main/install.sh | bash

set -e

REPO_URL="https://github.com/d0raka/claude-server-control-plugin"
INSTALL_DIR="$HOME/claude-server-control-plugin"

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║   Claude Server Control Plugin - Installer   ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Check for git
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y git -qq
    elif command -v brew &> /dev/null; then
        brew install git
    else
        echo "Error: please install git manually and re-run this script."
        exit 1
    fi
fi

# Clone the repo
if [ -d "$INSTALL_DIR" ]; then
    echo "Found existing install at $INSTALL_DIR - updating..."
    git -C "$INSTALL_DIR" pull -q
else
    echo "Downloading plugin..."
    git clone -q "$REPO_URL" "$INSTALL_DIR"
fi

echo ""
echo "Which machine do you want to control?"
echo "  1) Linux (Ubuntu, Debian, Raspberry Pi, etc.)"
echo "  2) macOS"
echo "  3) Windows"
echo ""
read -p "Enter 1, 2 or 3: " PLATFORM

case $PLATFORM in
    1)
        SKILL_SRC="SKILL.md"
        PLATFORM_NAME="Linux"
        ;;
    2)
        SKILL_SRC="SKILL-mac.md"
        PLATFORM_NAME="macOS"
        ;;
    3)
        SKILL_SRC="SKILL-windows.md"
        PLATFORM_NAME="Windows"
        ;;
    *)
        echo "Invalid choice. Defaulting to Linux."
        SKILL_SRC="SKILL.md"
        PLATFORM_NAME="Linux"
        ;;
esac

SKILLS_DIR="$INSTALL_DIR/skills/server-control"

echo ""
echo "Enter your $PLATFORM_NAME machine details:"
echo "(These will be saved into the plugin - keep this folder private)"
echo ""
read -p "  IP address (e.g. 100.64.0.5):  " SERVER_IP
read -p "  SSH username (e.g. ubuntu):     " SSH_USER
read -s -p "  SSH password:                   " SSH_PASS
echo ""

# Activate the right SKILL file
if [ "$SKILL_SRC" != "SKILL.md" ]; then
    # Back up current SKILL.md if it exists and isn't already a backup
    if [ -f "$SKILLS_DIR/SKILL.md" ]; then
        CURRENT_PLATFORM=$(head -5 "$SKILLS_DIR/SKILL.md" | grep -i "Linux\|macOS\|Windows" | head -1 | awk '{print $NF}' || echo "linux")
        mv "$SKILLS_DIR/SKILL.md" "$SKILLS_DIR/SKILL-backup.md" 2>/dev/null || true
    fi
    cp "$SKILLS_DIR/$SKILL_SRC" "$SKILLS_DIR/SKILL.md"
fi

# Fill in the credentials using sed
sed -i.bak \
    -e "s|YOUR_SERVER_IP|$SERVER_IP|g" \
    -e "s|YOUR_MAC_IP|$SERVER_IP|g" \
    -e "s|YOUR_WINDOWS_IP|$SERVER_IP|g" \
    -e "s|YOUR_USERNAME|$SSH_USER|g" \
    -e "s|YOUR_PASSWORD|$SSH_PASS|g" \
    "$SKILLS_DIR/SKILL.md"

rm -f "$SKILLS_DIR/SKILL.md.bak"

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║   Done! One step left:                       ║"
echo "╠═══════════════════════════════════════════════╣"
echo "║                                               ║"
echo "║   Open Claude Cowork and:                    ║"
echo "║   Settings -> Plugins -> Load local plugin   ║"
echo "║                                               ║"
printf "║   Select this folder:                        ║\n"
echo "║   $INSTALL_DIR"
echo "║                                               ║"
echo "║   Then start a new chat - Claude will         ║"
echo "║   connect to your $PLATFORM_NAME machine automatically. ║"
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo "Tip: To open the folder now, run:"
echo "  open $INSTALL_DIR"    # macOS
echo "  xdg-open $INSTALL_DIR" # Linux
echo ""
