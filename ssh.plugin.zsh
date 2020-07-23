#!/usr/bin/env zsh

hosts=()
if [ -d ${ZDOTDIR}/cache ]; then
  local CACHE_FILE="${ZDOTDIR}/cache/ssh-hosts.zsh"
else
  local CACHE_FILE="${TMPDIR:-/tmp}/zsh-${UID}/ssh-hosts.zsh"
fi

if [[ -f ~/.ssh/config ]]; then
  if \
    [[ "$CACHE_FILE" -nt "$HOME/.ssh/config" ]] && \
    [[ "$CACHE_FILE" -nt "$HOME/.ssh/known_hosts" ]]; then
    source "$CACHE_FILE"
  else
    mkdir -p "${CACHE_FILE:h}"# # host completion
    [[ -r ~/.ssh/config ]] && local _ssh_config_hosts=(${${(s: :)${(ps:\t:)${${(@M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }}}:#*[*?]*}) || local _ssh_config_hosts=()
    [[ -r ~/.ssh/known_hosts ]] && local _ssh_hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}) || local _ssh_hosts=()
    [[ -r /etc/hosts ]] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()
    hosts=(
      "$_ssh_config_hosts[@]"
      "$_ssh_hosts[@]"
      "$_etc_hosts[@]"
    )
    typeset -p hosts >! "$CACHE_FILE" 2> /dev/null
    zcompile "$CACHE_FILE"
  fi
fi

if [ -r ${ZDOTDIR}/users.txt ]; then
  local _users=( "${(@f)"$(<${ZDOTDIR}/users.txt)"}" )
  # local users=("$_users[@]")
  zstyle ':completion:*:(ssh|scp|sshfs|mosh):*:users' users $_users
fi

zstyle ':completion:*:hosts' hosts $hosts

zstyle ':completion:*:(ssh|scp|sshfs|mosh):*' sort false
zstyle ':completion:*:(ssh|scp|sshfs|mosh):*' format ' %F{yellow}-- %d --%f'

zstyle ':completion:*:(ssh|scp|sshfs|mosh):*' group-name ''
zstyle ':completion:*:(ssh|scp|sshfs|mosh):*' verbose yes

zstyle ':completion:*:(scp|rsync|sshfs):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync|sshfs):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr

zstyle ':completion:*:(ssh|mosh):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(ssh|mosh):*' group-order users hosts-domain hosts-host users hosts-ipaddr

zstyle ':completion:*:(ssh|scp|sshfs|mosh):*:users' ignored-patterns '_*'
zstyle ':completion:*:(ssh|scp|sshfs|mosh):*:hosts-host' ignored-patterns '*(.|:)*' loopback localhost broadcasthost 'ip6-*'
zstyle ':completion:*:(ssh|scp|sshfs|mosh):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|sshfs|mosh):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.*' '255.255.255.255' '::1' 'fe80::*' 'ff02::*'
