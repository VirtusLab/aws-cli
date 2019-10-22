# Set POSIX sh for maximum interoperability
SHELL := /bin/sh

# Set an output prefix, which is the local directory if not specified
PREFIX?=$(shell pwd)

# Setup variables for the Makefile
NAME := aws-cli
REPO := virtuslab/aws-cli
DOCKER_REGISTRY := quay.io
VERSION := 1.16.263
EXTENDED_VERSION := -2

GITCOMMIT := $(shell git rev-parse --short HEAD)
GITBRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
GITIGNOREDBUTTRACKEDCHANGES := $(shell git ls-files -i --exclude-standard)
ifneq ($(GITUNTRACKEDCHANGES),)
    GITCOMMIT := $(GITCOMMIT)-dirty
endif
ifneq ($(GITIGNOREDBUTTRACKEDCHANGES),)
    GITCOMMIT := $(GITCOMMIT)-dirty
endif

DETAILED_TAG := $(GITCOMMIT)
VERSION_TAG := $(GITCOMMIT)
LATEST_TAG := $(GITCOMMIT)

ifneq ($(TRAVIS_TAG),)
	override DETAILED_TAG := $(VERSION)$(EXTENDED_VERSION)-$(GITCOMMIT)
	override VERSION_TAG := $(VERSION)$(EXTENDED_VERSION)
	override LATEST_TAG := latest
endif

ARGS ?= $(EXTRA_ARGS)

.DEFAULT_GOAL := help

.PHONY: all
all: status docker-build docker-images ## Build the image
	@echo "+ $@"

.PHONY: docker-build
docker-build: ## Build the container
	@echo "+ $@"
	docker build --build-arg AWS_CLI_VERSION=$(VERSION) -t $(REPO):$(GITCOMMIT) .

.PHONY: docker-login
docker-login: ## Log in into the repository
	@echo "+ $@"
	@docker login -u="${DOCKER_USER}" -p="${DOCKER_PASS}" $(DOCKER_REGISTRY)

.PHONY: docker-images
docker-images: ## List all local containers
	@echo "+ $@"
	docker images

.PHONY: docker-push
docker-push: docker-login ## Push the container
	@echo "+ $@"
	@docker tag $(REPO):$(GITCOMMIT) $(DOCKER_REGISTRY)/$(REPO):$(DETAILED_TAG)
	@docker tag $(REPO):$(GITCOMMIT) $(DOCKER_REGISTRY)/$(REPO):$(VERSION_TAG)
	@docker tag $(REPO):$(GITCOMMIT) $(DOCKER_REGISTRY)/$(REPO):$(LATEST_TAG)
	@docker push $(DOCKER_REGISTRY)/$(REPO):$(DETAILED_TAG)
	@docker push $(DOCKER_REGISTRY)/$(REPO):$(VERSION_TAG)
	@docker push $(DOCKER_REGISTRY)/$(REPO):$(LATEST_TAG)

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
    DOCKER_FLAGS += -t
endif

.PHONY: docker-run
docker-run: docker-build ## Build and run the container, you can use EXTRA_ARGS
	@echo "+ $@"
	docker run --rm -i $(DOCKER_FLAGS) \
		--mount type=bind,source=$(HOME)/.aws,target=/root/.aws \
		$(REPO):$(GITCOMMIT) $(ARGS)

.PHONY: tag
tag: ## Create a new git tag to prepare to build a release
	@echo "+ $@"
	git tag -a $(VERSION)$(EXTENDED_VERSION) -m "$(VERSION)$(EXTENDED_VERSION)"
	git push origin $(VERSION)$(EXTENDED_VERSION)

.PHONY: help
help:
	@grep -Eh '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: status
status: ## Shows git and dep status
	@echo "+ $@"
	@echo "Commit: $(GITCOMMIT), VERSION: $(VERSION)$(EXTENDED_VERSION)"
	@echo
	@echo "DETAILED_TAG: $(DETAILED_TAG)"
	@echo "VERSION_TAG: $(VERSION_TAG)"
	@echo "LATEST_TAG: $(LATEST_TAG)"
	@echo "TRAVIS_TAG: $(TRAVIS_TAG)"
	@echo
ifneq ($(GITUNTRACKEDCHANGES),)
	@echo "Changed files:"
	@git status --porcelain --untracked-files=no
	@echo
endif
ifneq ($(GITIGNOREDBUTTRACKEDCHANGES),)
	@echo "Ignored but tracked files:"
	@git ls-files -i --exclude-standard
	@echo
endif
