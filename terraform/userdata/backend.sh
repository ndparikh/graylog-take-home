#!/bin/bash
exec > /var/log/user-data.log 2>&1

set -o xtrace
yum -y update

/etc/eks/bootstrap.sh --apiserver-endpoint '${cluster_endpoint}' --b64-cluster-ca '${b64_cluster_ca}' '${cluster_name}' --kubelet-extra-args ' --node-labels=type=backend_workers \
--system-reserved cpu=250m,memory=0.5Gi,ephemeral-storage=1Gi \
--kube-reserved cpu=250m,memory=0.5Gi,ephemeral-storage=1Gi \
--eviction-hard memory.available<0.2Gi,nodefs.available<10%'
