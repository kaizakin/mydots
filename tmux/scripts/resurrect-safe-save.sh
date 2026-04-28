#!/usr/bin/env bash

set -u

PLUGIN_DIR="${HOME}/.tmux/plugins/tmux-resurrect/scripts"
SAVE_SCRIPT="${PLUGIN_DIR}/save.sh"

tmux_option() {
	local option="$1"
	local default_value="$2"
	local value
	value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
	if [ -n "$value" ]; then
		printf '%s\n' "$value"
	else
		printf '%s\n' "$default_value"
	fi
}

resurrect_dir() {
	local default_dir
	if [ -d "${HOME}/.tmux/resurrect" ]; then
		default_dir="${HOME}/.tmux/resurrect"
	else
		default_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/tmux/resurrect"
	fi

	local configured
	configured="$(tmux_option '@resurrect-dir' "$default_dir")"
	configured="${configured//\$HOME/${HOME}}"
	configured="${configured/#\~/${HOME}}"
	printf '%s\n' "$configured"
}

is_valid_snapshot() {
	local file="$1"
	[ -f "$file" ] || return 1
	[ -s "$file" ] || return 1
	grep -q '^pane' "$file"
}

latest_valid_snapshot() {
	local dir="$1"
	local candidate

	for candidate in "$dir"/tmux_resurrect_*.txt; do
		[ -e "$candidate" ] || continue
		if is_valid_snapshot "$candidate"; then
			printf '%s\n' "$candidate"
		fi
	done | sort | tail -n 1
}

current_last_target() {
	local last_link="$1"
	if [ -L "$last_link" ]; then
		readlink -f "$last_link" 2>/dev/null || true
	elif [ -f "$last_link" ]; then
		printf '%s\n' "$last_link"
	fi
}

main() {
	local dir last_link previous_valid new_target
	dir="$(resurrect_dir)"
	last_link="${dir}/last"
	previous_valid="$(latest_valid_snapshot "$dir")"

	if [ ! -x "$SAVE_SCRIPT" ]; then
		tmux display-message "tmux-resurrect save script not found"
		exit 0
	fi

	"$SAVE_SCRIPT"

	new_target="$(current_last_target "$last_link")"
	if is_valid_snapshot "$new_target"; then
		exit 0
	fi

	if [ -n "$previous_valid" ] && [ "$previous_valid" != "$new_target" ]; then
		ln -fs "$(basename "$previous_valid")" "$last_link"
		tmux display-message "tmux save ignored invalid snapshot; kept $(basename "$previous_valid")"
	else
		rm -f "$last_link"
		tmux display-message "tmux save produced invalid snapshot; auto-restore disabled until next valid save"
	fi
}

main "$@"
