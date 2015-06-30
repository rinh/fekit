#!/bin/bash
# fekit command completion script
#
# Installation: fekit completion >> ~/.bashrc  (or ~/.zshrc)
# Or, maybe: fekit completion > /usr/local/etc/bash_completion.d/fekit
#

COMP_WORDBREAKS=${COMP_WORDBREAKS/=/}
COMP_WORDBREAKS=${COMP_WORDBREAKS/@/}
export COMP_WORDBREAKS

if type complete &>/dev/null; then
  _fekit_completion () {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           fekit completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F _fekit_completion fekit
elif type compdef &>/dev/null; then
  _fekit_completion() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 fekit completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef _fekit_completion fekit
elif type compctl &>/dev/null; then
  _fekit_completion () {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       fekit completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K _fekit_completion fekit
fi
