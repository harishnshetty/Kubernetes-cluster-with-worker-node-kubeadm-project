Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.31.33.42:6443 --token jjzdo5.mdnhh3frptiiravz \
        --discovery-token-ca-cert-hash sha256:688204e361074906a65fa01f94974bf28a2b6c4018dba890b445beffa66e8a6e \
        --cri-socket unix:///var/run/containerd/containerd.sock

sudo systemctl enable --now kubelet

        sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.bak

        sudo sed -i 's/disabled_plugins = \["cri"\]/# disabled_plugins = \["cri"\]/' /etc/containerd/config.toml

https://v1-34.docs.kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd


        [plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.10"