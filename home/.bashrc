# ~/.bashrc: executed by bash(1) for non-login shells.
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Load common environment
[ -f "$HOME/.bash_env" ] && source "$HOME/.bash_env"

# --- BASHRC DEBUG (enable with: touch ~/.debug_bashrc) ---
if [[ -f "$HOME/.debug_bashrc" ]]; then
  _dbg_log="$HOME/.bashrc.debug.$(date +%Y%m%d-%H%M%S).log"
  exec 9>"$_dbg_log"
  export BASH_XTRACEFD=9
  PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
  set -o errtrace -o functrace -o pipefail
  trap 'rc=$?; echo "ERR $rc at ${BASH_SOURCE}:${LINENO}: ${BASH_COMMAND}" >&9' ERR
  set -x
  _dbg_cleanup='set +x; trap - ERR; exec 9>&-; unset _dbg_log _dbg_cleanup'
  PROMPT_COMMAND="${_dbg_cleanup}${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  echo "bashrc debug log: $_dbg_log" >&2
fi
# --- /BASHRC DEBUG ---

# Only run once per shell session
if [ -z "${BASHRC_DONE:-}" ] && [ -n "${BASH:-}" ]; then
  # History settings
  HISTCONTROL=ignoreboth
  shopt -s histappend
  HISTSIZE=1000
  HISTFILESIZE=1500

  # Check window size
  shopt -s checkwinsize

  # Lesspipe setup
  [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

  # Debian chroot
  [ -r /etc/debian_chroot ] && debian_chroot=$(cat /etc/debian_chroot)

  # Prompt setup
  case "$TERM" in
      xterm-color|*-256color) color_prompt=yes;;
  esac

	if [ -n "${force_color_prompt:-}" ]; then
      [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null && color_prompt=yes || color_prompt=
  fi

  if [ "$color_prompt" = yes ]; then
      PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  else
      PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
  fi
  unset color_prompt force_color_prompt

  # Mark initialization as done
  export BASHRC_DONE=1
fi

# Always load these (safe for multiple sourcing)
# Color support
if [ -x /usr/bin/dircolors ]; then
    [ -r ~/.dircolors ] && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Completion
if ! shopt -oq posix; then
  [ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion ||
  [ -f /etc/bash_completion ] && . /etc/bash_completion
fi

# FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash


# Dotfiles path
if [ -f ~/.config/.bash_aliases ]; then
	source ~/.config/.bash_aliases
fi

if [ -z "${SSH_SETUP_DONE:-}" ]; then
  set +e +o errexit
  source "$DOTFILES/scripts/ssh_setup.sh"
  export SSH_SETUP_DONE=1
fi

# Always (re)sync SSH agent into tmux for any new interactive shell inside tmux
if [ -n "${TMUX:-}" ] && [ -n "${SSH_AUTH_SOCK:-}" ]; then
  # Only update if different to avoid churn
  cur="$(tmux show-environment -g SSH_AUTH_SOCK 2>/dev/null || true)"
  want="SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
  if [ "$cur" != "$want" ]; then
    tmux setenv -g SSH_AUTH_SOCK "$SSH_AUTH_SOCK" 2>/dev/null || true
    tmux refresh-client -S 2>/dev/null || true
  fi
fi

force_color_prompt=yes
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

# keep interactive shells from dying on harmless errors
case $- in *i*) set +o errexit 2>/dev/null; trap - ERR 2>/dev/null;; esac
