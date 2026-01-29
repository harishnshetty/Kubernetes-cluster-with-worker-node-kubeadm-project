## Backup

etcdctl snapshot save /home/harish/etcd-snapshot.db


etcdctl --endpoints=https://127.0.0.1:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key snapshot save /home/harish/etcd-snapshot.db

## Restore

etcdutl --data-dir /var/lib/etcd snapshot restore /home/harish/etcd-snapshot.db


etcdctl snapshot restore /home/harish/etcd-snapshot.db


etcdctl --endpoints=https://127.0.0.1:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key snapshot restore /home/harish/etcd-snapshot.db


cd /etc/kubernetes/manifests

ls -l
nano etcd.yaml


stroedir: /var/lib/etcd
etcd




https://etcd.io/

https://github.com/etcd-io/etcd/releases/


```bash
wget https://github.com/etcd-io/etcd/releases/download/v3.6.7/etcd-v3.6.7-linux-amd64.tar.gz
tar -xvf etcd-v3.6.7-linux-amd64.tar.gz
sudo mv etcd-v3.6.7-linux-amd64/etcdutl /usr/local/bin/
```

etcdutl --data-dir /var/lib/etcd-new snapshot restore /home/harish/etcd-snapshot.db

