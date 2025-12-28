package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		hostname, _ := os.Hostname()
		log.Println("Hello from browser")
		fmt.Fprintf(w, "Hello from EC2: %s\n", hostname)
	})

	fmt.Println("Server running on port 8080")
	http.ListenAndServe(":8080", nil)
}

// ssh -i go-ec2-ssh-key.pem ec2-user@18.212.235.248
// chmod +x app
// scp -i go-ec2-ssh-key.pem /home/pravinms/Documents/code/go/aws/webserver/app ec2-user@18.212.235.248:/home/ec2-user/
