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
    echo -e "${CYAN}→${NC} Rebuilding video tools environment..."
    echo ""

    # Find Python 3.10+
    PYTHON_CMD=""
    for cmd in python3.14 python3.13 python3.12 python3.11 python3.10 python3; do
        if command -v "$cmd" &>/dev/null; then
            ver=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
            major=$(echo "$ver" | cut -d. -f1)
            minor=$(echo "$ver" | cut -d. -f2)
            if [ "$major" -ge 3 ] && [ "$minor" -ge 10 ]; then
                PYTHON_CMD="$cmd"
                break
            fi
        fi
    done

    if [ -z "$PYTHON_CMD" ]; then
        echo -e "${RED}✗${NC} Python 3.10+ not found. Please install Python first:"
        echo "   macOS:  brew install python@3.12"
        echo "   Linux:  sudo apt install python3.12 python3.12-venv"
        exit 1
    fi

    # Remove broken venv if it exists
    [ -d "$MCP_DIR/venv" ] && rm -rf "$MCP_DIR/venv"

    # Create fresh venv and install
    echo -e "${CYAN}→${NC} Creating virtual environment with $PYTHON_CMD..."
    "$PYTHON_CMD" -m venv "$MCP_DIR/venv"
    "$MCP_DIR/venv/bin/pip" install --upgrade pip --quiet

    echo -e "${CYAN}→${NC} Installing dependencies..."
    cd "$MCP_DIR"
    if "$MCP_DIR/venv/bin/pip" install -e ".[enhanced]" --quiet 2>&1; then
        echo -e "${GREEN}✓${NC} Enhanced dependencies installed"
    elif "$MCP_DIR/venv/bin/pip" install -e "." --quiet 2>&1; then
        echo -e "${YELLOW}⚠${NC}  Core dependencies installed (enhanced features unavailable)"
    else
        echo -e "${RED}✗${NC} Video tools installation failed!"
        echo "   Try running: cd $MCP_DIR && $PYTHON_CMD -m venv venv && venv/bin/pip install -e ."
        exit 1
    fi

    # Verify install
    if "$MCP_DIR/venv/bin/python" -c "import mcp; import whisper" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Dependencies verified"
    else
        echo -e "${RED}✗${NC} Installation verification failed!"
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

# Playwright cache location is OS-dependent
if [[ "$(uname)" == "Darwin" ]]; then
    PLAYWRIGHT_CACHE="$HOME/Library/Caches/ms-playwright"
else
    PLAYWRIGHT_CACHE="$HOME/.cache/ms-playwright"
fi

# Check if Chromium browser is installed
if [ -d "$PLAYWRIGHT_CACHE" ] && ls "$PLAYWRIGHT_CACHE/" 2>/dev/null | grep -q "chromium"; then
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
    if [ -d "$PLAYWRIGHT_CACHE" ] && ls "$PLAYWRIGHT_CACHE/" 2>/dev/null | grep -q "chromium"; then
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
