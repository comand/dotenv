#
# Fzf configuration
#

# Set up fzf
[ -f $HOME/.fzf.bash ] && source $HOME/.fzf.bash

# Use fd instead of find
export FZF_DEFAULT_COMMAND='fd --type f'

# Solarized Light Modified
export FZF_DEFAULT_OPTS='
    --bind ctrl-n:page-down,ctrl-u:page-up,ctrl-j:down,ctrl-k:up,shift-tab:jump
    --color hl:33,fg+:241,bg+:221,hl+:33
    --color info:33,prompt:33,pointer:166,marker:166,spinner:33,gutter:33
    --prompt="▶ "
'

# Standard arguments for command line widgets implemented below.
FZF_WIDGET_ARGS="--border --height=~40% --info=right"

export FZF_CTRL_R_OPTS="$FZF_WIDGET_ARGS --info=right --exact"

# __fzf_history__() {
#   local output opts
#   opts="--height ${FZF_TMUX_HEIGHT:-40%} --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} --scheme=history ${FZF_CTRL_R_OPTS-} -n4.. +m +s --tac --ansi"
#   output=$( builtin history | FZF_DEFAULT_OPTS="$opts" $(__fzfcmd) --query "$READLINE_LINE" ) || return
#   READLINE_LINE=${output#*\[*\] }
#   if [[ -z "$READLINE_POINT" ]]; then
#     echo "$READLINE_LINE"
#   else
#     READLINE_POINT=0x7fffffff
#   fi
# }

# Open the matched file in VISUAL editor.
fzf-preview() {
    fzf $FZF_WIDGET_ARGS "$@" --preview '[[ $(file --mime {}) =~ binary ]] &&
        echo {} is a binary file || (bat --style=numbers --color=always {} || cat {}) 2>/dev/null | head -500'
}

fzf-edit() {
    editfiles=$(fzf-preview -m)
    if [[ -n $editfiles ]]; then
        history -s $VISUAL $editfiles
        $VISUAL $editfiles
    fi
}

# Edit the selected file(s)
bind -x '"\C-e": fzf-edit'

# Insert the selected file on the command line.
bind -x '"\C-f": fzf-file-widget'

# Fuzzy find in all files from the current working dir, allow multi selection
# of files with line numbers, open each unique file in a buffer with cursor at
# the line number of the first selected match.
fzf-edit-match() {
    editfiles=$(rg --line-number --no-heading '' \
        | fzf -m +s $FZF_WIDGET_ARGS \
        | awk -F: '{ if (!($1 in seen)) { seen[$1] = $2 } }
            END { for (i in seen) { print i":"seen[i] } }' )
    if [[ -n $editfiles ]]; then
        history -s $VISUAL $editfiles
        $VISUAL $editfiles
    fi
}

bind -x '"\C-g": fzf-edit-match'

# Fuzzy find in all directory paths for the current source tree.
fzf-cd-path() {
    if [[ -n ${SRCDIR+x} ]]; then
        sel=$( cd $SRCDIR && fd --type d | fzf $FZF_WIDGET_ARGS )
        [[ -n $sel ]] && eval "cd $SRCDIR/$sel ; echo $SRCDIR/$sel"
    fi
}
bind -x '"\C-p": fzf-cd-path'

egrok() {
    grok --color=always "$@" \
        | fzf --ansi -m +s $FZF_WIDGET_ARGS \
        | awk -v root=$SRCDIR -F: '{ if (!($1 in seen)) { seen[$1] = $2 } }
            END { for (i in seen) { print root"/"i":"seen[i] } }' \
        | xargs -r $VISUAL
}

_list_tests() {
    xmlstarlet sel -t -v "/testspecs/test/@name" testSpecs.xml
}

__select_tests__() {
    if [[ -f testSpecs.xml ]]; then
        _list_tests | fzf $FZF_WIDGET_ARGS $1 | paste -sd "," -
    fi
}

fzf-select-tests() {
    if [[ -f testSpecs.xml ]]; then
        local selected="$(__select_tests__ --multi)"
        READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
        READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
    fi
}
bind -x '"\et": fzf-select-tests'

fzf-run-tests() {
    local selected=$(__select_tests__ --multi)
    [[ -n $selected ]] && eval "echo runone -n $selected; runone -n $selected"
}
bind -x '"\er": fzf-run-tests'
