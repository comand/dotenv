# Debugging
# PS4='+ $(date "+%s.%N")\011 '
# exec 3>&2 2>/tmp/bashstart.$$.log
# set -x

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

if [[ ! $PATH =~ $HOME/.local/bin  ]]; then
    USERPATH=(
        $HOME/bin
        $HOME/.local/bin
        $HOME/.local/opt/bin
        $HOME/.cargo/bin
        $HOME/.local/share/bob/nvim-bin
        )

    export PATH=$(join_by : "${USERPATH[@]}"):$PATH
fi

case "$-" in *i*) if [ -r ~/.bashrc ]; then source ~/.bashrc; fi ;; esac
