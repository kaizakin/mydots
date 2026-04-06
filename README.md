# mydots

A collection of my personal configuration files, managed with **GNU Stow**. Each configuration is modular and can be used independently.

- **Window Manager:** [Hyprland](https://github.com/kaizakin/hyprland)
- **Terminal:** [Ghostty](https://github.com/kaizakin/ghostty) / [Kitty](https://github.com/kaizakin/kitty)
- **Text Editor:** [Neovim](https://github.com/kaizakin/nvim)
- **Shell:** [Zsh](https://github.com/kaizakin/zsh) + Oh My Posh
- **File Manager:** [Yazi](https://github.com/kaizakin/yazi)
- **Bar:** [Waybar](https://github.com/kaizakin/waybar)

---

## 🖼️ Gallery

<table>
  <tr>
    <td width="50%"><img src="assets/neovim.png" alt="Neovim Preview" /></td>
    <td width="50%"><img src="assets/fastfetch.png" alt="Fastfetch Preview" /></td>
  </tr>
  <tr>
    <td colspan="2"><img src="assets/waybar.png" alt="Waybar Preview" width="100%"/></td>
  </tr>
</table>

---

### Installation

This setup uses **GNU Stow** for symlinking.

### Prerequisites

Ensure `stow` is installed on your system:

```bash
# Arch Linux
sudo pacman -S stow
# Debian/Ubuntu
sudo apt install stow
```

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/kaizakin/mydots
   cd mydots
   ```
2. Apply a configuration:
   ```bash
   stow [config_name]
   ```
   _Example: `stow nvim`_

---

For convenience, each configuration is maintained as a separate repository. This allows to pick and choose exactly what you want without cloning the entire collection.

| Component    | Repository Link                                           |
| :----------- | :-------------------------------------------------------- |
| **Neovim**   | [kaizakin/nvim](https://github.com/kaizakin/nvim)         |
| **Hyprland** | [kaizakin/hyprland](https://github.com/kaizakin/hyprland) |
| **Waybar**   | [kaizakin/waybar](https://github.com/kaizakin/waybar)     |
| **Ghostty**  | [kaizakin/ghostty](https://github.com/kaizakin/ghostty)   |
| **Kitty**    | [kaizakin/kitty](https://github.com/kaizakin/kitty)       |
| **Zsh**      | [kaizakin/zsh](https://github.com/kaizakin/zsh)           |
| **Yazi**     | [kaizakin/yazi](https://github.com/kaizakin/yazi)         |
| **Tmux**     | [kaizakin/tmux](https://github.com/kaizakin/tmux)         |

---

> [!TIP]
> Each folder in this repository mirrors the structure expected by `stow`. For example, `nvim` contains a `.config/nvim` directory which will be symlinked to `~/.config/nvim`.
