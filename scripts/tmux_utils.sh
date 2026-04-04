#!/bin/bash
# tmux_utils.sh - Interactive TMUX Guide & Command Reference
# Usage: ./tmux_utils.sh [section]   or   source tmux_utils.sh && tmux_guide

set -e

# Color codes for formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# =============================================================================
# CORE GUIDE FUNCTION - Main interactive menu
# =============================================================================
tmux_guide() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          TMUX ULTIMATE GUIDE & COMMAND REFERENCE           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Select a section to view:${NC}"
    echo "  1) 🚀 Quick Start (5 min essentials)"
    echo "  2) 🎛️  Key Bindings (Prefix: Ctrl-b)"
    echo "  3) 🪟  Window Management"
    echo "  4) ➗  Pane Management"
    echo "  5) 📊  Session Management"
    echo "  6) 📋  Copy Mode & Clipboard"
    echo "  7) ⚙️  Configuration & Customization"
    echo "  8) 💡 Advanced Tips & Tricks"
    echo "  9) 📖 Complete Cheat Sheet"
    echo "  0) ❌ Exit"
    echo ""
    read -p "Enter choice [0-9]: " choice
    
    case $choice in
        1) quick_start ;;
        2) key_bindings ;;
        3) windows_guide ;;
        4) panes_guide ;;
        5) sessions_guide ;;
        6) copy_mode_guide ;;
        7) config_guide ;;
        8) advanced_tips ;;
        9) full_cheat_sheet ;;
        0) echo -e "${GREEN}Happy tmuxing!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}"; sleep 1; tmux_guide ;;
    esac
}

# =============================================================================
# SECTION 1: QUICK START
# =============================================================================
quick_start() {
    clear
    echo -e "${MAGENTA}=== TMUX 5-MINUTE ESSENTIALS ===${NC}"
    cat << 'EOF'

BASIC CONCEPTS:
  • Session: Collection of windows (like a project workspace)
  • Window: Single screen with one or more panes (like a browser tab)
  • Pane: Split within a window (like split view in an editor)

PREFIX KEY:
  All commands start with PREFIX (default: Ctrl+b). Press then release,
  then press the command key.

ESSENTIAL COMMANDS TO MEMORIZE:
  PREFIX c  → Create new window
  PREFIX %  → Split pane vertically
  PREFIX "  → Split pane horizontally
  PREFIX arrow → Switch between panes
  PREFIX n/p → Next/previous window
  PREFIX d  → Detach session (keeps it running)
  
  $ tmux attach           → Re-attach to last session
  $ tmux new -s myproject → New named session

EOF
    press_any_key
}

# =============================================================================
# SECTION 2: KEY BINDINGS
# =============================================================================
key_bindings() {
    clear
    echo -e "${MAGENTA}=== ESSENTIAL KEY BINDINGS (AFTER PREFIX) ===${NC}"
    cat << 'EOF'

SESSION MANAGEMENT:
  d      Detach session
  $      Rename session
  ( )    Switch to previous/next session

WINDOW MANAGEMENT:
  c      Create new window
  ,      Rename current window
  &      Kill current window
  n/p    Next/previous window
  0-9    Jump to window number
  w      List windows (interactive)
  f      Find window by name

PANE MANAGEMENT:
  %      Split vertically (left/right)
  "      Split horizontally (up/down)
  x      Kill current pane
  !      Convert pane to window
  q      Show pane numbers (then press number to switch)
  { }    Swap pane left/right
  z      Toggle pane zoom
  space  Toggle between layouts
  arrow  Move to adjacent pane
  ;      Go to previously active pane
  o      Go to next pane

MISCELLANEOUS:
  ?      List all key bindings
  t      Show clock
  :      Enter command mode
  [      Enter copy mode
  ]      Paste buffer
  ~      Show messages
  #      List buffers

EOF
    press_any_key
}

# =============================================================================
# SECTION 3: WINDOWS GUIDE
# =============================================================================
windows_guide() {
    clear
    echo -e "${MAGENTA}=== WINDOW MANAGEMENT DEEP DIVE ===${NC}"
    cat << 'EOF'

CREATE & CLOSE:
  PREFIX c                    → New window
  PREFIX &                    → Kill current window (prompts)
  $ tmux new-window -n name   → New named window (from shell)

NAVIGATION:
  PREFIX n/p                  → Next/previous window
  PREFIX 0-9                  → Jump to window number
  PREFIX w                    → Interactive window list
  PREFIX f                    → Find window by name
  PREFIX '                    → Jump to window by number (prompt)

REORGANIZE:
  PREFIX ,                    → Rename window
  PREFIX .                    → Move window to position (prompt)
  PREFIX !                    → Move pane to new window
  $ tmux move-window -t :2    → Move current window to pos 2 (shell)

LAYOUT:
  PREFIX space                → Cycle through layouts
  PREFIX M-1..5               → Select layout directly:
        even-horizontal, even-vertical, main-horizontal, 
        main-vertical, tiled

EOF
    press_any_key
}

