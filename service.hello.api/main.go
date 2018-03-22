package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/pat"
	"github.com/spf13/viper"
	"github.com/vectorhacker/pds/service.hello.api/handlers"
	hello "github.com/vectorhacker/pds/service.hello/proto"
	"google.golang.org/grpc"
)

var router = pat.New()

func init() {
	viper.SetDefault("host", "0.0.0.0")
	viper.SetDefault("port", "5000")
	viper.SetDefault("helloServiceAddress", "localhost:4140")
	viper.AutomaticEnv()

	router.Get("/hello/{name}", handlers.HandleHello)
}

func main() {
	host := viper.GetString("host")
	port := viper.GetString("port")

	cc, err := grpc.Dial(viper.GetString("helloServiceAddress"), grpc.WithInsecure())
	if err != nil {
		log.Fatal(err)
	}

	client := hello.NewHelloClient(cc)

	router.Use(func(h http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := r.Context()
			ctx = context.WithValue(ctx, "hello_client", client)
			r = r.WithContext(ctx)

			h.ServeHTTP(w, r)
		})
	})

	http.ListenAndServe(fmt.Sprintf("%s:%s", host, port), router)
}
