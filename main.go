package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

type AppHealth struct {
	FrontendStatus string    `json:"frontend_status"`
	Uptime         string    `json:"uptime"`
	Timestamp      time.Time `json:"timestamp"`
	CommitHash     string    `json:"commit_hash"`
}

const frontendURL = "http://localhost:5173"

var (
	startTime  time.Time
	commitHash string
)

func main() {
	startTime = time.Now()

	PORT := os.Getenv("PORT")
	if PORT == "" {
		PORT = "4000"
		log.Printf("PORT not set. Using default port %v", PORT)
	}

	var err error
	commitHash, err = getCommitHash()
	if err != nil {
		log.Printf("Failed to get commit hash: %v", err)
		commitHash = "unknown"
	}

	// Not Necessary for this scenario, but included for demonstration purposes
	// go checkFrontendPeriodically()

	app := fiber.New()

	// Set CORS before calling the Route
	// I've used CORS plenty, but never spent 20min banging my head just for it
	// to be 1 line below the Handler...
	app.Use(cors.New())

	app.Get("/health", checkHealth)

	log.Printf("Server running on port %v", PORT)
	if err := app.Listen(":" + PORT); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func checkHealth(c *fiber.Ctx) error {
	log.Println("Received health check request")
	currentStatus := checkFrontendStatus()
	health := AppHealth{
		FrontendStatus: currentStatus,
		Uptime:         formatUptime(time.Since(startTime)),
		Timestamp:      time.Now(),
		CommitHash:     commitHash,
	}

	return c.Status(fiber.StatusOK).JSON(health)
}

func checkFrontendStatus() string {
	status := "healthy"
	resp, err := http.Get(frontendURL)
	if err != nil || resp.StatusCode != http.StatusOK {
		status = "down"
		log.Printf("Frontend disconnected: %v", err)
	}
	if resp != nil {
		resp.Body.Close()
	}
	return status
}

func getCommitHash() (string, error) {
	url := "https://api.github.com/repos/mleager/health-check-backend/commits/main"
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("Failed to get commit hash: %v", err)
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Failed to read commit hash response: %v", err)
		return "", err
	}

	var commit struct {
		SHA string `json:"sha"`
	}

	err = json.Unmarshal(body, &commit)
	if err != nil {
		log.Printf("Failed to unmarshal commit hash response: %v", err)
		return "", err
	}

	if commit.SHA == "" {
		return "", fmt.Errorf("no commits found in response")
	}

	return commit.SHA, nil
}

func formatUptime(d time.Duration) string {
	d = d.Round(time.Second)
	h := d / time.Hour
	d -= h * time.Hour
	m := d / time.Minute
	d -= m * time.Minute
	s := d / time.Second

	if h > 0 {
		return fmt.Sprintf("%dh %dmin %dsec", h, m, s)
	} else if m > 0 {
		return fmt.Sprintf("%dmin %dsec", m, s)
	}
	return fmt.Sprintf("%dsec", s)
}

// Not Necessary for this scenario, but included for demonstration purposes
// func checkFrontendPeriodically() {
// 	ticker := time.NewTicker(30 * time.Second)
// 	defer ticker.Stop()
//
// 	for range ticker.C {
// 		status := checkFrontendStatus()
// 		log.Printf("Frontend status check: %s", status)
// 	}
// }