# =============================================================================
# SECTION 4: PANES GUIDE
# =============================================================================
panes_guide() {
    clear
    echo -e "${MAGENTA}=== PANE MANAGEMENT DEEP DIVE ===${NC}"
    cat << 'EOF'

SPLITTING:
  PREFIX %                    → Split vertically (left/right)
  PREFIX "                    → Split horizontally (up/down)
  $ tmux split-window -h      → Horizontal split from shell
  $ tmux split-window -v      → Vertical split from shell

RESIZING:
  PREFIX Ctrl+arrow           → Resize by 1 cell
  PREFIX Alt+arrow            → Resize by 5 cells
  PREFIX :resize-pane -U 10   → Resize up by 10 (command mode)

NAVIGATION:
  PREFIX arrow                → Move to adjacent pane
  PREFIX ;                    → Last active pane
  PREFIX q  [0-9]             → Show numbers, then jump
  PREFIX { }                  → Swap panes left/right

ADVANCED:
  PREFIX !                    → Convert pane to window
  PREFIX z                    → Toggle zoom (focus/unfocus)
  PREFIX x                    → Kill current pane
  PREFIX :swap-pane -s 1 -t 0 → Swap panes by number
  $ tmux join-pane -s :2      → Move pane from session 2

EOF
    press_any_key
}

# =============================================================================
# SECTION 5: SESSIONS GUIDE
# =============================================================================
sessions_guide() {
    clear
    echo -e "${MAGENTA}=== SESSION MANAGEMENT ===${NC}"
    cat << 'EOF'

CREATE & ATTACH:
  $ tmux new -s myapp         → New named session
  $ tmux new                  → New session
  $ tmux attach               → Attach to last session
  $ tmux attach -t myapp      → Attach to specific session
  $ tmux attach -d -t myapp   → Force attach (detach others)

LIST & SWITCH:
  $ tmux ls                   → List all sessions
  $ tmux list-sessions
  PREFIX s                    → Interactive session list
  PREFIX ( )                  → Previous/next session
  PREFIX $                    → Rename current session

MANAGE:
  PREFIX d                    → Detach current session
  $ tmux kill-session -t myapp → Kill session
  $ tmux kill-session -a      → Kill all but current
  $ tmux rename-session -t old new → Rename from shell

SESSION GROUPS (advanced):
  $ tmux new -s main          → Create 'main' session
  $ tmux new -s main:sub      → Create grouped session (shares windows)

EOF
    press_any_key
}

# =============================================================================
# SECTION 6: COPY MODE
# =============================================================================
copy_mode_guide() {
    clear
    echo -e "${MAGENTA}=== COPY MODE & CLIPBOARD ===${NC}"
    cat << 'EOF'

ENTER COPY MODE:
  PREFIX [                    → Enter copy mode
  PREFIX ]                    → Paste from buffer
  PREFIX =                    → List paste buffers

IN COPY MODE (emacs mode):
  Space                       → Start selection
  Enter                       → Copy selection
  q/Escape                    → Exit copy mode
  Ctrl+s                      → Search forward
  Ctrl+r                      → Search backward
  g/G                         → Go to top/bottom
  arrow/PgUp/PgDn             → Navigate

IN COPY MODE (vi mode):
  v                           → Start selection
  y                           → Copy selection
  q/Escape                    → Exit
  /?                          → Search forward/backward
  gg/G                        → Go to top/bottom

CLIPBOARD INTEGRATION:
  # Add to ~/.tmux.conf:
  bind-key -T copy-mode-vi v send-keys -X begin-selection
  bind-key -T copy-mode-vi y send-keys -X copy-pipe 'xclip -selection clipboard'
  
  # Then use PREFIX [ → v to select → y to copy to system clipboard

EOF
    press_any_key
}

# =============================================================================
# SECTION 7: CONFIGURATION
# =============================================================================
config_guide() {
    clear
    echo -e "${MAGENTA}=== CONFIGURATION EXAMPLES ===${NC}"
    cat << 'EOF'

CONFIG FILE: ~/.tmux.conf

# Change prefix to Ctrl+a (like screen)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Mouse support
set -g mouse on

# Reload config with PREFIX r
bind-key r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Easier pane splitting
bind | split-window -h
bind - split-window -v

# Start windows at 1 instead of 0
set -g base-index 1
set -g pane-base-index 1

# Enable 24-bit color
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

# Status bar customization
set -g status-bg black
set -g status-fg white
set -g status-left '#[fg=green]#S #[fg=yellow]→ #[default]'
set -g status-right '#[fg=blue]%d %b %Y #[fg=red]%H:%M#[default]'

# Clipboard integration (Linux)
bind-key -T copy-mode-vi y send-keys -X copy-pipe 'xclip -selection clipboard'
bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe 'xclip -selection clipboard'

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

EOF
    press_any_key
}

