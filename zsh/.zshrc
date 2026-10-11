[[ -r "${ZDOTDIR:-$HOME}/.zshenv" ]] && source "${ZDOTDIR:-$HOME}/.zshenv"
[[ -o interactive ]] && fastfetch

# ------------------------------------------------------------
# Zsh: fast, fuzzy, and a little bit pretty.
# ------------------------------------------------------------

[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zen0x/defaults.sh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zen0x/defaults.sh"
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zen0x/fzf-theme.zsh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zen0x/fzf-theme.zsh"

export EDITOR="${EDITOR:-micro}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="-R --use-color -Dd+r -Du+b"

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt inc_append_history
setopt share_history

# Completion cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Friendlier completion
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format ''
# A space hides labels while retaining the argument fzf-tab passes to compadd -x.
zstyle ':completion:*:messages' format ' '
zstyle ':completion:*:warnings' format ' '

# Useful shell behavior
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt interactive_comments
setopt no_beep
setopt prompt_subst
setopt auto_list
setopt auto_menu
setopt complete_in_word
setopt always_to_end
setopt glob_dots
setopt no_nomatch

# Keybinds
bindkey -e

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^W' backward-kill-word
bindkey '^L' clear-screen
bindkey '^[[3~' delete-char

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME/.git" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting

# FZF
if [[ -t 0 ]] && command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS="
    --height=40%
    --layout=reverse
    --border=rounded
    --prompt='  '
    --pointer=''
    --marker=''
    ${ZEN0X_FZF_COLOR_OPTS:-}
  "

  if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
  else
    source <(fzf --zsh)
  fi
fi

# FZF Tab completion without preview pane
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-flags \
  --height=40% \
  --layout=reverse \
  --border=rounded \
  --no-preview

zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-preview ''

zinit light Aloxaf/fzf-tab

# Zoxide
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Starship
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Aliases: basics
alias c='clear'
alias reload='source ~/.zshrc'
alias please='sudo'

# Aliases: navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias conf='cd ~/.config'
alias dots='cd ~/dotfiles'
alias repos='cd ~/Repos'
alias dl='cd ~/Downloads'

# Aliases: listing
if command -v eza >/dev/null 2>&1; then
  alias l='eza --icons --group-directories-first'
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --group-directories-first --git'
  alias la='eza -A --icons --group-directories-first'
  alias lt='eza --tree --icons --level=2'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah'
  alias la='ls -A'
fi

# Aliases: safer file operations
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias grep='grep --color=auto'
alias vim='nvim'
command -v bat >/dev/null 2>&1 && alias cat='bat'
alias codex='codex "/caveman ultra"'

# Aliases: Git
alias gs='git status --short'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate --all'



# Extract archives
extract() {
  [[ -f "$1" ]] || {
    echo "File not found: $1"
    return 1
  }

  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.tar.zst) tar --zstd -xf "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.7z)      7z x "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.xz)      unxz "$1" ;;
    *.zst)     unzstd "$1" ;;
    *)         echo "Cannot extract: $1" ;;
  esac
}

typeset -U path
path=("$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.spicetify" $path)

# Unity CLI
case ":${PATH}:" in *:"$HOME/.local/bin":*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
