alias git=git.exe
msedge(){
	/mnt/c/Program\ Files\ \(x86\)/Microsoft/Edge/Application/msedge.exe "$@"
}
alias python=python3

alias vm=nvim

alias au="sudo $DOTFILES/scripts/apt_update.sh"
alias sb="source ~/.bashrc"
alias enva="source .venv/bin/activate"
alias envd="deactivate"
alias py3="python3"
alias pip="pip3"
alias lg="lazygit"
alias fd='fd --color=never'
alias ls='ls --color=never'
alias grep='grep --color=never'
alias dotfiles="cd ~/.dotfiles"
alias relink='source "$DOTFILES/setup/link-dotfiles.sh"'
rmlf(){
	echo "Changing $1"
	sed -i -e "s/\r//g" "$1"
}
alias rmlf=rmlf
alias attach="tmux attach -t"
alias detach="if [ -n "$TMUX" ]; then tmux detach; else exit; fi"

declare -A gotoPaths
gotoPaths["config"]="$DOTFILES/home/.config"
gotoPaths["nvim"]="$DOTFILES/home/config/nvim"
gotoPaths["dotfiles"]=$DOTFILES

echo "Sourced Bash Aliases"

[ -f "$DOTFILES/scripts/utils.sh" ] && source "$DOTFILES/scripts/utils.sh"

if [ -f "$DOTFILES/pkg/get_packages.sh" ]; then
  # shellcheck source=/dev/null
  source "$DOTFILES/pkg/get_packages.sh"
fi

# Git Helper Functions
alias gremote="git remote -v"
alias git="/usr/bin/git"
source $DOTFILES/scripts/git_help.sh
alias rmlock="remove_lock"
githelp(){
	guideline
}
alias fixsshkey='export SSH_AUTH_SOCK="$(tmux display -p "#{client_env:SSH_AUTH_SOCK}")"'
