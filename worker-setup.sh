#!/bin/bash
set -e

# ================================
# System Update & Base Packages
# ================================
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gpg \
  ncdu \
  net-tools

# ================================
# Disable Swap (Required for Kubernetes)
# ================================
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# ================================
# Kernel Modules for Kubernetes
# ================================

sudo modprobe overlay
sudo modprobe br_netfilter


cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# ================================
# Sysctl Settings for Kubernetes Networking
# ================================
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Verify Modules
lsmod | grep br_netfilter || true
lsmod | grep overlay || true

# ================================
# Install Containerd
# ================================
sudo apt update
sudo apt install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Docker Repository
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y containerd.io

# ================================
# Configure Containerd
# ================================
containerd config default | sudo tee /etc/containerd/config.toml

sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.bak

sudo sed -i \
  's/SystemdCgroup \= false/SystemdCgroup \= true/g' \
  /etc/containerd/config.toml


sudo sed -i "/\[plugins\.'io\.containerd\.grpc\.v1\.cri'\]/a\    sandbox_image = 'registry.k8s.io/pause:3.10'" /etc/containerd/config.toml

# Enable CRI plugin (remove it from disabled_plugins if present)

sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# ================================
# Install runc
# ================================
curl -LO https://github.com/opencontainers/runc/releases/download/v1.4.0/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# ================================
# Install CNI Plugins
# ================================
curl -LO https://github.com/containernetworking/plugins/releases/download/v1.9.0/cni-plugins-linux-amd64-v1.9.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.9.0.tgz

# ================================
# Install Kubernetes Components
# ================================
sudo apt-get update
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y \
  kubelet=1.34.3-1.1 \
  kubeadm=1.34.3-1.1 \
  kubectl=1.34.3-1.1 \
  --allow-downgrades \
  --allow-change-held-packages

sudo apt-mark hold kubelet kubeadm kubectl

sudo chmod 666 /run/containerd/containerd.sock
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
