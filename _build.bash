#!/bin/bash

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8;

echo "Building ..."
source src/oe-init-build-env
bitbake core-image-minimal
#bitbake core-image-minimal -c populate_sdk
