docker network create k8s-cluster-bridge

docker quay.io/footloose/ubuntu18.04

footloose -c k8s-cluster.yaml create

footloose -c k8s-cluster.yaml ssh root@node-0 -- "env INSTALL_K3S_SKIP_DOWNLOAD=true /root/install-k3s.sh --flannel-backend=none --cluster-cidr=192.168.0.0/16"

export K3S_TOKEN=$(footloose -c k8s-cluster.yaml ssh root@node-0 -- cat /var/lib/rancher/k3s/server/node-token)

footloose -c k8s-cluster.yaml ssh root@node-1 -- "env INSTALL_K3S_SKIP_DOWNLOAD=true env K3S_URL=https://node-0:6443 env K3S_TOKEN=$K3S_TOKEN /root/install-k3s.sh"

footloose -c k8s-cluster.yaml ssh root@node-2 -- "env INSTALL_K3S_SKIP_DOWNLOAD=true env K3S_URL=https://node-0:6443 env K3S_TOKEN=$K3S_TOKEN /root/install-k3s.sh"
