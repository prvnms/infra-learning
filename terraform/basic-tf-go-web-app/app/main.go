package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Println("Hello from browser")
		fmt.Fprintln(w, "Hello from my first EC2 Go app!")
	})

	fmt.Println("Server running on port 8080")
	http.ListenAndServe(":8080", nil)
}

// scp -i go-ec2-ssh-key.pem /home/pravinms/Documents/code/go/aws/webserver/app ec2-user@18.212.235.248:/home/ec2-user/
