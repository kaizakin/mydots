package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() {
	// 1. Run CAVA as a subprocess
	// We use the config file we created earlier
	cmd := exec.Command("cava", "-p", os.Getenv("HOME")+"/.config/cava/config_waybar")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error creating stdout pipe:", err)
		return
	}

	if err := cmd.Start(); err != nil {
		fmt.Fprintln(os.Stderr, "Error starting cava:", err)
		return
	}

	// 2. Define our "Bar" characters
	// This maps the 0-7 values from CAVA to Unicode blocks
	bars := []string{" ", "▂", "▃", "▄", "▅", "▆", "▇", "█"}

	// 3. Read CAVA output line by line
	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		line := scanner.Text()
		var visualizer strings.Builder
		
		// Each character in the output is a number representing height
		for _, char := range line {
			// Convert ASCII digit to integer index
			val := int(char - '0')
			if val >= 0 && val < len(bars) {
				visualizer.WriteString(bars[val])
			}
		}
		// Print to stdout for Waybar to consume
		fmt.Println(visualizer.String())
	}
}
