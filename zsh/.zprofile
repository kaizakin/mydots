FASTFETCH_LOCK="/tmp/kitty_fastfetch_$(id -u)"

if [[ ! -f "$FASTFETCH_LOCK" ]]; then
  fastfetch
  touch "$FASTFETCH_LOCK"
fi

export PATH="/home/karthik/.local/share/solana/install/active_release/bin:$PATH"
