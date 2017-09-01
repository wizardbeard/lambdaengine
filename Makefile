#@IgnoreInspection BashAddShebang
.PHONY: all

SRCS = $(shell git ls-files '*.go' | grep -v '^vendor/')

GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
LAMBDAENGINE_IMAGE := lambdaengine$(if $(GIT_BRANCH),:$(GIT_BRANCH))
LAMBDAENGINE_TEST_IMAGE := lambdaengine-test$(if $(GIT_BRANCH),:$(GIT_BRANCH))
REPONAME := $(shell echo $(REPO) | tr '[:upper:]' '[:lower:]')

DOCKER_BUILD_ARGS := $(if $(DOCKER_VERSION), "--build-arg=DOCKER_VERSION=$(DOCKER_VERSION)",)

THIS_FILE := $(lastword $(MAKEFILE_LIST))

print-%: ; @echo $*=$($*)

default: build

build:
	docker build $(DOCKER_BUILD_ARGS) -t "$(LAMBDAENGINE_IMAGE)" -f Dockerfile .

build-no-cache:
	docker build --no-cache -t "$(LAMBDAENGINE_IMAGE)" -f Dockerfile .

shell: build ## start a shell inside the build env
	$(DOCKER_RUN_LAMBDAENGINE) /bin/bash

run:
	cd cmd/lambdaengine && go build -ldflags "-X github.com/TheWizardAndTheWyrd/lambdaengine/lambdaengine.versionHash=`git rev-parse --short HEAD`" .
	export DOCKER_HOST_IP=$(ip route | grep 'default' | awk '{print $3}')
	cd cmd/lambdaengine && ./lambdaengine

dev-run:
	. .env
	@$(MAKE) -f $(THIS_FILE) run

run-tests:
	docker build $(DOCKER_BUILD_ARGS) -t "$(LAMBDAENGINE_TEST_IMAGE)" -f test.Dockerfile .

fmt:
	gofmt -s -l -w $(SRCS)

docker-run:
	docker run $(LAMBDAENGINE_IMAGE)
