#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Tutorialinator Installer
# Works from cloned repo OR piped via: curl ... | bash
# Dashboard-style installation with live progress
# ─────────────────────────────────────────────────────────────────────────────

# Colors (matching the CLI/dashboard palette)
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SKILL_DEST="$HOME/.claude/skills/tutorialinator"
MCP_DIR="$SKILL_DEST/mcp-server"
VENV_DIR="$MCP_DIR/venv"
SETTINGS_FILE="$HOME/.claude/settings.json"

# ─────────────────────────────────────────────────────────────────────────────
# Dashboard Drawing Primitives
# ─────────────────────────────────────────────────────────────────────────────

# Status indicators (matching dashboard.py exactly)
S_PENDING="○"
S_ACTIVE="◉"
S_DONE="✓"
S_FAIL="✗"
S_WARN="◎"
S_ARROW="→"
S_DOT="•"

is_interactive() { [ -t 0 ]; }

# Progress bar: ████████░░ 80%  (matches dashboard._make_progress_bar)
progress_bar() {
    local pct=$1
    local filled=$((pct / 10))
    local empty=$((10 - filled))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    printf "%s %3d%%" "$bar" "$pct"
}

# Panel: ╭─── Title ───╮ (matching Rich box.ROUNDED)
panel_top() {
    local title="$1" width="${2:-60}"
    local title_len=${#title}
    local pad=$(( (width - title_len - 4) / 2 ))
    local pad_r=$(( width - title_len - 4 - pad ))
    printf "  ${CYAN}╭"
    printf '─%.0s' $(seq 1 $pad)
    printf " %s " "$title"
    printf '─%.0s' $(seq 1 $pad_r)
    printf "╮${NC}\n"
}

panel_row() {
    local content="$1" width="${2:-60}"
    local stripped
    stripped=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
    local content_len=${#stripped}
    local pad=$(( width - content_len - 4 ))
    if [ $pad -lt 0 ]; then pad=0; fi
    printf "  ${CYAN}│${NC} %b" "$content"
    printf '%*s' "$pad" ""
    printf " ${CYAN}│${NC}\n"
}

panel_empty() {
    local width="${1:-60}"
    local inner=$(( width - 2 ))
    printf "  ${CYAN}│${NC}"
    printf '%*s' "$inner" ""
    printf "${CYAN}│${NC}\n"
}

panel_bottom() {
    local width="${1:-60}"
    printf "  ${CYAN}╰"
    printf '─%.0s' $(seq 1 $((width - 2)))
    printf "╯${NC}\n"
}

# Step status line:  ◉ Step Name          ████░░░░░░  40%  details
step_line() {
    local symbol="$1" color="$2" name="$3" pct="$4" detail="${5:-}"
    local bar
    bar=$(progress_bar "$pct")
    printf "  ${color}%s${NC}  %-22s %s  ${DIM}%s${NC}\n" "$symbol" "$name" "$bar" "$detail"
}

# Section header (matching dashboard header style)
section_header() {
    local title="$1"
    echo ""
    echo -e "  ${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "  ${CYAN}▓▓▓${NC}  ${BOLD}$title${NC}"
    echo -e "  ${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

die() {
    echo -e "  ${RED}${S_FAIL}${NC}  ${RED}$*${NC}"
    echo ""
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Logo
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}"
cat << 'BANNER'
     ╔═══════════════════════════════════════════════════════════════╗
     ║                                                               ║
     ║    ████████╗██╗   ██╗████████╗ ██████╗ ██████╗ ██╗ █████╗     ║
     ║    ╚══██╔══╝██║   ██║╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗    ║
     ║       ██║   ██║   ██║   ██║   ██║   ██║██████╔╝██║███████║    ║
     ║       ██║   ██║   ██║   ██║   ██║   ██║██╔══██╗██║██╔══██║    ║
     ║       ██║   ╚██████╔╝   ██║   ╚██████╔╝██║  ██║██║██║  ██║    ║
     ║       ╚═╝    ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝    ║
     ║                                                               ║
     ║       ██╗     ██╗███╗   ██╗ █████╗ ████████╗ ██████╗ ██████╗  ║
     ║       ██║     ██║████╗  ██║██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗ ║
     ║       ██║     ██║██╔██╗ ██║███████║   ██║   ██║   ██║██████╔╝ ║
     ║       ██║     ██║██║╚██╗██║██╔══██║   ██║   ██║   ██║██╔══██╗ ║
     ║       ███████╗██║██║ ╚████║██║  ██║   ██║   ╚██████╔╝██║  ██║ ║
     ║       ╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ║
     ║                                                               ║
     ╚═══════════════════════════════════════════════════════════════╝

        [▓▓▓▓▓]═══════════════════════════════════════[▓▓▓▓▓]

       ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌──────────┐
       │  VIDEO  │   │  TOPIC  │   │   WEB   │   │   DEEP   │
       │   .mp4  │   │ "teach" │   │  URLs   │   │ RESEARCH │
       └────┬────┘   └────┬────┘   └────┬────┘   └────┬─────┘
            │             │             │             │
            └─────────────┴──────┬──────┴─────────────┘
                                 │
                            ╔════╧════╗
                            ║   AI    ║
                            ║  ⚡⚡⚡  ║
                            ╚════╤════╝
                                 │
                          ┌──────┴──────┐
                          │  TUTORIAL   │
                          │    SITE     │
                          └─────────────┘
BANNER
echo -e "${NC}"

# ─────────────────────────────────────────────────────────────────────────────
# Installation Dashboard Overview
# ─────────────────────────────────────────────────────────────────────────────

echo ""
panel_top "Installation Dashboard" 60
panel_empty 60
panel_row "${BOLD}Agent${NC}                  ${BOLD}Status${NC}       ${BOLD}Progress${NC}" 60
panel_row "──────────────────────────────────────────────────────" 60
panel_row "${CYAN}Source Files${NC}          ${YELLOW}${S_PENDING} Pending${NC}    ░░░░░░░░░░   0%" 60
panel_row "${CYAN}Prerequisites${NC}         ${YELLOW}${S_PENDING} Pending${NC}    ░░░░░░░░░░   0%" 60
panel_row "${CYAN}Python Environment${NC}    ${YELLOW}${S_PENDING} Pending${NC}    ░░░░░░░░░░   0%" 60
panel_row "${CYAN}Dependencies${NC}          ${YELLOW}${S_PENDING} Pending${NC}    ░░░░░░░░░░   0%" 60
panel_row "${CYAN}Whisper Model${NC}         ${YELLOW}${S_PENDING} Pending${NC}    ░░░░░░░░░░   0%" 60
panel_row "${CYAN}Playwright${NC}            ${YELLOW}${S_PENDING} Pending${NC}    ░░░░░░░░░░   0%" 60
panel_row "${CYAN}Configuration${NC}         ${YELLOW}${S_PENDING} Pending${NC}    ░░░░░░░░░░   0%" 60
panel_row "${CYAN}Verification${NC}          ${YELLOW}${S_PENDING} Pending${NC}    ░░░░░░░░░░   0%" 60
panel_empty 60
panel_bottom 60
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Step 0: Locate Source Files
# ─────────────────────────────────────────────────────────────────────────────

section_header "Source Files ${S_ARROW} Locating installation files"

SCRIPT_DIR=""
TEMP_CLONE=""

if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/skill/SKILL.md" ]; then
    SOURCE_DIR="$SCRIPT_DIR/skill"
    step_line "$S_DONE" "$GREEN" "Source Files" 100 "Local repo: $SCRIPT_DIR"
elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/SKILL.md" ]; then
    SOURCE_DIR="$SCRIPT_DIR"
    step_line "$S_DONE" "$GREEN" "Source Files" 100 "Local repo: $SCRIPT_DIR"
else
    step_line "$S_ACTIVE" "$CYAN" "Source Files" 20 "Cloning repository..."
    TEMP_CLONE="$(mktemp -d)"
    if ! command -v git &>/dev/null; then
        die "git is required for curl|bash install. Install git first."
    fi
    git clone --depth 1 https://github.com/masudl-hub/tutorialinator.git "$TEMP_CLONE" 2>&1 | while read -r line; do
        echo -e "       ${DIM}$line${NC}"
    done
    # Support both repo layouts: skill/ subdirectory or flat root
    if [ -f "$TEMP_CLONE/skill/SKILL.md" ]; then
        SOURCE_DIR="$TEMP_CLONE/skill"
    elif [ -f "$TEMP_CLONE/SKILL.md" ]; then
        SOURCE_DIR="$TEMP_CLONE"
    else
        die "Clone succeeded but SKILL.md not found. Repo may be malformed."
    fi
    step_line "$S_DONE" "$GREEN" "Source Files" 100 "Downloaded to temp directory"
fi

cleanup() {
    if [ -n "$TEMP_CLONE" ] && [ -d "$TEMP_CLONE" ]; then
        rm -rf "$TEMP_CLONE"
    fi
}
trap cleanup EXIT

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Prerequisites — System Check Panel
# ─────────────────────────────────────────────────────────────────────────────

section_header "Prerequisites ${S_ARROW} Checking system requirements"

echo ""
panel_top "System Check" 60
panel_row "${BOLD}Component${NC}        ${BOLD}Status${NC}    ${BOLD}Purpose${NC}" 60
panel_row "────────────────────────────────────────────────────" 60

# Python 3.10+ — search for a suitable version
PYTHON_CMD=""
for candidate in python3 python3.13 python3.12 python3.11 python3.10 \
                 /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 \
                 /opt/homebrew/bin/python3.11 /opt/homebrew/bin/python3.10 \
                 /opt/homebrew/bin/python3; do
    if command -v "$candidate" &>/dev/null || [ -x "$candidate" ]; then
        PY_VER=$("$candidate" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null) || continue
        PY_MAJ=$(echo "$PY_VER" | cut -d. -f1)
        PY_MIN=$(echo "$PY_VER" | cut -d. -f2)
        if [ "$PY_MAJ" -ge 3 ] && [ "$PY_MIN" -ge 10 ]; then
            PYTHON_CMD="$candidate"
            PY_VERSION="$PY_VER"
            break
        fi
    fi
done

if [ -n "$PYTHON_CMD" ]; then
    panel_row "Python $PY_VERSION     ${GREEN}${S_DONE}${NC}         Runtime environment" 60
    panel_row "  ${DIM}($PYTHON_CMD)${NC}" 60
else
    # Report what we found
    if command -v python3 &>/dev/null; then
        OLD_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
        panel_row "Python $OLD_VER     ${RED}${S_FAIL}${NC}         Needs 3.10+" 60
    else
        panel_row "Python           ${RED}${S_FAIL}${NC}         Not found" 60
    fi
    panel_bottom 60
    echo ""
    die "Python 3.10+ required. Install: brew install python@3.12 (macOS) or sudo apt install python3.12 (Ubuntu)"
fi

# Node.js + npx
if command -v node &>/dev/null && command -v npx &>/dev/null; then
    NODE_VER=$(node --version)
    panel_row "Node.js $NODE_VER   ${GREEN}${S_DONE}${NC}         Playwright & tooling" 60
else
    panel_row "Node.js          ${RED}${S_FAIL}${NC}         Not found" 60
    panel_bottom 60
    echo ""
    die "Node.js + npx not found. Install: brew install node (macOS) or see https://nodejs.org"
fi

# FFmpeg (self-heal on macOS)
if command -v ffmpeg &>/dev/null; then
    FF_VER=$(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')
    panel_row "FFmpeg $FF_VER   ${GREEN}${S_DONE}${NC}         Video processing" 60
else
    if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
        panel_row "FFmpeg           ${YELLOW}${S_WARN}${NC}         Auto-installing..." 60
        panel_bottom 60
        echo ""
        step_line "$S_ACTIVE" "$CYAN" "FFmpeg" 50 "brew install ffmpeg..."
        brew install ffmpeg 2>&1 | tail -3
        step_line "$S_DONE" "$GREEN" "FFmpeg" 100 "Installed via Homebrew"
        echo ""
        panel_top "System Check (continued)" 60
    else
        panel_row "FFmpeg           ${RED}${S_FAIL}${NC}         Not found" 60
        panel_bottom 60
        echo ""
        die "FFmpeg not found. Install: brew install ffmpeg (macOS) or sudo apt install ffmpeg (Ubuntu) or sudo dnf install ffmpeg (Fedora)"
    fi
fi

# yt-dlp (checked but optional — will be installed via pip)
panel_row "yt-dlp           ${DIM}${S_DOT}${NC}         ${DIM}Via pip (video downloads)${NC}" 60
panel_row "Whisper          ${DIM}${S_DOT}${NC}         ${DIM}Via pip (transcription)${NC}" 60

panel_bottom 60
echo ""

step_line "$S_DONE" "$GREEN" "Prerequisites" 100 "All system requirements met"

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Copy skill files
# ─────────────────────────────────────────────────────────────────────────────

section_header "Skill Files ${S_ARROW} Installing to ~/.claude/skills/"

step_line "$S_ACTIVE" "$CYAN" "Skill Files" 10 "Creating directories..."

mkdir -p "$SKILL_DEST/templates"
mkdir -p "$SKILL_DEST/mcp-server/mcp_video_tutorial"

step_line "$S_ACTIVE" "$CYAN" "Skill Files" 40 "Copying SKILL.md, templates..."

cp "$SOURCE_DIR/SKILL.md"                          "$SKILL_DEST/SKILL.md"
cp "$SOURCE_DIR/auto-setup.sh"                     "$SKILL_DEST/auto-setup.sh"
cp "$SOURCE_DIR/templates/README.md"               "$SKILL_DEST/templates/README.md"
cp "$SOURCE_DIR/templates/DESIGN_UPDATES.md"       "$SKILL_DEST/templates/DESIGN_UPDATES.md"

step_line "$S_ACTIVE" "$CYAN" "Skill Files" 70 "Copying MCP server..."

cp "$SOURCE_DIR/mcp-server/pyproject.toml"         "$SKILL_DEST/mcp-server/pyproject.toml"
cp "$SOURCE_DIR/mcp-server/mcp_video_tutorial/__init__.py"  "$SKILL_DEST/mcp-server/mcp_video_tutorial/__init__.py"
cp "$SOURCE_DIR/mcp-server/mcp_video_tutorial/__main__.py"  "$SKILL_DEST/mcp-server/mcp_video_tutorial/__main__.py"
cp "$SOURCE_DIR/mcp-server/mcp_video_tutorial/server.py"    "$SKILL_DEST/mcp-server/mcp_video_tutorial/server.py"

chmod +x "$SKILL_DEST/auto-setup.sh"

step_line "$S_DONE" "$GREEN" "Skill Files" 100 "9 files installed"

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Python virtual environment (self-healing)
# ─────────────────────────────────────────────────────────────────────────────

section_header "Python Environment ${S_ARROW} Virtual environment setup"

venv_healthy() {
    [ -d "$VENV_DIR" ] &&
    [ -f "$VENV_DIR/bin/python" ] &&
    "$VENV_DIR/bin/python" -c "import sys; sys.exit(0)" &>/dev/null
}

if venv_healthy; then
    step_line "$S_DONE" "$GREEN" "Python Environment" 100 "Existing venv healthy"
else
    if [ -d "$VENV_DIR" ]; then
        step_line "$S_WARN" "$YELLOW" "Python Environment" 20 "Broken venv detected, rebuilding..."
        rm -rf "$VENV_DIR"
    else
        step_line "$S_ACTIVE" "$CYAN" "Python Environment" 20 "Creating virtual environment..."
    fi
    "$PYTHON_CMD" -m venv "$VENV_DIR"
    step_line "$S_DONE" "$GREEN" "Python Environment" 60 "Virtual environment created"
fi

step_line "$S_ACTIVE" "$CYAN" "Python Environment" 80 "Upgrading pip..."
"$VENV_DIR/bin/python" -m pip install --upgrade pip --quiet 2>&1 | tail -1
step_line "$S_DONE" "$GREEN" "Python Environment" 100 "pip up to date"

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Install Python packages
# ─────────────────────────────────────────────────────────────────────────────

section_header "Dependencies ${S_ARROW} Installing Python packages"

step_line "$S_ACTIVE" "$CYAN" "Dependencies" 0 "pip install (this may take a few minutes)..."

cd "$MCP_DIR"

# Try enhanced first (includes OCR + timestamped whisper), fall back to base
ENHANCED_OK=true
"$VENV_DIR/bin/pip" install -e ".[enhanced]" --quiet 2>&1 | while IFS= read -r line; do
    echo -ne "\r  ${CYAN}${S_ACTIVE}${NC}  Dependencies             ████░░░░░░  40%  ${DIM}${line:0:40}${NC}  \033[K"
done
echo ""

# Check if enhanced install actually succeeded (pip in a pipe doesn't propagate exit code)
if ! "$VENV_DIR/bin/python" -c "import rapidocr_onnxruntime" &>/dev/null; then
    ENHANCED_OK=false
    step_line "$S_WARN" "$YELLOW" "Dependencies" 50 "Enhanced deps unavailable, installing core..."
    "$VENV_DIR/bin/pip" install -e "." --quiet 2>&1 | while IFS= read -r line; do
        echo -ne "\r  ${CYAN}${S_ACTIVE}${NC}  Dependencies             ███████░░░  70%  ${DIM}${line:0:40}${NC}  \033[K"
    done
    echo ""
    # Verify core install succeeded
    if ! "$VENV_DIR/bin/python" -c "import mcp; import whisper" &>/dev/null; then
        step_line "$S_FAIL" "$RED" "Dependencies" 0 "Core install failed — check Python version and try manually"
        echo "   Try: cd $MCP_DIR && $PYTHON_CMD -m venv venv && venv/bin/pip install -e ."
        exit 1
    fi
fi

if [ "$ENHANCED_OK" = true ]; then
    step_line "$S_DONE" "$GREEN" "Dependencies" 100 "All packages installed (enhanced)"
else
    step_line "$S_DONE" "$GREEN" "Dependencies" 100 "Core packages installed"
fi

echo ""
panel_top "Installed Packages" 60
panel_row "${DIM}${S_DOT} mcp             Model Context Protocol SDK${NC}" 60
panel_row "${DIM}${S_DOT} fastmcp         FastMCP server framework${NC}" 60
panel_row "${DIM}${S_DOT} openai-whisper  Local speech-to-text${NC}" 60
panel_row "${DIM}${S_DOT} yt-dlp          Video downloading${NC}" 60
panel_row "${DIM}${S_DOT} ffmpeg-python   FFmpeg bindings${NC}" 60
panel_row "${DIM}${S_DOT} pydantic        Data validation${NC}" 60
panel_row "${DIM}${S_DOT} httpx           HTTP client${NC}" 60
panel_row "${DIM}${S_DOT} beautifulsoup4  HTML parsing${NC}" 60
panel_row "${DIM}${S_DOT} rich            Terminal formatting${NC}" 60
panel_bottom 60

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Whisper model selection & download
# ─────────────────────────────────────────────────────────────────────────────

section_header "Whisper Model ${S_ARROW} Speech-to-text engine"

MODEL="base"

if is_interactive; then
    echo ""
    panel_top "Whisper Model Selection" 60
    panel_empty 60
    panel_row "${BOLD}Which Whisper model would you like?${NC}" 60
    panel_empty 60
    panel_row "  1. ${GREEN}base${NC}    ~140 MB   Fast, good for clear audio" 60
    panel_row "                     ${DIM}(recommended)${NC}" 60
    panel_empty 60
    panel_row "  2. ${CYAN}large${NC}   ~1.5 GB   Slower, better accuracy" 60
    panel_row "                     ${DIM}for noisy/accented audio${NC}" 60
    panel_empty 60
    panel_bottom 60
    echo ""
    echo -ne "  ${BOLD}Select${NC} [${DIM}1${NC}]: "
    read -r model_choice
    if [ "$model_choice" = "2" ]; then
        MODEL="large"
    fi
    echo ""
fi

step_line "$S_ACTIVE" "$CYAN" "Whisper Model" 20 "Downloading '$MODEL' model..."

if "$VENV_DIR/bin/python" -c "import whisper; whisper.load_model('$MODEL')" 2>&1 | while IFS= read -r line; do
    echo -ne "\r  ${CYAN}${S_ACTIVE}${NC}  Whisper Model             █████░░░░░  50%  ${DIM}${line:0:35}${NC}  \033[K"
done; then
    echo ""
    step_line "$S_DONE" "$GREEN" "Whisper Model" 100 "'$MODEL' model ready"
else
    echo ""
    step_line "$S_WARN" "$YELLOW" "Whisper Model" 50 "Download failed, retrying..."
    if "$VENV_DIR/bin/python" -c "import whisper; whisper.load_model('$MODEL')" 2>&1 | tail -3; then
        step_line "$S_DONE" "$GREEN" "Whisper Model" 100 "'$MODEL' model ready (retry)"
    else
        step_line "$S_WARN" "$YELLOW" "Whisper Model" 80 "Will download on first use"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 6: Playwright + Chromium (non-fatal)
# ─────────────────────────────────────────────────────────────────────────────

section_header "Playwright ${S_ARROW} Browser validation engine"

step_line "$S_ACTIVE" "$CYAN" "Playwright" 20 "Installing MCP package..."

if npx --yes @playwright/mcp@latest --version &>/dev/null 2>&1; then
    step_line "$S_ACTIVE" "$CYAN" "Playwright" 50 "MCP package ready"
else
    step_line "$S_WARN" "$YELLOW" "Playwright" 30 "MCP package had issues (non-fatal)"
fi

# Install Chromium browser
if [[ "$(uname)" == "Darwin" ]]; then
    PLAYWRIGHT_CACHE="$HOME/Library/Caches/ms-playwright"
else
    PLAYWRIGHT_CACHE="$HOME/.cache/ms-playwright"
fi
if [ -d "$PLAYWRIGHT_CACHE" ] && ls "$PLAYWRIGHT_CACHE/" 2>/dev/null | grep -q "chromium"; then
    step_line "$S_DONE" "$GREEN" "Playwright" 100 "Chromium already installed"
else
    step_line "$S_ACTIVE" "$CYAN" "Playwright" 60 "Installing Chromium browser..."
    TMPDIR_PW=$(mktemp -d)
    if (
        cd "$TMPDIR_PW"
        npm init -y > /dev/null 2>&1
        npm install @playwright/test > /dev/null 2>&1
        npx playwright install chromium 2>&1 | tail -3
    ); then
        step_line "$S_DONE" "$GREEN" "Playwright" 100 "Chromium installed"
    else
        step_line "$S_WARN" "$YELLOW" "Playwright" 80 "Chromium install had issues (non-fatal)"
    fi
    rm -rf "$TMPDIR_PW"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 7 & 8: Configuration (MCP + settings.json)
# ─────────────────────────────────────────────────────────────────────────────

section_header "Configuration ${S_ARROW} MCP servers & Claude Code settings"

step_line "$S_ACTIVE" "$CYAN" "Configuration" 20 "Writing .mcp.json..."

cat > "$SKILL_DEST/.mcp.json" <<EOF
{
  "mcpServers": {
    "tutorialinator": {
      "command": "$VENV_DIR/bin/python",
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

step_line "$S_ACTIVE" "$CYAN" "Configuration" 60 "Patching settings.json..."

mkdir -p "$HOME/.claude"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{"enableAllProjectMcpServers": true}' > "$SETTINGS_FILE"
    step_line "$S_DONE" "$GREEN" "Configuration" 100 "Created settings.json"
elif ! "$PYTHON_CMD" -c "import json; json.load(open('$SETTINGS_FILE'))" &>/dev/null; then
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
    echo '{"enableAllProjectMcpServers": true}' > "$SETTINGS_FILE"
    step_line "$S_WARN" "$YELLOW" "Configuration" 90 "Rebuilt malformed settings.json (.bak saved)"
else
    "$VENV_DIR/bin/python" -c "
import json, sys
path = '$SETTINGS_FILE'
with open(path) as f:
    data = json.load(f)
if data.get('enableAllProjectMcpServers') is True:
    print('already set')
    sys.exit(0)
data['enableAllProjectMcpServers'] = True
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
print('added')
" 2>/dev/null || true
    step_line "$S_DONE" "$GREEN" "Configuration" 100 "MCP + settings.json configured"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 9: Verification
# ─────────────────────────────────────────────────────────────────────────────

section_header "Verification ${S_ARROW} Testing installation"

VERIFY_PASS=true

step_line "$S_ACTIVE" "$CYAN" "Verification" 30 "Testing Python imports..."

if "$VENV_DIR/bin/python" -c "import mcp; import whisper; import fastmcp" &>/dev/null; then
    step_line "$S_ACTIVE" "$CYAN" "Verification" 60 "Core imports OK"
else
    step_line "$S_FAIL" "$RED" "Verification" 30 "Import check failed"
    VERIFY_PASS=false
fi

if [ -f "$SKILL_DEST/SKILL.md" ] && [ -f "$SKILL_DEST/.mcp.json" ]; then
    step_line "$S_ACTIVE" "$CYAN" "Verification" 80 "Skill files in place"
else
    step_line "$S_FAIL" "$RED" "Verification" 40 "Skill files missing"
    VERIFY_PASS=false
fi

if [ "$VERIFY_PASS" = true ]; then
    step_line "$S_DONE" "$GREEN" "Verification" 100 "All checks passed"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Final Dashboard Summary
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo ""

if [ "$VERIFY_PASS" = true ]; then
    echo -e "  ${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "  ${CYAN}▓▓▓${NC}  ${BOLD}I N S T A L L A T I O N   C O M P L E T E${NC}"
    echo -e "  ${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""

    # Final status table (matching dashboard agent table)
    panel_top "Final Status" 60
    panel_row "${BOLD}Agent${NC}                  ${BOLD}Status${NC}       ${BOLD}Progress${NC}" 60
    panel_row "──────────────────────────────────────────────────────" 60
    panel_row "${CYAN}Source Files${NC}          ${GREEN}${S_DONE} Complete${NC}   ██████████ 100%" 60
    panel_row "${CYAN}Prerequisites${NC}         ${GREEN}${S_DONE} Complete${NC}   ██████████ 100%" 60
    panel_row "${CYAN}Python Environment${NC}    ${GREEN}${S_DONE} Complete${NC}   ██████████ 100%" 60
    panel_row "${CYAN}Dependencies${NC}          ${GREEN}${S_DONE} Complete${NC}   ██████████ 100%" 60
    panel_row "${CYAN}Whisper Model${NC}         ${GREEN}${S_DONE} Complete${NC}   ██████████ 100%" 60
    panel_row "${CYAN}Playwright${NC}            ${GREEN}${S_DONE} Complete${NC}   ██████████ 100%" 60
    panel_row "${CYAN}Configuration${NC}         ${GREEN}${S_DONE} Complete${NC}   ██████████ 100%" 60
    panel_row "${CYAN}Verification${NC}          ${GREEN}${S_DONE} Complete${NC}   ██████████ 100%" 60
    panel_bottom 60

    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << 'SUCCESS'
        ╔═══════════════════════════════════════╗
        ║                                       ║
        ║        ✓  TUTORIALINATION            ║
        ║           COMPLETE!                   ║
        ║                                       ║
        ║     ┌─────────────────────┐          ║
        ║     │  INTERACTIVE SITE   │          ║
        ║     │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │          ║
        ║     │  ▓ READY TO DEPLOY▓ │          ║
        ║     │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │          ║
        ║     └─────────────────────┘          ║
        ║                                       ║
        ╚═══════════════════════════════════════╝
SUCCESS
    echo -e "${NC}"

    # Next steps in a panel (matching CLI panel style)
    panel_top "Next Steps" 60
    panel_empty 60
    panel_row "  1. ${CYAN}Restart Claude Code${NC}" 60
    panel_row "     ${DIM}Type 'exit' and relaunch. MCP servers${NC}" 60
    panel_row "     ${DIM}load on startup.${NC}" 60
    panel_empty 60
    panel_row "  2. ${CYAN}Enable agent teams (recommended)${NC}" 60
    panel_row "     ${DIM}Enables parallel research, dedicated review,${NC}" 60
    panel_row "     ${DIM}and better context management. The skill${NC}" 60
    panel_row "     ${DIM}works without them but produces deeper${NC}" 60
    panel_row "     ${DIM}tutorials with teams enabled.${NC}" 60
    panel_empty 60
    panel_row "  3. ${CYAN}Create your first tutorial${NC}" 60
    panel_row "     ${DIM}/tutorialinator \"teach me TypeScript generics\"${NC}" 60
    panel_row "     ${DIM}/tutorialinator ~/Downloads/my-video.mp4${NC}" 60
    panel_empty 60
    panel_row "  ${DIM}Installed to: $SKILL_DEST${NC}" 60
    panel_empty 60
    panel_bottom 60
    echo ""

else
    echo -e "  ${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "  ${YELLOW}▓▓▓${NC}  ${BOLD}INSTALLED WITH WARNINGS${NC}"
    echo -e "  ${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""

    panel_top "Recovery" 60
    panel_row "Some checks failed. After restarting Claude Code:" 60
    panel_row "${DIM}~/.claude/skills/tutorialinator/auto-setup.sh${NC}" 60
    panel_bottom 60
    echo ""
fi
