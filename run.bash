#!/bin/bash

if [ -z "$YOCTO_DOWNLOAD_CACHE" ]; then
	echo "Error: YOCTO_DOWNLOAD_CACHE environment variable is not set" 
	exit -1
fi

export IMAGE_NAME=ubuntu_20_yocto
export RUN_ARGS="--rm -v `pwd`:`pwd` -e YOCTO_DOWNLOAD_CACHE=$YOCTO_DOWNLOAD_CACHE -v $YOCTO_DOWNLOAD_CACHE:$YOCTO_DOWNLOAD_CACHE -e "CI_SOURCE_PATH=`pwd`" -t $IMAGE_NAME"

# Create Docker image
if [ -z $(docker images -q $IMAGE_NAME) ]; then
   echo "Building image ..."
   docker build -t $IMAGE_NAME docker	
fi

if [ ! -d "src" ]; then
   git clone -b scarthgap https://git.yoctoproject.org/poky src
   cd src
   git clone -b scarthgap https://git.yoctoproject.org/meta-intel
   git clone -b scarthgap https://git.openembedded.org/meta-openembedded
   git clone -b scarthgap https://github.com/kraj/meta-clang.git
   cd ..
fi

if [ ! -d "build_up" ]; then
   docker run $RUN_ARGS /bin/sh -c 'cd $CI_SOURCE_PATH; ./_setup.bash'
fi

# Build it
docker run $RUN_ARGS /bin/sh -c 'cd $CI_SOURCE_PATH; ./_build.bash'
