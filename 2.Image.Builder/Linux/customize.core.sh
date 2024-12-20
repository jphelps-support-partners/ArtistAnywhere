#!/bin/bash -ex

source /tmp/functions.sh

echo "Customize (Start): Core"

echo "Customize (Start): Image Build Platform"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
dnf -y install epel-release python3-devel gcc gcc-c++ perl lsof cmake bzip2 git
export AZNFS_NONINTERACTIVE_INSTALL=1
version=$(echo $buildConfig | jq -r .version.azBlobNFSMount)
curl -L https://github.com/Azure/AZNFS-mount/releases/download/$version/aznfs_install.sh | bash
if [ $machineType == Workstation ]; then
  echo "Customize (Start): Image Build Platform (Workstation)"
  dnf -y group install workstation
  dnf -y module enable nodejs:20
  dnf -y module install nodejs
  echo "Customize (End): Image Build Platform (Workstation)"
fi
echo "Customize (End): Image Build Platform"

if [[ $machineType == Storage || "$gpuProvider" != "" ]]; then
  echo "Customize (Start): Linux Kernel Dev"
  dnf -y install elfutils-libelf-devel openssl-devel bison flex
  fileName="kernel-devel-5.14.0-362.8.1.el9_3.x86_64.rpm"
  fileLink="https://download.rockylinux.org/vault/rocky/9.3/devel/x86_64/os/Packages/k/$fileName"
  DownloadFile $fileName $fileLink
  rpm -i $fileName
  echo "Customize (End): Linux Kernel Dev"
fi

if [ $machineType == Storage ]; then
  echo "Customize (Start): NVIDIA OFED"
  fileType="mellanox-ofed"
  fileName="MLNX_OFED_LINUX-24.07-0.6.1.0-rhel9.3-x86_64.tgz"
  fileLink="$binHostUrl/NVIDIA/OFED/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  tar -xzf $fileName
  dnf -y install kernel-modules-extra kernel-rpm-macros rpm-build libtool gcc-gfortran pciutils tcl tk
  RunProcess "./MLNX_OFED*/mlnxofedinstall --without-fw-update --add-kernel-support --skip-repo" $binDirectory/$fileType
  echo "Customize (End): NVIDIA OFED"
fi

if [ "$gpuProvider" == NVIDIA ]; then
  echo "Customize (Start): NVIDIA GPU (GRID)"
  fileType="nvidia-gpu-grid"
  fileName="$fileType.run"
  fileLink="https://go.microsoft.com/fwlink/?linkid=874272"
  DownloadFile $fileName $fileLink
  chmod +x $fileName
  dnf -y install libglvnd-devel mesa-vulkan-drivers xorg-x11-drivers pkg-config
  RunProcess "./$fileName --silent" $binDirectory/$fileType
  echo "Customize (End): NVIDIA GPU (GRID)"

  echo "Customize (Start): NVIDIA GPU (CUDA)"
  dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
  dnf -y install cuda
  echo "Customize (End): NVIDIA GPU (CUDA)"

  echo "Customize (Start): NVIDIA OptiX"
  version=$(echo $buildConfig | jq -r .version.nvidiaOptiX)
  fileType="nvidia-optix"
  fileName="NVIDIA-OptiX-SDK-$version-linux64-x86_64.sh"
  fileLink="$binHostUrl/NVIDIA/OptiX/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  chmod +x $fileName
  filePath="$binDirectory/$fileType/$version"
  mkdir -p $filePath
  RunProcess "./$fileName --skip-license --prefix=$filePath" $binDirectory/$fileType-1
  buildDirectory="$filePath/build"
  mkdir -p $buildDirectory
  dnf -y install libXrandr-devel
  dnf -y install libXcursor-devel
  dnf -y install libXinerama-devel
  dnf -y install mesa-libGL-devel
  dnf -y install mesa-libGL
  RunProcess "cmake -B $buildDirectory -S $filePath/SDK" $binDirectory/$fileType-2
  RunProcess "make -C $buildDirectory" $binDirectory/$fileType-3
  binPaths="$binPaths:$buildDirectory/bin"
  echo "Customize (End): NVIDIA OptiX"
fi

if [[ $machineType == Storage || $machineType == JobScheduler ]]; then
  echo "Customize (Start): Azure CLI"
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  dnf -y install https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
  dnf -y install azure-cli
  echo "Customize (End): Azure CLI"
fi

if [ $machineType == Workstation ]; then
  echo "Customize (Start): HP Anyware"
  version=$(echo $buildConfig | jq -r .version.hpAnywareAgent)
  [ "$gpuProvider" == "" ] && fileType="pcoip-agent-standard" || fileType="pcoip-agent-graphics"
  fileName="pcoip-agent-offline-rocky9.4_$version-1.el9.x86_64.tar.gz"
  fileLink="$binHostUrl/Teradici/$version/$fileName"
  DownloadFile $fileName $fileLink $tenantId $clientId $clientSecret $storageVersion
  mkdir -p $fileType
  tar -xzf $fileName -C $fileType
  cd $fileType
  RunProcess "./install-pcoip-agent.sh $fileType usb-vhci" $binDirectory/$fileType
  cd $binDirectory
  echo "Customize (End): HP Anyware"
fi

if [ "$binPaths" != "" ]; then
  echo "Customize (PATH): ${binPaths:1}"
  echo 'PATH=$PATH'$binPaths >> $aaaProfile
fi

echo "Customize (End): Core"
