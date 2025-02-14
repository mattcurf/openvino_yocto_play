# openvino_yocto_play

A playground demonstrating the use of the Yocto distribution building toolchain, how to include Intel's OpenVINO as a component of that, and steps required to build a guest virtual machine that can be launched by KVM with passthrough discrete Intel ARC A770 GPU for exclusive use by that virtual machine and used by OpenVINO.  This playground assumes use of Ubuntu 24.04 host.

*Note:* Some of the configuration mentioned in this repo is speciic to my particular machine setup: an Intel Core Ultra 9 285K workstation with integrated graphics and two Intel ARC A770 GPUs.  This repo is provided as-is in case it is helpful, but will not be actively maintained for the general public.

## Enable Docker

This example utilizes a container to fully encapsulate the Yocto toolchain build dependencies.  Here are the instructions how to install docker:

```
$ sudo apt-get update
$ sudo apt-get install ca-certificates curl
$ sudo install -m 0755 -d /etc/apt/keyrings
$ sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
$ sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable docker access as user
sudo groupadd docker
sudo usermod -aG docker $USER
```
*Note:* This configuration above grants full root access of the container to your machine. Only follow this if you understand the implications for doing so, and don't follow this procedure on a production machine.

## Build a Yocto based guest VM with OpenVINO 

The following steps will build a Yocto based guest OS from source, including CPU and GPU accelerated OpenVINO support.  The process will require ~300GB of storage space, significant Internet download capacity, and may take multiple hours to build depending on your system configuration.  More memory and CPUs make a big difference!
```
$ git clone https://github.com/mattcurf/openvino_yocto_play
$ cd openvino_yocto_play
$ make bitbake
```

## Enable Virtualization

The following steps are only required once to install the Ubuntu 24.04 KVM virtualization support, copied from multiple tutorials.  This playground may not necessariliy use all of the services described below (like libvirtd auto hardware provisioning):
```
$ sudo apt update && sudo apt upgrade -y
$ sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager -y
$ sudo systemctl enable --now libvirtd
$ sudo usermod -aG libvirt,kvm $USER
$ sudo reboot
```

## Execute Guest

Executing the guest is described in two parts: making the second GPU available for passthrough to the guest, and launching the guest.  These steps are typically automated using libvirtd but are show explictly here so the theory is understood:

### GPU Passthrough

This prepares the secondary A770 GPU located via 'lspci' command at bus 85 (GPU) and bus 86 (audio), by detaching the GPU from the host.
```
$ sudo modprobe vfio
$ sudo modprobe vfio_iommu_type1
$ sudo modprobe vfio_pci
$ sudo virsh nodedev-detach pci_0000_85_00_0
$ sudo virsh nodedev-detach pci_0000_86_00_0
```

### Launch the guest

