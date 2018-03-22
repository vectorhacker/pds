package handlers_test

import (
	"bytes"
	"context"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	pb "github.com/vectorhacker/pds/service.hello/proto"
	"google.golang.org/grpc"

	"github.com/vectorhacker/pds/service.hello.api/handlers"
)

type c struct{}

func (c) Greet(ctx context.Context, r *pb.Request, opts ...grpc.CallOption) (*pb.Response, error) {
	return &pb.Response{
		Greeting: "Hello " + r.Name,
	}, nil
}

func TestHandleHello(t *testing.T) {
	expectedBody := "Hello victor"
	client := &c{}

	w := httptest.NewRecorder()
	r := httptest.NewRequest(http.MethodGet, "/victor", nil)
	q := &url.Values{}
	q.Add(":name", "victor")
	r.URL.RawQuery = q.Encode()

	ctx := context.Background()
	ctx = context.WithValue(ctx, "hello_client", client)

	r = r.WithContext(ctx)

	handlers.HandleHello(w, r)

	resp := w.Result()
	body, _ := ioutil.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		t.Errorf("expected status %d got %d", http.StatusOK, resp.StatusCode)
	}

	if !bytes.Contains(body, []byte(expectedBody)) {
		t.Errorf("expected body %s got %s", expectedBody, body)
	}
}
