EXE = babygorilla

# this allows to do "make run arg1 arg2 arg3..."
ifeq (run,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

all: build-by-downloading-go-compiler

# big brain way if the machines in comp don't have Go 1.19
build-by-downloading-go-compiler: clean
	mkdir -p ./out; \
	wget -O ./out/go.tar.gz https://go.dev/dl/go1.19.1.linux-amd64.tar.gz; \
	tar -C ./out -xzf ./out/go.tar.gz; \
	./out/go/bin/go build -o ./$(EXE) ./main.go; \

build: clean
	mkdir -p ./out; \
	go build -o ./$(EXE) ./main.go; \

.PHONY: run
run: build
	./out/${EXE} $(RUN_ARGS)

hot:
	reflex -s -r '\.go$$' make run

zip: clean
	zip -r ./out/proj.zip ./main.go ./go.mod ./go.sum Makefile ./lib ./README.md

.PHONY: test
test:
	cd ./tests ; \
		go test

clean:
	rm -fr ./out/*; \
	rm -f ./$(EXE); \
