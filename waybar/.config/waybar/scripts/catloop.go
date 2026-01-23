package main

import(
	"bufio"
	"fmt"
	"strings"
	"strconv"
	"time"
	"os"
)

const(
	sleepAfter = 4
	minSpeed = 0.4
)

var (
	awakeFrames = []string{"A", "B", "C", "D", "E"}
	sleepFrames = []string{"G", "H", "I", "J", "K", "L", "M", "N"}
)

type CPUStat struct{
	active int64
	total int64
}

func readCPU() (CPUStat, error){
	file, err := os.Open("/proc/stat")
	
	if err != nil{
		return CPUStat{}, err
	}

	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan(){
		line := scanner.Text()
		if strings.HasPrefix(line, "cpu ") {
			fields := strings.Fields(line)

			// fields[0] = "cpu"
			user, _ := strconv.ParseInt(fields[1], 10, 64)
			nice, _ := strconv.ParseInt(fields[2], 10, 64)
			sys, _ := strconv.ParseInt(fields[3], 10, 64)
			idle, _ := strconv.ParseInt(fields[4], 10, 64)

			active := user + nice + sys
			total := active + idle

			return CPUStat{active, total}, nil
		}
	}

	return CPUStat{}, fmt.Errorf("cpu stats not found")
}

func main() {
	prev, err := readCPU()
	if err != nil{
		panic(err)
	}

	sleepcounter := 0

	for {
		curr, err := readCPU()

		// if error jump for the next loop
		if err != nil{
			continue
		}

		deltaActive := curr.active - prev.active
		deltaTotal := curr.total - prev.total

		var usage float64
		if deltaTotal <= 0 || deltaActive < 0 {
			usage = 0.0
		} else {
			usage = float64(deltaActive) / float64(deltaTotal)
		}

		// Speed Calculation
		speed := 1.0 / (4.0 + (usage * 100.0))

		// Clamp speed
		if speed < 0.03 {
			speed = 0.03
		}
		if speed > 0.15 {
			speed = 0.15
		}
		// sleep logic
		if usage < 0.02 {
			sleepcounter++
		} else {
			sleepcounter = 0
		}

		if sleepcounter >= sleepAfter {
			for _, frame := range sleepFrames {
				fmt.Println(frame)
				time.Sleep(time.Duration(speed * float64(time.Second)))
			}
		} else {
			for _, frame := range awakeFrames {
				fmt.Println(frame)
				time.Sleep(time.Duration(speed * float64(time.Second)))
			}
		}

		prev = curr
	}
}