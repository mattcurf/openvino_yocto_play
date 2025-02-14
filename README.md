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

This command launche the guest VM as a console on the current terminal.  No display is enabled, but the GPU is full enabled for OpenVINO acceleration.  Launching the VM requires sudo permission.
```
$ cd openvino_yocto_play
$ make execute
```
