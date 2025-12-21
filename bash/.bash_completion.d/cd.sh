# Prefer local matches
_my_cd () { CDPATH='' _cd "$@"; if [[ -z $COMPREPLY ]]; then _cd "$@"; fi;}
[[ -n $(type -t _cd) ]] && complete -F _my_cd -o nospace cd
