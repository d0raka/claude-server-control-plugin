#!/bin/bash
# Claude Server Control Plugin - Installer
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/d0raka/claude-server-control-plugin/main/install.sh)

set -e

REPO_URL="https://github.com/d0raka/claude-server-control-plugin"
PLUGIN_NAME="server-control"
INSTALL_DIR="$HOME/claude-server-control-plugin"

# Always read from terminal even when piped
exec < /dev/tty

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║  Claude Server Control Plugin - Installer    ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# -- 1. Install git if missing ------------------------------------------------
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

# -- 2. Clone or update the plugin --------------------------------------------
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing install..."
    git -C "$INSTALL_DIR" pull -q
else
    echo "Downloading plugin..."
    git clone -q "$REPO_URL" "$INSTALL_DIR"
fi

# -- 3. Choose platform -------------------------------------------------------
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

# -- 4. Get credentials -------------------------------------------------------
echo ""
echo "Enter your $PLATFORM_NAME machine details:"
echo ""
read -p "  IP address (e.g. 100.64.0.5): " SERVER_IP
read -p "  SSH username (e.g. ubuntu):    " SSH_USER
read -s -p "  SSH password:                  " SSH_PASS
echo ""

# Escape special characters for sed (/, &, \)
escape_sed() { printf '%s' "$1" | sed 's/[\/&]/\\&/g'; }

SERVER_IP_ESC=$(escape_sed "$SERVER_IP")
SSH_USER_ESC=$(escape_sed "$SSH_USER")
SSH_PASS_ESC=$(escape_sed "$SSH_PASS")

# -- 5. Build plugin in a temp folder -----------------------------------------
TEMP_PLUGIN="$(mktemp -d)/server-control-plugin-build"
cp -r "$INSTALL_DIR" "$TEMP_PLUGIN"

# -- 6. Activate the right SKILL file -----------------------------------------
if [ "$SKILL_SRC" != "SKILL.md" ]; then
    [ -f "$TEMP_PLUGIN/skills/server-control/SKILL.md" ] && \
        mv "$TEMP_PLUGIN/skills/server-control/SKILL.md" \
           "$TEMP_PLUGIN/skills/server-control/SKILL-linux.md" 2>/dev/null || true
    cp "$TEMP_PLUGIN/skills/server-control/$SKILL_SRC" \
       "$TEMP_PLUGIN/skills/server-control/SKILL.md"
fi

# -- 7. Fill in credentials ---------------------------------------------------
ACTIVE_SKILL="$TEMP_PLUGIN/skills/server-control/SKILL.md"

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' \
        -e "s/YOUR_SERVER_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_MAC_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_WINDOWS_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_USERNAME/$SSH_USER_ESC/g" \
        -e "s/YOUR_PASSWORD/$SSH_PASS_ESC/g" \
        "$ACTIVE_SKILL"
else
    sed -i \
        -e "s/YOUR_SERVER_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_MAC_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_WINDOWS_IP/$SERVER_IP_ESC/g" \
        -e "s/YOUR_USERNAME/$SSH_USER_ESC/g" \
        -e "s/YOUR_PASSWORD/$SSH_PASS_ESC/g" \
        "$ACTIVE_SKILL"
fi

# -- 8. Package as .plugin file (zip) -----------------------------------------
echo ""
echo "Creating your personalized .plugin file..."

# Determine Desktop path
if [[ "$OSTYPE" == "darwin"* ]]; then
    DESKTOP="$HOME/Desktop"
else
    DESKTOP="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
    [ -d "$DESKTOP" ] || DESKTOP="$HOME"
fi

PLUGIN_FILE="$DESKTOP/server-control.plugin"

cd "$TEMP_PLUGIN"
zip -r -q "$PLUGIN_FILE" .
cd - > /dev/null

# Cleanup temp build
rm -rf "$(dirname "$TEMP_PLUGIN")"

# -- 9. Done ------------------------------------------------------------------
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║  Your plugin is ready!                       ║"
echo "╠═══════════════════════════════════════════════╣"
echo "║                                               ║"
echo "║  File saved to your Desktop:                 ║"
echo "║    server-control.plugin                     ║"
echo "║                                               ║"
echo "║  To activate:                                ║"
echo "║  Open Claude Cowork ->                       ║"
echo "║  Customize -> Upload plugin                  ║"
echo "║  Select: server-control.plugin               ║"
echo "║                                               ║"
printf "║  Claude will connect to your %-15s ║\n" "$PLATFORM_NAME machine."
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
