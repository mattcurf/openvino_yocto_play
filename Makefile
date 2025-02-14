CURRENT_DIR := $(shell pwd)

ARCH := $(shell uname -m)
ifeq ($(ARCH),arm64)
  ARCH := aarch64
endif

DOCKER_IMAGE_NAME = $(shell basename `pwd`)
DOCKER_ARGS = -it --rm -v `pwd`:`pwd` -w `pwd` -e CI_SOURCE_PATH=`pwd`
DOCKER_ARGS += $(DOCKER_IMAGE_NAME)

image:
	@echo "Building Docker image $(DOCKER_IMAGE_NAME)..."
	@docker build . --progress plain -f docker/Dockerfile.$(ARCH) -t $(DOCKER_IMAGE_NAME)

clean:
	@docker rmi $(DOCKER_IMAGE_NAME)

bitbake: image
	@docker run $(DOCKER_ARGS) /bin/bash scripts/_build

shell: image 
	@docker run --entrypoint /bin/bash $(DOCKER_ARGS)

execute: 
	sudo qemu-system-x86_64 \
  	   -cpu host \
  	   -enable-kvm \
           -m 16G \
           -smp cores=4,sockets=1,threads=1 \
           -rtc base=localtime \
           -kernel src/build/tmp/deploy/images/intel-corei7-64/bzImage \
           -drive file=src/build/tmp/deploy/images/intel-corei7-64/core-image-minimal-intel-corei7-64.rootfs.ext4,format=raw \
           -append "root=/dev/sda rw"

