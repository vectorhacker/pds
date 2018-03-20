package main

import (
	"context"
	"fmt"
	"net"

	pb "github.com/vectorhacker/pds/service.tracking.api/proto"
	"google.golang.org/grpc"
)

type trackingServer struct {
}

func (*trackingServer) Track(ctx context.Context, r *pb.Request) (*pb.Response, error) {
	return &pb.Response{}, nil
}

func newServer() *trackingServer {
	s := &trackingServer{}
	return s
}

func main() {
	lis, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%d", 5000))
	if err != nil {
		panic(err)
	}

	var opts []grpc.ServerOption
	grpcServer := grpc.NewServer(opts...)
	pb.RegisterTrackingServer(grpcServer, newServer())
	grpcServer.Serve(lis)
}
