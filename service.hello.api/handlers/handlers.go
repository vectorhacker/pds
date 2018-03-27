package handlers

import (
	"fmt"
	"log"
	"net/http"
	"os"

	pb "github.com/vectorhacker/pds/service.hello/proto"
)

var errLog = log.New(os.Stderr, "error: ", log.Lshortfile)

func HandleHello(w http.ResponseWriter, r *http.Request) {
	log.Println("Hello api started")

	hello := r.Context().Value("helloClient").(pb.HelloClient)
	name := r.URL.Query().Get(":name")

	res, err := hello.Greet(r.Context(), &pb.Request{
		Name: name,
	})

	if err != nil {
		errLog.Printf("%##v\n", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, res.Greeting)
	w.WriteHeader(http.StatusOK)
}
