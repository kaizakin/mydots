#!/bin/zsh

killall -9 swaync
killall -9 waybar

swaync &
waybar &
