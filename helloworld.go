package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"

	pb "github.com/izumiya/knative-ko/genproto"
	"google.golang.org/grpc"
)

type server struct {
	pb.UnimplementedGreeterServer
}

// grpcurl --proto helloworld.proto --plaintext -d '{"name": "WORLD"}' localhost:8080 helloworld.Greeter/SayHello
func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	log.Printf("Received: %v", in.GetName())
	return &pb.HelloReply{Message: "Hello " + in.GetName()}, nil
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterGreeterServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
