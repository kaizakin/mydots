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

# enable colors to ls command
alias ls='ls --color'

# add colors to the completions as well
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"


# add zoxide to zsh
eval "$(zoxide init zsh)"

# uncomment this line to alias zoxide to cd if you cannot overcome your muscle memory.
# eval "$(zoxide init --cmd cd zsh)"

# enable previews to work with zoxide as well
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# automatically load completions
autoload -U compinit && compinit

# Zinit re-applies certain plugin actions that depend on your current directory context
# zinit uses this to replay all cached completions
# this needs to be placed immediately next to compinit initialization
zinit cdreplay -q

# install oh-my-posh using curl
# add oh-my-posh to zsh add the installation directory to path before sourcing it
export PATH=$PATH:/home/karthik/.local/bin
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

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
alias gcm='git commit -m'
alias gs='git status'
alias gp='git push'
alias ga='git add'

# fzf and open that in nvim 
alias fzfnvim='nvim $(fzf -m --preview="bat --color=always {}")'

# tools
alias lzg='lazygit'
alias lzc='lazycommit'

# config files
alias kittyconf='vim ~/.config/kitty/kitty.conf'
alias nvimconf='nvim ~/.config/nvim/'
alias ompconf='vim ~/.config/ohmyposh/zen.toml'

# add dotfiles folder alias
alias dots='z ~/mydots/'

# pnpm
export PNPM_HOME="/home/karthik/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end