This command launche the guest VM as a console on the current terminal.  No display is enabled, but the GPU is full enabled for OpenVINO acceleration.  Launching the VM requires sudo permission.  The generated guest VM users 'root' user with no password.
```
$ cd openvino_yocto_play
$ make execute
Poky (Yocto Project Reference Distro) 5.0.7 intel-skylake-64 /dev/ttyS0

intel-skylake-64 login: root

WARNING: Poky is a reference Yocto Project distribution that should be used for
testing and development purposes only. It is recommended that you create your
own distribution for production use.

root@intel-skylake-64:~# hello_query_device
[ INFO ] Build ................................. 2024.1.0-15008-f4afc983258-releases/2024/1
[ INFO ] 
[ INFO ] Available devices: 
[ INFO ] CPU
[ INFO ]        SUPPORTED_PROPERTIES: 
[ INFO ]                Immutable: AVAILABLE_DEVICES : ""
[ INFO ]                Immutable: RANGE_FOR_ASYNC_INFER_REQUESTS : 1 1 1
[ INFO ]                Immutable: RANGE_FOR_STREAMS : 1 4
[ INFO ]                Immutable: EXECUTION_DEVICES : CPU
[ INFO ]                Immutable: FULL_DEVICE_NAME : Intel(R) Core(TM) Ultra 7 265K
[ INFO ]                Immutable: OPTIMIZATION_CAPABILITIES : FP32 FP16 INT8 BIN EXPORT_IMPORT
[ INFO ]                Immutable: DEVICE_TYPE : integrated
[ INFO ]                Immutable: DEVICE_ARCHITECTURE : intel64
[ INFO ]                Mutable: NUM_STREAMS : 1
[ INFO ]                Mutable: AFFINITY : CORE
[ INFO ]                Mutable: INFERENCE_NUM_THREADS : 0
[ INFO ]                Mutable: PERF_COUNT : NO
[ INFO ]                Mutable: INFERENCE_PRECISION_HINT : f32
[ INFO ]                Mutable: PERFORMANCE_HINT : LATENCY
[ INFO ]                Mutable: EXECUTION_MODE_HINT : PERFORMANCE
[ INFO ]                Mutable: PERFORMANCE_HINT_NUM_REQUESTS : 0
[ INFO ]                Mutable: ENABLE_CPU_PINNING : YES
[ INFO ]                Mutable: SCHEDULING_CORE_TYPE : ANY_CORE
[ INFO ]                Mutable: MODEL_DISTRIBUTION_POLICY : ""
[ INFO ]                Mutable: ENABLE_HYPER_THREADING : YES
[ INFO ]                Mutable: DEVICE_ID : ""
[ INFO ]                Mutable: CPU_DENORMALS_OPTIMIZATION : NO
[ INFO ]                Mutable: LOG_LEVEL : LOG_NONE
[ INFO ]                Mutable: CPU_SPARSE_WEIGHTS_DECOMPRESSION_RATE : 1
[ INFO ]                Mutable: DYNAMIC_QUANTIZATION_GROUP_SIZE : 0
[ INFO ]                Mutable: KV_CACHE_PRECISION : f16
[ INFO ] 
[ INFO ] GPU
[ INFO ]        SUPPORTED_PROPERTIES: 
[ INFO ]                Immutable: AVAILABLE_DEVICES : 0
[ INFO ]                Immutable: RANGE_FOR_ASYNC_INFER_REQUESTS : 1 2 1
[ INFO ]                Immutable: RANGE_FOR_STREAMS : 1 2
[ INFO ]                Immutable: OPTIMAL_BATCH_SIZE : 1
[ INFO ]                Immutable: MAX_BATCH_SIZE : 1
[ INFO ]                Immutable: DEVICE_ARCHITECTURE : GPU: vendor=0x8086 arch=v781.192.8
[ INFO ]                Immutable: FULL_DEVICE_NAME : Intel(R) Arc(TM) A770 Graphics (dGPU)
[ INFO ]                Immutable: DEVICE_UUID : 8680a056080000000004000000000000
[ INFO ]                Immutable: DEVICE_LUID : d0b6296cfd7f0000
[ INFO ]                Immutable: DEVICE_TYPE : discrete
[ INFO ]                Immutable: DEVICE_GOPS : {f16:0,f32:19660.8,i8:0,u8:0}
[ INFO ]                Immutable: OPTIMIZATION_CAPABILITIES : FP32 BIN FP16 INT8 GPU_HW_MATMUL EXPORT_IMPORT
[ INFO ]                Immutable: GPU_DEVICE_TOTAL_MEM_SIZE : 16225243136
[ INFO ]                Immutable: GPU_UARCH_VERSION : 781.192.8
[ INFO ]                Immutable: GPU_EXECUTION_UNITS_COUNT : 512
[ INFO ]                Immutable: GPU_MEMORY_STATISTICS : ""
[ INFO ]                Mutable: PERF_COUNT : NO
[ INFO ]                Mutable: MODEL_PRIORITY : MEDIUM
[ INFO ]                Mutable: GPU_HOST_TASK_PRIORITY : MEDIUM
[ INFO ]                Mutable: GPU_QUEUE_PRIORITY : MEDIUM
[ INFO ]                Mutable: GPU_QUEUE_THROTTLE : MEDIUM
[ INFO ]                Mutable: GPU_ENABLE_LOOP_UNROLLING : YES
[ INFO ]                Mutable: GPU_DISABLE_WINOGRAD_CONVOLUTION : NO
[ INFO ]                Mutable: CACHE_DIR : ""
[ INFO ]                Mutable: CACHE_MODE : optimize_speed
[ INFO ]                Mutable: PERFORMANCE_HINT : LATENCY
[ INFO ]                Mutable: EXECUTION_MODE_HINT : PERFORMANCE
[ INFO ]                Mutable: COMPILATION_NUM_THREADS : 4
[ INFO ]                Mutable: NUM_STREAMS : 1
[ INFO ]                Mutable: PERFORMANCE_HINT_NUM_REQUESTS : 0
[ INFO ]                Mutable: INFERENCE_PRECISION_HINT : f16
[ INFO ]                Mutable: ENABLE_CPU_PINNING : NO
[ INFO ]                Mutable: DEVICE_ID : 0
[ INFO ]
```
