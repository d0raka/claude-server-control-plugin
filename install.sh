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

# ── 1. Install git if missing ────────────────────────────────────────────────
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

# ── 2. Clone or update the plugin ───────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing install..."
    git -C "$INSTALL_DIR" pull -q
else
    echo "Downloading plugin..."
    git clone -q "$REPO_URL" "$INSTALL_DIR"
fi

# ── 3. Choose platform ──────────────────────────────────────────────────────
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

# ── 4. Get credentials ──────────────────────────────────────────────────────
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

# ── 5. Activate the right SKILL file ────────────────────────────────────────
if [ "$SKILL_SRC" != "SKILL.md" ]; then
    [ -f "$SKILLS_DIR/SKILL.md" ] && mv "$SKILLS_DIR/SKILL.md" "$SKILLS_DIR/SKILL-linux.md" 2>/dev/null || true
    cp "$SKILLS_DIR/$SKILL_SRC" "$SKILLS_DIR/SKILL.md"
fi

# ── 6. Fill in credentials ──────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
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

# ── 7. Auto-register in Claude Cowork ───────────────────────────────────────
echo ""
echo "Registering plugin in Claude Cowork..."

# Find Claude data directory
find_claude_dir() {
    local candidates=(
        "$HOME/Library/Application Support/Claude/local-agent-mode-sessions"  # macOS
        "$HOME/.config/Claude/local-agent-mode-sessions"                       # Linux
    )
    for candidate in "${candidates[@]}"; do
        if [ -d "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

REGISTERED=false

if CLAUDE_SESSIONS=$(find_claude_dir 2>/dev/null); then
    # Find the most recent session with an installed_plugins.json
    PLUGINS_JSON=$(find "$CLAUDE_SESSIONS" -name "installed_plugins.json" -type f 2>/dev/null \
        | xargs ls -t 2>/dev/null | head -1)

    if [ -n "$PLUGINS_JSON" ]; then
        MARKETPLACE_DIR="$(dirname "$PLUGINS_JSON")/marketplaces/local-desktop-app-uploads"
        PLUGIN_DEST="$MARKETPLACE_DIR/$PLUGIN_NAME"

        # Copy plugin to Claude's marketplace folder
        mkdir -p "$MARKETPLACE_DIR"
        rm -rf "$PLUGIN_DEST"
        cp -r "$INSTALL_DIR" "$PLUGIN_DEST"

        NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

        # Update installed_plugins.json using python3
        python3 - "$PLUGINS_JSON" "$PLUGIN_NAME" "$PLUGIN_DEST" "$NOW" << 'PYEOF'
import json, sys

plugins_path = sys.argv[1]
plugin_name  = sys.argv[2]
plugin_dest  = sys.argv[3]
now          = sys.argv[4]
plugin_key   = f"{plugin_name}@local-desktop-app-uploads"

with open(plugins_path, 'r') as f:
    data = json.load(f)

data.setdefault('plugins', {})[plugin_key] = [{
    "scope":       "user",
    "installPath": plugin_dest,
    "version":     "2.0.0",
    "installedAt": now,
    "lastUpdated": now
}]

with open(plugins_path, 'w') as f:
    json.dump(data, f, indent=2)

print("ok")
PYEOF

        if [ $? -eq 0 ]; then
            REGISTERED=true
            echo "  Plugin registered successfully."
        fi
    fi
fi

# ── 8. Done ──────────────────────────────────────────────────────────────────
echo ""
if $REGISTERED; then
    echo "╔═══════════════════════════════════════════════╗"
    echo "║  All done!                                   ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo "║                                               ║"
    echo "║  The plugin was installed automatically.      ║"
    echo "║  Just restart Claude Cowork and start         ║"
    echo "║  a new chat - Claude will connect to your     ║"
    echo "║  $PLATFORM_NAME machine automatically.               ║"
    echo "║                                               ║"
    echo "╚═══════════════════════════════════════════════╝"
else
    echo "╔═══════════════════════════════════════════════╗"
    echo "║  One manual step needed:                     ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo "║                                               ║"
    echo "║  Open Claude Cowork:                         ║"
    echo "║  Settings -> Plugins -> Load local plugin    ║"
    echo "║                                               ║"
    printf "║  Select: %-38s║\n" "$INSTALL_DIR"
    echo "║                                               ║"
    echo "╚═══════════════════════════════════════════════╝"

    # Open the folder for easy drag-and-drop
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$INSTALL_DIR"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$INSTALL_DIR" 2>/dev/null &
    fi
fi
echo ""
