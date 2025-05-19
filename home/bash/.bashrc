# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Only run once per shell session
if [ -z "$BASHRC_DONE" ] && [ -n "$BASH" ]; then
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

  if [ -n "$force_color_prompt" ]; then
      [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null && color_prompt=yes || color_prompt=
  fi

  if [ "$color_prompt" = yes ]; then
      PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  else
      PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
  fi
  unset color_prompt force_color_prompt

  # Brew initialization (only once)
  if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      export HOMEBREW_NO_ENV_HINTS=1
  fi

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
export DOTFILES_DIR="${DOTFILES_DIR:-"$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"}"

if [ -f ~/.config/.bash_aliases ]; then
	source ~/.config/.bash_aliases
fi

# SSH Setup (tmux-aware)
if [ -z "$SSH_SETUP_DONE" ]; then
  source "$DOTFILES_DIR/bash_sh/ssh_setup.sh"
  export SSH_SETUP_DONE=1
  
  # Update tmux environment if in tmux
  if [ -n "$TMUX" ]; then
    tmux set-environment SSH_AUTH_SOCK "$SSH_AUTH_SOCK" &>/dev/null
    tmux set-environment DOTFILES_DIR "$DOTFILES_DIR" &>/dev/null
  fi
fi

# Path modifications (after brew)
export PATH="/home/eyong/repos/ninja/build-cmake:$PATH"
export EDITOR=nvim
export VISUAL=nvim
export TERM="xterm-256color"
