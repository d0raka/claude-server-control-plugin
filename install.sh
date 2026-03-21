#!/bin/bash
# Claude Server Control Plugin - Installer
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/d0raka/claude-server-control-plugin/main/install.sh)

set -e

REPO_URL="https://github.com/d0raka/claude-server-control-plugin"
INSTALL_DIR="$HOME/claude-server-control-plugin"

# Always read from terminal even when piped
exec < /dev/tty

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║  Claude Server Control Plugin - Installer    ║"
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
        echo "Error: please install git manually and re-run."
        exit 1
    fi
fi

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing install..."
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
    2) SKILL_SRC="SKILL-mac.md";     PLATFORM_NAME="macOS"   ;;
    3) SKILL_SRC="SKILL-windows.md"; PLATFORM_NAME="Windows" ;;
    *) SKILL_SRC="SKILL.md";         PLATFORM_NAME="Linux"   ;;
esac

SKILLS_DIR="$INSTALL_DIR/skills/server-control"

echo ""
echo "Enter your $PLATFORM_NAME machine details:"
echo ""
read -p "  IP address (e.g. 100.64.0.5): " SERVER_IP
read -p "  SSH username (e.g. ubuntu):    " SSH_USER
read -s -p "  SSH password:                  " SSH_PASS
echo ""

# Escape special characters for sed (handles /, &, \, newlines)
escape_sed() {
    printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

SERVER_IP_ESC=$(escape_sed "$SERVER_IP")
SSH_USER_ESC=$(escape_sed "$SSH_USER")
SSH_PASS_ESC=$(escape_sed "$SSH_PASS")

# Activate the right SKILL file
if [ "$SKILL_SRC" != "SKILL.md" ]; then
    if [ -f "$SKILLS_DIR/SKILL.md" ]; then
        mv "$SKILLS_DIR/SKILL.md" "$SKILLS_DIR/SKILL-linux.md" 2>/dev/null || true
    fi
    cp "$SKILLS_DIR/$SKILL_SRC" "$SKILLS_DIR/SKILL.md"
fi

# Fill in credentials
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed needs empty string for in-place edit
    sed -i '' \
        -e "s/YOUR_SERVER_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_MAC_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_WINDOWS_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_USERNAME/$SSH_USER_ESC/g" \
        -e "s/YOUR_PASSWORD/$SSH_PASS_ESC/g" \
        "$SKILLS_DIR/SKILL.md"
else
    sed -i \
        -e "s/YOUR_SERVER_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_MAC_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_WINDOWS_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_USERNAME/$SSH_USER_ESC/g" \
        -e "s/YOUR_PASSWORD/$SSH_PASS_ESC/g" \
        "$SKILLS_DIR/SKILL.md"
fi

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║  Done! One step left:                        ║"
echo "╠═══════════════════════════════════════════════╣"
echo "║                                               ║"
echo "║  Open Claude Cowork and go to:               ║"
echo "║  Settings -> Plugins -> Load local plugin    ║"
echo "║                                               ║"
echo "║  Select this folder:                         ║"
printf "║  %-46s║\n" "$INSTALL_DIR"
echo "║                                               ║"
echo "║  Start a new chat - Claude will connect       ║"
echo "║  to your $PLATFORM_NAME machine automatically.       ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Open the folder
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$INSTALL_DIR"
elif command -v xdg-open &> /dev/null; then
    xdg-open "$INSTALL_DIR" 2>/dev/null &
fi
