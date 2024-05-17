#!/bin/bash

source src/oe-init-build-env

bitbake-layers add-layer ../src/meta-intel
bitbake-layers add-layer ../src/meta-openembedded/meta-oe
bitbake-layers add-layer ../src/meta-openembedded/meta-python
bitbake-layers add-layer ../src/meta-clang

cat <<EOF >> conf/local.conf 
LICENSE_FLAGS_ACCEPTED = "commercial"
INHERIT += "own-mirrors"
BB_GENERATE_MIRROR_TARBALLS = "1"
SOURCE_MIRROR_URL = "file://$YOCTO_DOWNLOAD_CACHE"
MACHINE = "intel-skylake-64"
PACKAGECONFIG:append:pn-openvino-inference-engine = " opencl"
PACKAGECONFIG:append:pn-openvino-inference-engine = " python3"
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-inference-engine"
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-inference-engine-samples"
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-inference-engine-python3"
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-model-optimizer"
EOF
