#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Tutorialinator Uninstaller
# Dashboard-style removal matching the installer aesthetic
# ─────────────────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SKILL_DIR="$HOME/.claude/skills/tutorialinator"
WHISPER_CACHE="$HOME/.cache/whisper"
VIDEO_CACHE="$HOME/.cache/video-tutorial"
SETTINGS_FILE="$HOME/.claude/settings.json"

S_DONE="✓"
S_ACTIVE="◉"
S_DOT="•"
S_ARROW="→"

is_interactive() { [ -t 0 ]; }

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

step_line() {
    local symbol="$1" color="$2" name="$3" detail="${4:-}"
    printf "  ${color}%s${NC}  %-28s ${DIM}%s${NC}\n" "$symbol" "$name" "$detail"
}

# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo -e "  ${RED}════════════════════════════════════════════════════════${NC}"
echo -e "  ${RED}▓▓▓${NC}  ${BOLD}T U T O R I A L I N A T O R   ${RED}U N I N S T A L L${NC}"
echo -e "  ${RED}════════════════════════════════════════════════════════${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Remove skill directory
# ─────────────────────────────────────────────────────────────────────────────

if [ -d "$SKILL_DIR" ]; then
    rm -rf "$SKILL_DIR"
    step_line "$S_DONE" "$GREEN" "Skill directory" "Removed $SKILL_DIR"
else
    step_line "$S_DOT" "$DIM" "Skill directory" "Not found, skipping"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Optional cache removal (interactive prompt in panel)
# ─────────────────────────────────────────────────────────────────────────────

if [ -d "$WHISPER_CACHE" ]; then
    WHISPER_SIZE=$(du -sh "$WHISPER_CACHE" 2>/dev/null | awk '{print $1}')
    if is_interactive; then
        echo ""
        panel_top "Whisper Cache" 60
        panel_empty 60
        panel_row "Remove Whisper model cache?" 60
        panel_row "${DIM}$WHISPER_CACHE ($WHISPER_SIZE)${NC}" 60
        panel_empty 60
        panel_row "  1. ${GREEN}Keep${NC}    ${DIM}(recommended if reinstalling)${NC}" 60
        panel_row "  2. ${RED}Remove${NC}  ${DIM}Free up $WHISPER_SIZE disk space${NC}" 60
        panel_empty 60
        panel_bottom 60
        echo ""
        echo -ne "  ${BOLD}Select${NC} [${DIM}1${NC}]: "
        read -r cache_choice
        if [ "$cache_choice" = "2" ]; then
            rm -rf "$WHISPER_CACHE"
            step_line "$S_DONE" "$GREEN" "Whisper cache" "Removed ($WHISPER_SIZE freed)"
        else
            step_line "$S_DOT" "$DIM" "Whisper cache" "Kept"
        fi
    else
        step_line "$S_DOT" "$DIM" "Whisper cache" "Kept (non-interactive)"
    fi
fi

if [ -d "$VIDEO_CACHE" ]; then
    VIDEO_SIZE=$(du -sh "$VIDEO_CACHE" 2>/dev/null | awk '{print $1}')
    if is_interactive; then
        echo ""
        panel_top "Video Tutorial Cache" 60
        panel_empty 60
        panel_row "Remove video tutorial cache?" 60
        panel_row "${DIM}$VIDEO_CACHE ($VIDEO_SIZE)${NC}" 60
        panel_empty 60
        panel_row "  1. ${GREEN}Keep${NC}    ${DIM}(recommended)${NC}" 60
        panel_row "  2. ${RED}Remove${NC}  ${DIM}Free up $VIDEO_SIZE disk space${NC}" 60
        panel_empty 60
        panel_bottom 60
        echo ""
        echo -ne "  ${BOLD}Select${NC} [${DIM}1${NC}]: "
        read -r vcache_choice
        if [ "$vcache_choice" = "2" ]; then
            rm -rf "$VIDEO_CACHE"
            step_line "$S_DONE" "$GREEN" "Video cache" "Removed ($VIDEO_SIZE freed)"
        else
            step_line "$S_DOT" "$DIM" "Video cache" "Kept"
        fi
    else
        step_line "$S_DOT" "$DIM" "Video cache" "Kept (non-interactive)"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Revert settings.json
# ─────────────────────────────────────────────────────────────────────────────

if [ -f "$SETTINGS_FILE" ]; then
    if python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    data = json.load(f)
if 'enableAllProjectMcpServers' in data:
    del data['enableAllProjectMcpServers']
    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
    print('removed')
else:
    print('not present')
" 2>/dev/null; then
        step_line "$S_DONE" "$GREEN" "settings.json" "Cleaned enableAllProjectMcpServers"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo -e "  ${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}▓▓▓${NC}  ${BOLD}U N I N S T A L L   C O M P L E T E${NC}"
echo -e "  ${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

panel_top "Note" 60
panel_row "${DIM}System packages (Python, Node.js, FFmpeg)${NC}" 60
panel_row "${DIM}were not removed.${NC}" 60
panel_row "${DIM}Restart Claude Code to complete cleanup.${NC}" 60
panel_bottom 60
echo ""
