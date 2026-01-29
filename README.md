# Kubernetes-cluster-with-worker-node-kubeadm-project

## For more projects, check out  
[https://harishnshetty.github.io/projects.html](https://harishnshetty.github.io/projects.html)

[![Video Tutorial](https://github.com/harishnshetty/image-data-project/blob/22ed0e06accf2365a14a6e0a704044c93e16461c/kubeadm0.jpg)](https://youtu.be/BgyYqUXuHuk?si=Gi6vkxhnVJQBILkG)

[![Channel Link](https://github.com/harishnshetty/image-data-project/blob/22ed0e06accf2365a14a6e0a704044c93e16461c/kubeadm2.jpg)](https://youtu.be/BgyYqUXuHuk?si=Gi6vkxhnVJQBILkG)




sudo hostnamectl set-hostname master
exec bash



https://kubernetes.io/docs/reference/networking/ports-and-protocols/

## 🔐 Kubernetes Control Plane – Network Ports
| Protocol | Direction | Port / Range  | Purpose                 | Used By                           |
| -------- | --------- | ------------- | ----------------------- | --------------------------------- |
| TCP      | Inbound   | **6443**      | Kubernetes API Server   | All (kubectl, nodes, controllers) |
| TCP      | Inbound   | **2379–2380** | etcd server client API  | kube-apiserver, etcd              |
| TCP      | Inbound   | **10250**     | Kubelet API             | Control plane, self               |
| TCP      | Inbound   | **10259**     | kube-scheduler          | Self                              |
| TCP      | Inbound   | **10257**     | kube-controller-manager | Self                              |

[![Control Plane Security Group](https://github.com/harishnshetty/image-data-project/blob/22ed0e06accf2365a14a6e0a704044c93e16461c/kubeadm3-control-sg.png)](https://youtu.be/BgyYqUXuHuk?si=Gi6vkxhnVJQBILkG)



## 🖥️ Kubernetes Worker Nodes – Network Ports

| Protocol | Direction | Port / Range    | Purpose           | Used By              |
| -------- | --------- | --------------- | ----------------- | -------------------- |
| TCP      | Inbound   | **10250**       | Kubelet API       | Control plane        |
| TCP      | Inbound   | **10256**       | kube-proxy        | Self, Load Balancers |
| TCP      | Inbound   | **30000–32767** | NodePort Services | All                  |
| UDP      | Inbound   | **30000–32767** | NodePort Services | All                  |

[![Worker Node Security Group](https://github.com/harishnshetty/image-data-project/blob/22ed0e06accf2365a14a6e0a704044c93e16461c/kubeadm4-worker-sg.png)](https://youtu.be/BgyYqUXuHuk?si=Gi6vkxhnVJQBILkG)



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

9) initialize control plane

## calico setup  --> ip range is 192.168.0.0/16
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=172.31.22.160 --cri-socket unix:///var/run/containerd/containerd.sock --node-name controlplane
```
## flannel setup or weavenet setup --> ip range is 10.244.0.0/16
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=172.31.22.160 --cri-socket unix:///var/run/containerd/containerd.sock --node-name controlplane
```

>Note: copy to the notepad that was generated after the init command completion, we will use that later.

10) Prepare `kubeconfig`

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



11) Install calico 

## calico setup  --> ip range is 192.168.0.0/16
https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/operator-crds.yaml


kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/tigera-operator.yaml

curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/custom-resources-bpf.yaml

kubectl apply -f custom-resources-bpf.yaml

watch kubectl get tigerastatus
```

Node should become:

```bash
kubectl get nodes
```

## Allow Scheduling Pods on Control Plane (Single Node Only)
```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```



## Validation

If all the above steps were completed, you should be able to run `kubectl get nodes` on the master node, and it should return all the 3 nodes in ready status.

Also, make sure all the pods are up and running by using the command as below:
` kubectl get pods -A`

>If your Calico-node pods are not healthy, please perform the below steps:

- Disabled source/destination checks for master and worker nodes too.
- Configure Security group rules, Bidirectional, all hosts,TCP 179(Attach it to master and worker nodes)
- Update the ds using the command:
`kubectl set env daemonset/calico-node -n calico-system IP_AUTODETECTION_METHOD=interface=ens5`
Where ens5 is your default interface, you can confirm by running `ifconfig` on all the machines
- IP_AUTODETECTION_METHOD  is set to first-found to let Calico automatically select the appropriate interface on each node.
- Wait for some time or delete the calico-node pods and it should be up and running.
- If you are still facing the issue, you can follow the below workaround

- Install Calico CNI addon using manifest instead of Operator and CR, and all calico pods will be up and running 
`kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml`

This is not the latest version of calico though(v.3.25). This deploys CNI in kube-system NS. 

---
# Cleanup the failed attempt

```bash
sudo kubeadm reset -f
sudo rm -rf ~/.kube
# Retry init
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=[IP_ADDRESS] --node-name controlplane
```