# Makefile for Tunnelbees project

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOGET=$(GOCMD) get
BINARY_NAME=tunnelbees

# Build directories
GEN_KEY_DIR=.
HONEYPOT_DIR=honeypot
SCHNORR_DIR=schnorr
STEALTH_DIR=stealth

# Targets
all: gen_key honeypot_client honeypot_server schnorr stealth_client stealth_server

gen_key:
	$(GOBUILD) -o $(BINARY_NAME)_gen_key $(GEN_KEY_DIR)/gen-key.go

honeypot_client:
	$(GOBUILD) -o $(BINARY_NAME)_honeypot_client $(HONEYPOT_DIR)/tb-client.go

honeypot_server:
	$(GOBUILD) -o $(BINARY_NAME)_honeypot_server $(HONEYPOT_DIR)/tb-server.go

schnorr:
	$(GOBUILD) -o $(BINARY_NAME)_schnorr $(SCHNORR_DIR)/schnorr.go

stealth_client:
	$(GOBUILD) -o $(BINARY_NAME)_stealth_client $(STEALTH_DIR)/tb-client.go

stealth_server:
	$(GOBUILD) -o $(BINARY_NAME)_stealth_server $(STEALTH_DIR)/tb-server.go

clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)*

# Run 'go get' for dependencies
deps:
	$(GOGET) ./...

static: deps
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -a -installsuffix cgo -o $(BINARY_NAME)_gen_key $(GEN_KEY_DIR)/gen-key.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -a -installsuffix cgo -o $(BINARY_NAME)_honeypot_client $(HONEYPOT_DIR)/tb-client.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -a -installsuffix cgo -o $(BINARY_NAME)_honeypot_server $(HONEYPOT_DIR)/tb-server.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -a -installsuffix cgo -o $(BINARY_NAME)_schnorr $(SCHNORR_DIR)/schnorr.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -a -installsuffix cgo -o $(BINARY_NAME)_stealth_client $(STEALTH_DIR)/tb-client.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -a -installsuffix cgo -o $(BINARY_NAME)_stealth_server $(STEALTH_DIR)/tb-server.go
