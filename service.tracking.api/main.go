package main

import (
	"fmt"
	"net/http"

	"github.com/gorilla/pat"
)

func main() {
	r := pat.New()

	r.Get("/hello", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello World\n")
	})

	http.ListenAndServe(":8080", r)
}
