# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth  # Ignore duplicate lines and lines starting with space
shopt -s histappend     # Append to history file instead of overwriting
HISTSIZE=1000           # Number of commands to remember in history
HISTFILESIZE=1500       # Maximum size of the history file

# Check window size after each command and update LINES and COLUMNS
shopt -s checkwinsize

# Enable ** for recursive globbing (commented out by default)
# shopt -s globstar

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set debian_chroot if applicable
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Set a fancy prompt (color if supported)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Enable color support for ls and add aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Aliases for ls
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alert alias for long-running commands
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Source .bash_aliases if it exists
if [ -f ~/.config/.bash_aliases ]; then
    . ~/.config/.bash_aliases
fi

# Enable programmable completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Source fzf if it exists
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Custom PATH additions
export PATH="/home/eyong/repos/ninja/build-cmake:$PATH"

# Set default editor to Neovim
export EDITOR=nvim
export VISUAL=nvim

# Get the directory of the current script (resolves symlinks)
export DOTFILES_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Source ssh_setup.sh if it exists
if [ -f "$DOTFILES_DIR/bash_sh/ssh_setup.sh" ]; then
    source "$DOTFILES_DIR/bash_sh/ssh_setup.sh"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
