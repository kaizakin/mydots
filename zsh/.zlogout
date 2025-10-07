FASTFETCH_LOCK="/tmp/kitty_fastfetch_$(id -u)"
if [[ -f "$FASTFETCH_LOCK" ]]; then
  rm -f "$FASTFETCH_LOCK"
fi


