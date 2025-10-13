# Uncomment the following line to disable colors in ls.
DISABLE_LS_COLORS="true"


# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="%F{yellow}...%f"

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

# pnpm
export PNPM_HOME="/home/karthik/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

