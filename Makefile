build:
	go build -o bin/ src/engine/sampler.go
	go build -o bin/ src/engine/iopiper.go
	go build -o bin/ src/engine/ping-server.go
