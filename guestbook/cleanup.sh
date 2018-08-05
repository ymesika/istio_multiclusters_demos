#!/bin/bash

set +e
set +x

. ./config.sh

# Delete what was created by install_app
kubectl delete -f $APP_DEMO_DIR/cluster-a/ --context=$CLUSTER_A
kubectl delete -f $APP_DEMO_DIR/cluster-b/ --context=$CLUSTER_B

# Delete what was created by configure_cross_cluster
kubectl delete -f cluster-admin/cluster-a/cross-cluster.yaml --context=$CLUSTER_A
kubectl delete -f cluster-admin/cluster-b/cross-cluster.yaml --context=$CLUSTER_B

# Delete what was created by setup_istio
kubectl delete -f cluster-admin/coredns.yaml --context=$CLUSTER_A
kubectl delete -f cluster-admin/coredns.yaml --context=$CLUSTER_B
kubectl delete -f $ISTIO_FILE_NAME --context=$CLUSTER_A
kubectl delete -f $ISTIO_FILE_NAME --context=$CLUSTER_B

# Delete what was created by create_ns
kubectl delete namespace istio-system --context=$CLUSTER_A
kubectl delete namespace istio-system --context=$CLUSTER_B
