package main

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"
)

var intervals = []int{1, 2, 5, 10, 15, 20, 30, 45, 60}

func main() {
	intervalMin := 20
	running := false
	var remaining int

	fmt.Println("\033[1;31m╔══════════════════════════════════════╗\033[0m")
	fmt.Println("\033[1;31m║          RETINA GUARD                ║\033[0m")
	fmt.Println("\033[1;31m╚══════════════════════════════════════╝\033[0m")
	fmt.Println()
	fmt.Println("  Protect your eyes — 20-20-20 rule")
	fmt.Println()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	inputCh := make(chan string)
	go readInput(inputCh)

	printMenu(intervalMin)

	ticker := time.NewTicker(1 * time.Second)
	ticker.Stop()

	for {
		select {
		case <-sigCh:
			fmt.Println("\n\033[90mGoodbye!\033[0m")
			return
		case input := <-inputCh:
			switch input {
			case "s", "S", "start":
				if !running {
					running = true
					remaining = intervalMin * 60
					ticker = time.NewTicker(1 * time.Second)
					fmt.Printf("\n\033[32m▶ Protection started\033[0m — interval: %d min\n\n", intervalMin)
					printCountdown(remaining)
				}
			case "x", "X", "stop":
				if running {
					running = false
					ticker.Stop()
					fmt.Println("\n\033[33m■ Protection stopped\033[0m")
					fmt.Println()
				}
			case "q", "Q", "quit":
				fmt.Println("\n\033[90mGoodbye!\033[0m")
				return
			case "h", "H", "help":
				printMenu(intervalMin)
			default:
				if !running {
					for _, v := range intervals {
						if fmt.Sprintf("%d", v) == input {
							intervalMin = v
							fmt.Printf("\n\033[36mInterval set to %d min\033[0m\n\n", intervalMin)
							break
						}
					}
				}
			}
		case <-ticker.C:
			if running {
				remaining--
				printCountdown(remaining)
				if remaining <= 0 {
					remaining = intervalMin * 60
					showNotification()
					playSound()
					fmt.Println("\n\033[1;33m  ⏰ TIME TO LOOK AWAY!\033[0m")
					fmt.Println("  Look at something 20 feet away for 20 seconds.")
					fmt.Println()
				}
			}
		}
	}
}

func printCountdown(sec int) {
	m := sec / 60
	s := sec % 60
	fmt.Printf("\r\033[36m  Next break in \033[1m%02d:%02d\033[0m  ", m, s)
}

func printMenu(interval int) {
	fmt.Println("  \033[1mCommands:\033[0m")
	fmt.Println("    \033[32ms\033[0m / start    — Start protection")
	fmt.Println("    \033[33mx\033[0m / stop     — Stop protection")
	fmt.Printf("    \033[36m1-60\033[0m          — Set interval (current: %d min)\n", interval)
	fmt.Println("    \033[90mq\033[0m / quit     — Exit")
	fmt.Println("    \033[90mh\033[0m / help     — Show this menu")
	fmt.Println()
}

func readInput(ch chan string) {
	buf := make([]byte, 128)
	for {
		n, err := os.Stdin.Read(buf)
		if err != nil || n == 0 {
			continue
		}
		input := string(buf[:n])
		// trim newline/spaces
		for len(input) > 0 && (input[len(input)-1] == '\n' || input[len(input)-1] == '\r' || input[len(input)-1] == ' ') {
			input = input[:len(input)-1]
		}
		if len(input) > 0 {
			ch <- input
		}
	}
}

func showNotification() {
	title := "Retina Guard"
	msg := "Look at something 20 feet away for 20 seconds."
	script := fmt.Sprintf(`display notification "%s" with title "%s" sound name "Glass"`, msg, title)
	cmd := exec.Command("osascript", "-e", script)
	cmd.Run()
}

func playSound() {
	cmd := exec.Command("afplay", "/System/Library/Sounds/Glass.aiff")
	cmd.Run()
}
