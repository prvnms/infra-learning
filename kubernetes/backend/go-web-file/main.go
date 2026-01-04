package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"
)

const (
	maxRequestSize  = 1 << 20 // 1MB
	shutdownTimeout = 30 * time.Second
	maxLines        = 1000
)

var (
	dataPath = "/app/data"
	filePath = dataPath + "/data.txt"
)

type WriteRequest struct {
	Content string `json:"content"`
}

type ReadAllResponse struct {
	Lines []string `json:"lines"`
	Total int      `json:"total"`
}

type App struct {
	mu sync.RWMutex
}

func main() {
	log.Println("---HELLO---")

	dataPath = os.Getenv("DATA_PATH")
	if dataPath == "" {
		dataPath = "./data"
	}
	filePath = dataPath + "/data.txt"
	if err := os.MkdirAll(dataPath, 0755); err != nil {
		log.Fatal("failed to create data directory:", err)
	}

	app := &App{}

	mux := http.NewServeMux()
	mux.HandleFunc("/write", app.writeFile)
	mux.HandleFunc("/read", app.readLatest)
	mux.HandleFunc("/readall", app.readAll)
	mux.HandleFunc("/health", healthCheck)

	handler := loggingMiddleware(recoveryMiddleware(mux))

	server := &http.Server{
		Addr:              ":8080",
		Handler:           handler,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    1 << 20,
		ReadHeaderTimeout: 5 * time.Second,
	}

	// shutdown
	go func() {
		log.Println("srv listening on :8080")
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal("server error:", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("srv shuttingdown...")

	ctx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatal("srv shutdown:", err)
	}

	log.Println("---BYE---")
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.RequestURI, time.Since(start))
	})
}

func recoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("panic: %v", err)
				http.Error(w, "internal server error", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

/*
TESTING COMMANDS:

# Write data
curl -X POST http://localhost:8080/write \
  -H "Content-Type: application/json" \
  -d '{"content":"hello from curl"}'

# Read latest
curl http://localhost:8080/read

# Read all entries
curl http://localhost:8080/readall

# Health check
curl http://localhost:8080/health


DOCKER COMMANDS:

docker build -t go-web-file:v3 .
docker images | grep go-web-file

# Run locally
docker run -p 8080:8080 go-web-file:v3

AWS ECR:

aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  880265510348.dkr.ecr.us-east-1.amazonaws.com

docker tag go-web-file:v3 \
  880265510348.dkr.ecr.us-east-1.amazonaws.com/go-web-file:v3

docker push 880265510348.dkr.ecr.us-east-1.amazonaws.com/go-web-file:v3
*/
