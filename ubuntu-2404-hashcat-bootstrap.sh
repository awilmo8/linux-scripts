#!/bin/bash
# This script installs OpenCL libraries, AMD ROCm drivers, and then reboots the system.
# Target system: Ubuntu 24.04 (Noble)

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# Helper function to print errors and exit
function error_exit {
    echo "Error on line $1"
    exit 1
}
trap 'error_exit $LINENO' ERR

echo "Updating package lists..."
sudo apt update

echo "Installing OpenCL libraries and tools..."
sudo apt install -y ocl-icd-libopencl1 pocl-opencl-icd clinfo

echo "Downloading AMD GPU driver package..."
wget https://repo.radeon.com/amdgpu-install/6.3.4/ubuntu/noble/amdgpu-install_6.3.60304-1_all.deb -O amdgpu-install.deb

echo "Installing rsync dependency..."
sudo apt install -y rsync

echo "Installing AMD GPU driver package..."
sudo dpkg -i amdgpu-install.deb

echo "Running amdgpu-install with ROCm use case..."
sudo amdgpu-install -y --usecase=rocm

echo "Installation complete. System will reboot in 10 seconds..."
sleep 10

sudo reboot
