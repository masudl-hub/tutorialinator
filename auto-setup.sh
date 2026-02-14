#!/bin/bash
#
# Tutorialinator Auto-Setup Script
# This script is called when the /tutorialinator skill is invoked
# It ensures everything is installed and configured before proceeding
#

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_DIR="$SKILL_DIR/mcp-server"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Tutorialinator Auto-Setup                        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ──────────────────────────────────────────────
# Step 1: Video tutorial MCP server (Python venv)
# ──────────────────────────────────────────────
echo -e "${CYAN}→${NC} Checking video tools installation..."
NEEDS_INSTALL=0

if [ ! -d "$MCP_DIR/venv" ]; then
    echo -e "${YELLOW}⚠${NC}  Virtual environment not found"
    NEEDS_INSTALL=1
elif [ ! -f "$MCP_DIR/venv/bin/python" ]; then
    echo -e "${YELLOW}⚠${NC}  Python not found in venv"
    NEEDS_INSTALL=1
elif ! "$MCP_DIR/venv/bin/python" -c "import mcp; import whisper; import fastmcp" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC}  Dependencies not installed or broken"
    NEEDS_INSTALL=1
fi

if [ $NEEDS_INSTALL -eq 1 ]; then
    echo -e "${CYAN}→${NC} Running video tools installation..."
    echo ""
    cd "$MCP_DIR"
    ./install.sh
    if [ $? -ne 0 ]; then
        echo ""
        echo -e "${RED}✗${NC} Video tools installation failed!"
        exit 1
    fi
    echo ""
fi

echo -e "${GREEN}✓${NC} Video tools verified"
echo ""

# ──────────────────────────────────────────────
# Step 2: Playwright MCP (browser validation)
# ──────────────────────────────────────────────
echo -e "${CYAN}→${NC} Checking Playwright browser validation..."

# Check if npx is available
if ! command -v npx &>/dev/null; then
    echo -e "${RED}✗${NC} npx not found! Install Node.js first."
    exit 1
fi

# Pre-cache the Playwright MCP package
if npx --yes @playwright/mcp@latest --version &>/dev/null; then
    echo -e "${GREEN}✓${NC} Playwright MCP package available"
else
    echo -e "${CYAN}→${NC} Installing Playwright MCP..."
    npx --yes @playwright/mcp@latest --version
fi

# Check if Chromium browser is installed
if [ -d "$HOME/Library/Caches/ms-playwright" ] && ls "$HOME/Library/Caches/ms-playwright/" | grep -q "chromium"; then
    echo -e "${GREEN}✓${NC} Chromium browser installed"
else
    echo -e "${CYAN}→${NC} Installing Chromium browser for validation..."
    # Create a temp project to run playwright install
    TMPDIR=$(mktemp -d)
    (
        cd "$TMPDIR"
        npm init -y > /dev/null 2>&1
        npm install @playwright/test > /dev/null 2>&1
        npx playwright install chromium 2>&1
    )
    rm -rf "$TMPDIR"
    if [ -d "$HOME/Library/Caches/ms-playwright" ] && ls "$HOME/Library/Caches/ms-playwright/" | grep -q "chromium"; then
        echo -e "${GREEN}✓${NC} Chromium browser installed"
    else
        echo -e "${YELLOW}⚠${NC}  Chromium install may have failed — Playwright validation will use fallback"
    fi
fi

echo ""

# ──────────────────────────────────────────────
# Step 3: MCP configuration
# ──────────────────────────────────────────────
echo -e "${CYAN}→${NC} Checking MCP configuration..."

# Always write the canonical .mcp.json with both servers
cat > "$SKILL_DIR/.mcp.json" <<EOF
{
  "mcpServers": {
    "tutorialinator": {
      "command": "$MCP_DIR/venv/bin/python",
      "args": [
        "-m",
        "mcp_video_tutorial.server"
      ],
      "cwd": "$MCP_DIR"
    },
    "playwright": {
      "command": "npx",
      "args": [
        "--yes",
        "@playwright/mcp@latest",
        "--headless",
        "--allow-unrestricted-file-access"
      ]
    }
  }
}
EOF

# Verify both servers are in the config
if grep -q '"tutorialinator"' "$SKILL_DIR/.mcp.json" && grep -q '"playwright"' "$SKILL_DIR/.mcp.json"; then
    echo -e "${GREEN}✓${NC} MCP configuration verified (video-tutorial + playwright)"
else
    echo -e "${RED}✗${NC} MCP configuration write failed!"
    exit 1
fi

# Check if enableAllProjectMcpServers is enabled
if ! grep -q '"enableAllProjectMcpServers": true' ~/.claude/settings.json 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC}  Note: 'enableAllProjectMcpServers' is not enabled in settings.json"
    echo "   The MCP servers may not load automatically"
fi

echo ""

# ──────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║              TUTORIALINATOR READY!                       ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Setup complete! Proceeding with tutorialinator...${NC}"
echo ""

exit 0
