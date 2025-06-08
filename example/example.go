package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"time"
)

var startTime time.Time

type HealthResponse struct {
	FrontendConnected bool   `json:"frontendConnected"`
	BackendUptime     string `json:"backendUptime"`
	Timestamp         string `json:"timestamp"`
	CommitHash        string `json:"gitCommitHash"`
}

func getCommitHash() string {
	cmd := exec.Command("git", "rev-parse", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		log.Printf("Error getting git commit hash: %v", err)
		return "unknown"
	}
	return string(output[:len(output)-1])
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := HealthResponse{
		FrontendConnected: true, // placeholder
		BackendUptime:     time.Since(startTime).String(),
		Timestamp:         time.Now().Format(time.RFC3339),
		CommitHash:        getCommitHash(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	json.NewEncoder(w).Encode(response)
}

func main() {
	startTime = time.Now()

	http.HandleFunc("/health", healthHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "4000"
	}

	fmt.Printf("Server starting on port %s...\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
