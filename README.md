# Dotfiles

Configs I actually use. The layout is GNU Stow: each folder is a package, and its tree is meant to land on `$HOME` as-is.

I bounce between a niri + Quickshell desktop and some leftover Hyprland / Waybar bits. Don't stow both bars unless you like chaos.

## What's in here

- **niri** — tiling compositor. Keybinds, layout, window rules, startup.
- **quickshell** — the bar and overlay shell (pills, launcher, clipboard, AI usage, etc.).
- **hyprland** / **waybar** — older Hyprland setup. Still here if I need it.
- **zsh** — `.zshrc` with zinit, fzf-tab, and a pile of aliases.
- **nvim** — Neovim, lazy.nvim, the usual.
- **tmux** — `.tmux.conf` plus a couple of resurrect helper scripts.
- **ghostty** / **kitty** — terminals. Ghostty is the one I open.
- **starship** / **ohmyposh** — prompt themes. Pick one.
- **walker** — app launcher theme.
- **zathura** — PDF viewer.
- **fastfetch** — fetch config. `assets/` has screenshots of it.
- **neovide** — GUI Neovim wrapper.
- **herdr** — Herdr client config.
- **wallpapers** — pictures. Quickshell looks for walls in `~/.wall`, so copy or symlink them there.
- **skills** — agent skills I keep next to the configs. Not a Stow package.

## Setup

You want [GNU Stow](https://www.gnu.org/software/stow/) and the programs for the packages you care about. On Arch:

```bash
sudo pacman -S stow niri zsh neovim tmux ghostty
```

Quickshell is separate; install that however you usually do, then:

```bash
git clone https://github.com/kaizakin/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow zsh niri nvim tmux ghostty quickshell starship
```

Stow from the repo root. It will symlink `zsh/.zshrc` → `~/.zshrc`, `niri/.config/niri` → `~/.config/niri`, and so on.

Don't stow a package if that program isn't installed. Conflicts mean something already lives at that path; move it aside and stow again.

First zsh run clones zinit into `~/.local/share/zinit`. First nvim run installs plugins via lazy.

Wallpapers:

```bash
mkdir -p ~/.wall
cp wallpapers/* ~/.wall/
```

That's it. Edit in this repo, the symlinks update themselves.
