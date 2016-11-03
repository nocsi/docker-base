VERSION = 0.0.1
NAME = registry.nocsi.org

CREATE_DATE := $(shell date +%FT%T%Z)
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(shell dirname $(MKFILE_PATH))
DOCKER_BIN := $(shell which docker)

all: build test

.PHONY: check.env
check.env:
ifndef DOCKER_BIN
   $(error The docker command is not found. Verify that Docker is installed and accessible)
endif


### Base images

.PHONY: alpine
alpine:
	@echo " "
	@echo " "
	@echo "Building 'base/alpine' image..."
	@echo " "
	$(DOCKER_BIN) build -t $(NAME)/base:alpine $(CURRENT_DIR)/base/alpine

.PHONY: ubuntu
ubuntu:
	@echo " "
	@echo " "
	@echo "Building 'base/ubuntu' image..."
	@echo " "
	$(DOCKER_BIN) build -t $(NAME)/base:ubuntu $(CURRENT_DIR)/base/ubuntu

.PHONY: debian
debian:
	@echo " "
	@echo " "
	@echo "Building 'base/debian' image..."
	@echo " "
	$(DOCKER_BIN) build -t $(NAME)/base:debian $(CURRENT_DIR)/base/debian

.PHONY: centos
centos:
	@echo " "
	@echo " "
	@echo "Building 'base/centos' image..."
	@echo " "
	$(DOCKER_BIN) build -t $(NAME)/base:centos $(CURRENT_DIR)/base/centos

.PHONY: ubuntu-slim
ubuntu-slim:
	@echo " "
	@echo " "
	@echo "Building 'base/ubuntu-slim' image..."
	@echo " "
	cd $(CURRENT_DIR)/base/ubuntu-slim && $(MAKE) container
	cd $(CURRENT_DIR)

.PHONY: base
base: alpine ubuntu debian centos ubuntu-slim
	@echo " "
	@echo " "
	@echo "Base images have been built."
	@echo " "

.PHONY: base_test
base_test:
	@if ! $(DOCKER_BIN) run $(NAME)/base:ubuntu /bin/sh -c 'cat /etc/*-release' | grep -q -F Ubuntu; then false; fi
	@if ! $(DOCKER_BIN) run $(NAME)/base:ubuntu-slim /bin/sh -c 'cat /etc/*-release' | grep -q -F Ubuntu; then false; fi
	@if ! $(DOCKER_BIN) run $(NAME)/base:debian /bin/sh -c 'cat /etc/*-release' | grep -q -F Debian; then false; fi
	@if ! $(DOCKER_BIN) run $(NAME)/base:centos /bin/sh -c 'cat /etc/*-release' | grep -q -F CentOS; then false; fi
	@if ! $(DOCKER_BIN) run $(NAME)/base:alpine /bin/sh -c 'cat /etc/*-release' | grep -q -F Alpine; then false; fi
	@echo " "
	@echo " "
	@echo "Base tests have completed."
	@echo " "


.PHONY: base_rm
base_rm:
	@if docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F alpine; then $(DOCKER_BIN) rmi $(NAME)/base:alpine; fi
	@if docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F ubuntu-slim; then $(DOCKER_BIN) rmi $(NAME)/base:ubuntu-slim; fi
	@if docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F ubuntu; then $(DOCKER_BIN) rmi $(NAME)/base:ubuntu; fi
	@if docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F centos; then $(DOCKER_BIN) rmi $(NAME)/base:centos; fi
	@if docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F debian; then $(DOCKER_BIN) rmi $(NAME)/base:debian; fi


.PHONY: build
build: base 
	@echo " "
	@echo " "
	@echo "All done with builds."
	@echo " "



.PHONY: test
test: base_test 
	@echo " "
	@echo " "
	@echo "All done with tests."
	@echo " "



# Push updates to Docker's registry
.PHONY: release_base
release_base:
	@if ! $(DOCKER_BIN) images $(NAME)/base | awk '{ print $$2 }' | grep -q -F alpine; then echo "$(NAME)/base:alpine is not yet built. Please run 'make build'"; false; fi
	@if ! $(DOCKER_BIN) images $(NAME)/base | awk '{ print $$2 }' | grep -q -F ubuntu-slim; then echo "$(NAME)/base:ubuntu-slim is not yet built. Please run 'make build'"; false; fi
	@if ! $(DOCKER_BIN) images $(NAME)/base | awk '{ print $$2 }' | grep -q -F ubuntu; then echo "$(NAME)/base:ubuntu is not yet built. Please run 'make build'"; false; fi
	@if ! $(DOCKER_BIN) images $(NAME)/base | awk '{ print $$2 }' | grep -q -F debian; then echo "$(NAME)/base:debian is not yet built. Please run 'make build'"; false; fi
	@if ! $(DOCKER_BIN) images $(NAME)/base | awk '{ print $$2 }' | grep -q -F centos; then echo "$(NAME)/base:centos is not yet built. Please run 'make build'"; false; fi
	$(DOCKER_BIN) push $(NAME)/base

.PHONY: release
release: release_base


# Clean-up the cruft
.PHONY: clean
clean: clean_untagged clean_slim base_rm clean_untagged
	rm -rf $(CURRENT_DIR)/mush/terraform.tfvars
	rm -rf $(CURRENT_DIR)/jinja2/some.json

.PHONY: clean_slim
clean_slim:
	cd $(CURRENT_DIR)/base/ubuntu-slim && $(MAKE) clean
	cd $(CURRENT_DIR)

#	docker images -q --filter "dangling=true" | xargs -l docker rmi
#	docker images --no-trunc | grep none | awk '{print $$3}' | xargs -r docker rmi
.PHONY: clean_untagged
clean_untagged: clean_stopped
	docker images --no-trunc | grep none | awk '{print $$3}' | xargs -r docker rmi

.PHONY: clean_stopped
clean_stopped:
	for i in `docker ps --no-trunc -a -q`;do docker rm $$i;done
