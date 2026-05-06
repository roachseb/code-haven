package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

type HealthResponse struct {
	Status string `json:"status"`
}

type MessageResponse struct {
	Message string `json:"message"`
	Version string `json:"version"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(HealthResponse{Status: "healthy"})
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(MessageResponse{
		Message: "Hello from Code Haven Go service!",
		Version: "1.0.0",
	})
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", rootHandler)
	http.HandleFunc("/health", healthHandler)

	fmt.Printf("🚀 Server starting on port %s\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		fmt.Fprintf(os.Stderr, "Server failed: %v\n", err)
		os.Exit(1)
	}
}
