# worker-node-setup

## Auto Worker Node Setup Script
```bash
curl -O https://raw.githubusercontent.com/harishnshetty/Kubernetes-cluster-with-worker-node-kubeadm-project/refs/heads/main/worker-setup.sh
chmod +x worker-setup.sh
sudo ./worker-setup.sh
```


### Run the below steps on the Master VM
1) SSH into the Master EC2 server

### System Update & Base Packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg ncdu net-tools 
```


2)  Disable Swap using the below commands
```bash
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

Verify:

```bash
free -h
```


3) Forwarding IPv4 and letting iptables see bridged traffic


```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter


# Verify that the br_netfilter, overlay modules are loaded by running the following commands:

lsmod | grep br_netfilter
lsmod | grep overlay

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF



# Apply sysctl params without reboot
sudo sysctl --system

# Verify that the br_netfilter, overlay modules are loaded by running the following commands:
lsmod | grep br_netfilter
lsmod | grep overlay


# Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
```



4) Install container runtime

## containerd for specific version

https://github.com/containerd/containerd/releases 


```bash
curl -LO https://github.com/containerd/containerd/releases/download/v2.2.1/containerd-2.2.1-linux-amd64.tar.gz

sudo tar Cxzvf /usr/local containerd-2.2.1-linux-amd64.tar.gz

curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service


sudo mkdir -p /usr/local/lib/systemd/system/
sudo mv containerd.service /usr/local/lib/systemd/system/
sudo mkdir -p /etc/containerd
```
## Auto configuration

https://docs.docker.com/engine/install/ubuntu/

```bash
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install containerd.io
```

```bash
containerd config default | sudo tee /etc/containerd/config.toml
```

```bash
cat /etc/containerd/config.toml | grep -i SystemdCgroup

sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

sudo sed -i "/\[plugins\.'io\.containerd\.grpc\.v1\.cri'\]/a\    sandbox_image = 'registry.k8s.io/pause:3.10'" /etc/containerd/config.toml
```

```bash
sudo systemctl daemon-reload
sudo systemctl start containerd
sudo systemctl enable --now containerd
sudo systemctl restart containerd

# Check that containerd service is up and running
systemctl status containerd
```
Verify:

```bash
containerd --version
```

5) Install runc

https://github.com/opencontainers/runc/releases

```bash
curl -LO https://github.com/opencontainers/runc/releases/download/v1.4.0/runc.amd64

sudo install -m 755 runc.amd64 /usr/local/sbin/runc
```


6) install cni plugin

https://github.com/containernetworking/plugins/

```bash
curl -LO https://github.com/containernetworking/plugins/releases/download/v1.9.0/cni-plugins-linux-amd64-v1.9.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.9.0.tgz
```



7) Install kubeadm, kubelet and kubectl


### Add Kubernetes repo (new official method)
https://v1-34.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/


```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-cache madison kubeadm

sudo apt-get install -y kubelet=1.34.3-1.1 kubeadm=1.34.3-1.1 kubectl=1.34.3-1.1 --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

kubeadm version
kubelet --version
kubectl version --client
```


>Note: The reason we are installing 1.34, so that in one of the later task, we can upgrade the cluster to 1.35

8) Configure `crictl` to work with `containerd`

```bash
sudo chmod 666 /run/containerd/containerd.sock

sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock

sudo crictl --runtime-endpoint=unix:///run/containerd/containerd.sock version

crictl info
```


## This is the sample output


Then you can join any number of worker nodes by running the following on each as root:
```bash
kubeadm join 172.31.22.160:6443 --token 5onpcu.d8rhceyatl22765h \
        --discovery-token-ca-cert-hash sha256:a601e2ac5d29f48432375e26fbcea3adab77725c966b68f5b9858560a108fc2a
```


> If you forgot to copy the command, you can execute below command on master node to generate the join command again

## if incase failed to join, you can use the below command
```bash
sudo kubeadm reset
sudo systemctl enable --now kubelet
sudo kubeadm join 172.31.33.42:6443 --token jjzdo5.mdnhh3frptiiravz \
        --discovery-token-ca-cert-hash sha256:688204e361074906a65fa01f94974bf28a2b6c4018dba890b445beffa66e8a6e \
        --cri-socket unix:///var/run/containerd/containerd.sock
```        
    
```bash
kubeadm token create --print-join-command
```