# =============================================================================
# SECTION 8: ADVANCED TIPS
# =============================================================================
advanced_tips() {
    clear
    echo -e "${MAGENTA}=== ADVANCED TIPS & TRICKS ===${NC}"
    cat << 'EOF'

PAIRS & SYNC:
  PREFIX :setw synchronize-panes on → Type in all panes simultaneously
  PREFIX :setw synchronize-panes off → Turn off sync

FIND & JUMP:
  PREFIX f                    → Find window name
  PREFIX '                    → Jump to window number

WINDOW LINKING:
  $ tmux link-window -s 1:2 -t 0 → Link window 2 from session 1 to current

PAUSE OUTPUT:
  PREFIX M-p                  → Pause pane output
  PREFIX M-p                  → Resume (toggle)

MONITOR WINDOWS:
  PREFIX M-m                  → Monitor window for activity
  PREFIX M-!                  → Monitor for silence

COMMAND MODE:
  PREFIX :                    → Enter command mode
  Useful commands:
    list-keys                 → Show all bindings
    list-commands             → Show all commands
    info                      → Show session info
    clock                     → Big clock

SCRIPTING:
  $ tmux ls -F "#{session_name}: #{session_windows} windows" → Format output
  $ tmux list-panes -a -F "#{pane_current_command}" → Show all panes

EOF
    press_any_key
}

# =============================================================================
# SECTION 9: FULL CHEAT SHEET
# =============================================================================
full_cheat_sheet() {
    clear
    echo -e "${MAGENTA}=== COMPLETE TMUX CHEAT SHEET ===${NC}"
    cat << 'EOF'

┌─────────────────────────────────────────────────────────────────────┐
│ SESSIONS                                                            │
├─────────────────────────────────────────────────────────────────────┤
│ tmux new -s name       New named session           PREFIX d         │
│ tmux attach -t name    Attach to session           PREFIX $ rename  │
│ tmux ls                List sessions               PREFIX s list    │
│ tmux kill-session -t   Kill session                PREFIX ( )       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ WINDOWS                                                             │
├─────────────────────────────────────────────────────────────────────┤
│ PREFIX c               New window                  PREFIX & kill    │
│ PREFIX n/p             Next/previous               PREFIX , rename  │
│ PREFIX 0-9             Jump to number              PREFIX w list    │
│ PREFIX f               Find window                 PREFIX . move    │
│ PREFIX space           Cycle layouts               PREFIX ! pane→win│
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ PANES                                                               │
├─────────────────────────────────────────────────────────────────────┤
│ PREFIX %               Split vertical              PREFIX x kill    │
│ PREFIX "               Split horizontal            PREFIX z zoom    │
│ PREFIX arrow           Navigate                  PREFIX ! pane→win│
│ PREFIX q [num]         Jump to pane number       PREFIX { } swap  │
│ PREFIX Ctrl+arrow      Resize 1 cell             PREFIX ; last    │
│ PREFIX Alt+arrow       Resize 5 cells            PREFIX space     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ COPY MODE (PREFIX [)                                                │
├─────────────────────────────────────────────────────────────────────┤
│ Space/v                Start selection   Enter/y      Copy          │
│ Ctrl+s/r               Search            q/Escape     Exit          │
│ g/G                    Top/bottom      ]              Paste       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ MISC & COMMANDS                                                     │
├─────────────────────────────────────────────────────────────────────┤
│ PREFIX ?               Key bindings     PREFIX : command mode       │
│ PREFIX t               Clock             $ tmux command -t target  │
│ PREFIX M-p             Pause pane        $ tmux kill-server         │
│ PREFIX r               Reload config     $ tmux list-commands      │
└─────────────────────────────────────────────────────────────────────┘

EOF
    press_any_key
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
press_any_key() {
    echo ""
    read -p "Press Enter to continue..."
    tmux_guide
}

# Show specific section directly if argument provided
if [[ $# -gt 0 ]]; then
    case $1 in
        quick|start) quick_start ;;
        keys|bindings) key_bindings ;;
        windows) windows_guide ;;
        panes) panes_guide ;;
        sessions) sessions_guide ;;
        copy|clipboard) copy_mode_guide ;;
        config) config_guide ;;
        tips|advanced) advanced_tips ;;
        cheat|full) full_cheat_sheet ;;
        *) echo -e "${RED}Unknown section: $1${NC}"
           echo "Available: quick, keys, windows, panes, sessions, copy, config, tips, cheat"
           exit 1 ;;
    esac
else
    # Interactive menu by default
    tmux_guide
fi
