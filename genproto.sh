#!/bin/bash -e

protodir=.

mkdir -p genproto

protoc --go_out=plugins=grpc:genproto -I $protodir $protodir/helloworld.proto
