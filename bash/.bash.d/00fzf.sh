#
# Fzf configuration
#

# Set up fzf
[ -f $HOME/.fzf.bash ] && source $HOME/.fzf.bash

# Use fd instead of find
export FZF_DEFAULT_COMMAND="fd -tf -tl"

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
    # shellcheck disable=SC2016
    local preview='
        [[ $(file --mime {}) =~ binary ]] && echo {} is a binary file \
            || (bat --style=numbers --color=always {} \
            || cat {}) 2>/dev/null | head -500'
    fzf $FZF_WIDGET_ARGS "$@" --preview "$preview"
}

fzf-edit() {
    local editfiles
    mapfile -t editfiles < <(fzf-preview -m)
    if [[ ${#editfiles[@]} -gt 0 ]]; then
        printf -v line '%q ' "${editfiles[@]}"
        history -s "$VISUAL $line"
        $VISUAL "${editfiles[@]}"
    fi
}

# Edit the selected file(s)
bind -x '"\C-e": fzf-edit'

# Insert the selected file on the command line.
bind -x '"\C-f": fzf-file-widget'

fzf-edit-opened() {
    if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]]; then
        preview='git diff --no-prefix -U1000 $@ --color=always -- {-1}'
        mapfile -t candidates < <(git diff --name-only .)
    elif [[ -n $(p4 where 2>/dev/null) ]]; then
        preview='/bin/env P4DIFF="difft --display=inline --color=always -c10" p4 diff -f {}'
        mapfile -t candidates < <(p4 -ztag opened ... \
            | awk '/^\.\.\. clientFile/{print $NF}' \
            | xargs p4 where | awk '{print $NF}')
    fi
    if [[ ${#candidates[@]} -gt 0 ]]; then
        local editfiles
        mapfile -t editfiles < <(printf '%s\n' "${candidates[@]}" | \
            fzf $FZF_WIDGET_ARGS -m --no-height --preview "$preview")
        if [[ ${#editfiles[@]} -gt 0 ]]; then
            printf -v line '%q ' "${editfiles[@]}"
            history -s "$VISUAL $line"
            $VISUAL "${editfiles[@]}"
        fi
    fi
}

bind -x '"\C-o": fzf-edit-opened'

fzf-edit-match() {
    # shellcheck disable=SC2016
    local preview='
        IFS=: read -r file line rest <<< {}
        bat --style=numbers --color=always \
            --highlight-line "$line" \
            --line-range "$((line > 10 ? line-10 : 1)):$((line+30))" \
            "$file" 2>/dev/null \
        || (head -n $((line+30)) "$file" | tail -n +$((line > 10 ? line-10 : 1)))
    '
    mapfile -t selected < <(rg --sort path --line-number --no-heading --follow=to-files '' \
        | fzf --multi --no-sort --exact --reverse $FZF_WIDGET_ARGS --preview "$preview")
    _ref() { [[ $1 =~ ^([^:]+:[0-9]+): ]] && printf '%s' "${BASH_REMATCH[1]}"; }
    if [[ ${#selected[@]} -eq 1 ]]; then
        local ref=$(_ref "${selected[0]}")
        history -s "$VISUAL $ref"
        $VISUAL "$ref"
    elif [[ ${#selected[@]} -gt 1 ]]; then
        printf '%s\n' "${selected[@]}" > /tmp/nvim-comand-qf
        local refs=() s
        for s in "${selected[@]}"; do refs+=("$(_ref "$s")"); done
        history -s "$VISUAL ${refs[*]}"
        $VISUAL -- -q /tmp/nvim-comand-qf -c "copen"
    fi
}

bind -x '"\C-g": fzf-edit-match'

# Fuzzy find in all directory paths for the current source tree.
fzf-cd-path() {
    if [[ -n ${SRCDIR+x} ]]; then
        sel=$( cd $SRCDIR && fd -td | fzf $FZF_WIDGET_ARGS )
        [[ -n $sel ]] && eval "cd $SRCDIR/$sel ; echo $SRCDIR/$sel"
    fi
}
bind -x '"\C-p": fzf-cd-path'
