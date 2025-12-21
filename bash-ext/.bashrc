# If not running interactively, don't do anything.
[[ -z $PS1 ]] && return

# Source global definitions
[ -f /etc/bashrc ] && . /etc/bashrc

# Source local utilities
[[ -e $HOME/.bash-utils.sh ]] && source $HOME/.bash-utils.sh

umask 002
ulimit -c 0
set -o vi
shopt -s extglob
shopt -s globstar
shopt -s cdable_vars
shopt -s cdspell
shopt -s direxpand

# prevent ctrl-s/q from being interpreted as XON/XOFF.
stty -ixon

export VISUAL=neovide
export EDITOR=nvim

export PAGER=less
export LESS=-R
export MANPAGER='nvim +Man!'
export MANWIDTH=999
export BAT_THEME="Solarized (light)"

eval "$(dircolors -b $HOME/.dircolors)"
export EZA_COLORS=$LS_COLORS

# Source function libraries
#_BASHRC_BENCH=true
for script in "$HOME"/.bash.d/*.sh
do
    if [[ $_BASHRC_BENCH ]]; then
        TIMEFORMAT="$script: %R"
        time source $script
        unset TIMEFORMAT
    else
        source $script
    fi
done

# User specific aliases and functions
alias h="history"
alias df="df -h"
alias ptree=pstree
alias lg=lazygit

alias g=rg
alias ge=rg-edit
alias gvim=neovide
alias vim=nvim
alias ls="eza --icons=auto"

export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc

if [[ -n $SSH_CONNECTION ]]; then
    export PS1="\[\033[0;31m\]\u@\h\\$\[\033[0m\] "
elif [[ -n $container ]]; then
    export PS1="\[\033[0;31m\][\h]\[\033[0m\] \$ "
else
    export PS1="\s\\$ "
fi

export PYENV_ROOT=$HOME/.local/opt/pyenv
eval "$(~/.local/opt/bin/pyenv init --path)"
eval "$(~/.local/opt/bin/pyenv init -)"
export PIPX_DEFAULT_PYTHON=$(~/.local/opt/bin/pyenv which python)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

source <(leadr --bash)
