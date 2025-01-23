alias git=git.exe
msedge(){
	/mnt/c/Program\ Files\ \(x86\)/Microsoft/Edge/Application/msedge.exe "$@"
}
alias python=python3

alias vm=nvim

alias au="sudo ~/.config/apt_update.sh"
alias sb="source ~/.bashrc"
alias enva="source ./env/bin/activate"
alias envd="deactivate"
alias py3="python3"
alias pip="pip3"
alias lg="lazygit"
alias fd='fd --color=never'
alias ls='ls --color=never'
alias grep='grep --color=never'

rmlf(){
	echo "Changing $1"
	sed -i -e "s/\r//g" "$1"
}
alias rmlf=rmlf
alias attach="tmux attach -t"
alias detach="if [ -n "$TMUX" ]; then tmux detach; else exit; fi"

declare -A gotoPaths
gotoPaths["config"]="$HOME/.config"
gotoPaths["nvim"]="$HOME/.config/nvim"


echo "Sourced Bash Aliases"


# Utils Functions
goto(){
	source $HOME/.config/bash_sh/utils.sh
	goto "$@"
}

enable_file(){
	source $HOME/.config/bash_sh/utils.sh
	enable_file "$@"
}
	

# Git Helper Functions
alias gremote="git remote -v"
alias git="/usr/bin/git"
source $DOTFILES_DIR/bash_sh/git_help.sh
alias rmlock="remove_lock"
githelp(){
	guideline
}

