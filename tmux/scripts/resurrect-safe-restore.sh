#!/usr/bin/env bash

set -u

PLUGIN_DIR="${HOME}/.tmux/plugins/tmux-resurrect/scripts"
RESTORE_SCRIPT="${PLUGIN_DIR}/restore.sh"

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

main() {
	local dir last_link target valid_target
	dir="$(resurrect_dir)"
	last_link="${dir}/last"

	if [ ! -x "$RESTORE_SCRIPT" ]; then
		tmux display-message "tmux-resurrect restore script not found"
		exit 0
	fi

	target=""
	if [ -L "$last_link" ]; then
		target="$(readlink -f "$last_link" 2>/dev/null || true)"
	elif [ -f "$last_link" ]; then
		target="$last_link"
	fi

	if ! is_valid_snapshot "$target"; then
		valid_target="$(latest_valid_snapshot "$dir")"
		if [ -n "$valid_target" ]; then
			ln -fs "$(basename "$valid_target")" "$last_link"
			tmux display-message "tmux restore healed invalid snapshot; using $(basename "$valid_target")"
		else
			tmux display-message "tmux restore skipped: no valid resurrect snapshot"
			exit 0
		fi
	fi

	exec "$RESTORE_SCRIPT"
}

main "$@"
