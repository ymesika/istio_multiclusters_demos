#!/bin/bash

set +e
set +x

# EDIT ME - Cluster A Kubeconfig context
CLUSTER_A="cluster-a"

# EDIT ME - Cluster B Kubeconfig context
CLUSTER_B="cluster-b"

BOOKINFO_DEMO_DIR="app"
ISTIO_FILE_NAME="../istio.yaml"

# Delete what was created by bookinfo_app
for yaml in $BOOKINFO_DEMO_DIR/cluster-a/*.yaml
do
    kubectl delete -f $yaml --context=$CLUSTER_A
done

for yaml in $BOOKINFO_DEMO_DIR/cluster-b/*.yaml
do
    kubectl delete -f $yaml --context=$CLUSTER_B
done

# Delete what was created by configure_cross_cluster
kubectl delete -f cluster-admin/cluster-a/cross-cluster.yaml --context=$CLUSTER_A
kubectl delete -f cluster-admin/cluster-b/cross-cluster.yaml --context=$CLUSTER_B

# Delete what was created by setup_istio
kubectl delete -f cluster-admin/cluster-a/coredns.yaml --context=$CLUSTER_A
kubectl delete -f cluster-admin/cluster-b/coredns.yaml --context=$CLUSTER_B
kubectl delete -f $ISTIO_FILE_NAME --context=$CLUSTER_A
kubectl delete -f $ISTIO_FILE_NAME --context=$CLUSTER_B

# Delete what was created by create_ns
kubectl delete namespace istio-system --context=$CLUSTER_A
kubectl delete namespace istio-system --context=$CLUSTER_B