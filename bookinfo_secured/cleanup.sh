#!/bin/bash

set +e
set +x

. ./config.sh

# Delete what was created by test_app
kubectl delete -f $TEST_SERVER_DIR/cluster-a/app.yaml --context=$CLUSTER_A
kubectl delete -f $TEST_SERVER_DIR/cluster-b/app.yaml --context=$CLUSTER_B

# Delete what was created by configure_cross_cluster
kubectl delete -f $ADMIN_CLUSTER_DIR/cluster-a/cross-cluster.yaml --context=$CLUSTER_A
kubectl delete -f $ADMIN_CLUSTER_DIR/cluster-b/cross-cluster.yaml --context=$CLUSTER_B

# Delete what was created by setup_istio
kubectl delete -f $ADMIN_CLUSTER_DIR/cluster-a/coredns.yaml --context=$CLUSTER_A
kubectl delete -f $ADMIN_CLUSTER_DIR/cluster-b/coredns.yaml --context=$CLUSTER_B

# Delete what was created by setup_root_ca
kubectl delete -f $ADMIN_CLUSTER_DIR/root-ca/istio-standalone-service.yaml --context=$CLUSTER_A
kubectl delete -f $ADMIN_CLUSTER_DIR/root-ca/istio-standalone-service.yaml --context=$CLUSTER_B
kubectl delete -f $ADMIN_CLUSTER_DIR/root-ca/istio-citadel-standalone.yaml --context=$ROOT_CA_CTX

# Delete what was created by create_ns
kubectl delete namespace istio-system --context=$CLUSTER_A
kubectl delete namespace istio-system --context=$CLUSTER_B
