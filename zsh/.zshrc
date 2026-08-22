# the directory to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"


# add fzf integration to zsh
# this enables quite a lot of things including fuzzy finding in reverse search
# enable this using ctrl + r (remember it like ctrl reverse search) and once entered fzf you can use ctrl p and n as well
eval "$(fzf --zsh)"

# add zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# bring fzf to completions menu
zinit light Aloxaf/fzf-tab
zstyle ':completion:*' menu no # disable default zsh shell completions so that our fzf can work nicer.

# enable preview of our directories right in the completions menu
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# add git plugin to zinit from ohmyzsh repository this provides some aliases
# OMZP refers to ohmyzsh plugin repo
zinit snippet OMZP::git

# sudo plugin pres esc twice to prepend the last executed and current command with sudo
zinit snippet OMZP::sudo

# gives some aliases to for arch-based systems
zinit snippet OMZP::archlinux

# add an bunch of aliases for aws cli commands
# zinit snippet OMZP::aws

# adds a bunch of aliases and autocompletions for kubectl commands (kubernetes)
zinit snippet OMZP::kubectl

# kubernetes cluster  context switcher
zinit snippet OMZP::kubectx

# gives you a nice description of where this command can be found instead of a bare command not found error on false commands
zinit snippet OMZP::command-not-found

# set keybindings to emacs-mode
bindkey -e
# ctrl + f to accecpt a autosuggestion
# ctrl + b for moving backwards through the prompt
# ctrl + f for moving forward
# ctrl + a to jump to the start of the prompt
# etrl + e to jump to the end
# ctrl + p to cycle back to the past executed commands think like ctrl previous
# ctrl + n to cycle forward the history think like ctrl next 


# command  History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# search through the history based on what is currently present in the prompt 
# for ex: writing curl and pressing ctrl + p and ctrl + n cycles through the already exectuted curl commands instead of the whole history
# however if nothing is written on the prompt and pressing ctrl+p ctrl+n does the normal job as always
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# jump words using ctrl arrow
bindkey "\e[1;5C" forward-word
bindkey "\e[1;5D" backward-word


# in-casesensitive auto-completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# add colors to the completions as well
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"


# add zoxide to zsh
eval "$(zoxide init zsh)"

# homebrew
# eval "$(brew shellenv)"

# uncomment this line to alias zoxide to cd if you cannot overcome your muscle memory.
# eval "$(zoxide init --cmd cd zsh)"

# enable previews to work with zoxide as well
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# automatically load completions
fpath=(~/.zsh/completions $fpath) # load completion files
autoload -U compinit && compinit

# Zinit re-applies certain plugin actions that depend on your current directory context
# zinit uses this to replay all cached completions
# this needs to be placed immediately next to compinit initialization
zinit cdreplay -q

# install oh-my-posh using curl
# add oh-my-posh to zsh add the installation directory to path before sourcing it
export PATH=$PATH:/home/karthik/.local/bin
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

# use starship for a change
# export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
# eval "$(starship init zsh)"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="%F{white}...%f"

# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
 else
   export EDITOR='nvim'
 fi

# Example aliases
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

# git aliases custom made by karthik
alias gcm='git commit -s -m'
alias gs='git status'
alias gp='git push'
alias ga='git add'
alias h='herdr'

# fzf and open that in nvim 
alias fzfnvim='nvim $(fzf -m --preview="bat --color=always {}")'

# tools
alias lzg='lazygit'
alias lzc='lazycommit'
alias h='herdr'
alias n='neovide'
alias agy='agy --dangerously-skip-permissions'

alias ls='eza --icons=auto'
alias cat='bat'


# config files
alias kittyconf='neovide ~/.config/kitty/kitty.conf'
alias nvimconf='neovide ~/.config/nvim/'
alias ompconf='neovide ~/.config/ohmyposh/zen.toml'
alias tmuxconf='neovide ~/.tmux.conf'
alias ghosttyconf='neovide ~/.config/ghostty'

# add dotfiles folder alias
alias dots='nvim ~/dotfiles/'

# lazy aliases
# alias deidocker='sudo systemctl start docker'
# alias resetnetwork='sudo systemctl restart NetworkManager'
alias k='kubectl'
alias kload='kind load docker-image'

# lazy functions
lazypush() {
  git add .
  git commit -m "$*"
  git push origin main
}

stty -ixon # stop ctrl + s from freezing terminal so tmux prefix works properly


# pnpm
export PNPM_HOME="/home/karthik/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


export PATH="$PATH:$HOME/.local/bin"

# export env vars for hadooop
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# export path var for kubectl krew plugin
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"


# bun completions
[ -s "/home/karthik/.bun/_bun" ] && source "/home/karthik/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# yazi configuration to open the last exited folder path in terminal
# to use this use y to open yazi instead of yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


# lazy dir create and cd
mkcd () {
  mkdir -p "$1" && cd "$1"
}

# Add Go binaries to the system path
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
# source /usr/share/nvm/init-nvm.sh
export LD_LIBRARY_PATH=~/Qt/6.11.0/gcc_64/lib:$LD_LIBRARY_PATH

# Create a Tmux Dev Layout with editor, ai, and terminal
# Usage: tdl <c|cx|codex|other_ai> [<second_ai>]
tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }

  local current_dir="${PWD}"
  local editor_pane ai_pane ai2_pane
  local ai="$1"
  local ai2="$2"

  # Use TMUX_PANE for the pane we're running in (stable even if active window changes)
  editor_pane="$TMUX_PANE"

  # Name the current window after the base directory name
  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  # Split window vertically - top 85%, bottom 15% (target editor pane explicitly)
  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"

  # Split editor pane horizontally - AI on right 30% (capture new pane ID directly)
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  # If second AI provided, split the AI pane vertically
  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  # Run ai in the right pane
  tmux send-keys -t "$ai_pane" "$ai" C-m

  # Run nvim in the left pane
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m

  # Select the nvim pane for focus
  tmux select-pane -t "$editor_pane"
}

aur-install() {
  local pkg
  # Pulls package descriptions, pipes into fzf with a preview window showing package details
  pkg=$(yay -Slq | fzf \
    --prompt="AUR/Repo > " \
    --preview="yay -Si {} || pacman -Si {}" \
    --preview-window=right:60%:wrap \
    --height=90%)

  if [ -n "$pkg" ]; then
    yay -S "$pkg"
  fi
}

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<


# Added by Antigravity CLI installer
export PATH="/home/karthik/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
