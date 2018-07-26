#!/bin/bash

set +e
set +x

# IBM Cloud Private cluster context
#CLUSTER_A="cluster.local-context"
#INGRESS_A_TYPE="NodePort"

# EDIT ME - Cluster A Kubeconfig context
CLUSTER_A="cluster-a"

# EDIT ME - Cluster B Kubeconfig context
CLUSTER_B="cluster-b"


# Following variables shouldn't be when deploying on two IKS clusters
CLUSTER_A_NAME=`echo $CLUSTER_A | tr A-Z a-z` # Lower case of context name
INGRESS_A_TYPE="LoadBalancer"

CLUSTER_B_NAME=`echo $CLUSTER_B | tr A-Z a-z` # Lower case of context name
INGRESS_B_TYPE="LoadBalancer"

ADMIN_CLUSTER_DIR=cluster-admin
BOOKINFO_DEMO_DIR=app
ISTIO_FILE_NAME="../istio.yaml"

create_ns()
{
    kubectl create namespace istio-system --context=$CLUSTER_A
    kubectl create namespace istio-system --context=$CLUSTER_B
}

setup_istio()
{
    # Cluster A
    # Install Istio
    sed -e "s/__INGRESS_GATEWAY_TYPE__/$INGRESS_A_TYPE/g" \
        $ISTIO_FILE_NAME | kubectl --context=$CLUSTER_A apply -f -
    # Install CoreDNS
    kubectl apply -f $ADMIN_CLUSTER_DIR/cluster-a/coredns.yaml --context=$CLUSTER_A
    
    # Cluster B
    # Install Istio
    sed -e "s/__INGRESS_GATEWAY_TYPE__/$INGRESS_B_TYPE/g" \
        $ISTIO_FILE_NAME | kubectl --context=$CLUSTER_B apply -f -
    # Install CoreDNS
    kubectl apply -f $ADMIN_CLUSTER_DIR/cluster-b/coredns.yaml --context=$CLUSTER_B
}

configure_cross_cluster()
{
    # Cluster A
    CORE_DNS_IP=`kubectl get svc core-dns -n istio-system -o jsonpath='{.spec.clusterIP}' --context=$CLUSTER_A`
    if [ $INGRESS_B_TYPE = "NodePort" ]; then
	    INGRESS_B_IP=`kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}' --context=$CLUSTER_B`
	    INGRESS_B_PORT=`kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' --context=$CLUSTER_B`
    else
	    INGRESS_B_IP=`kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[*].ip}' --context=$CLUSTER_B`
	    INGRESS_B_PORT=80
    fi
	sed -e "s/INGRESS_IP_ADDRESS/$INGRESS_B_IP/g" \
	    -e "s/INGRESS_PORT/$INGRESS_B_PORT/g" \
		-e "s/CORE_DNS_IP/$CORE_DNS_IP/g" \
		$ADMIN_CLUSTER_DIR/cluster-a/cross-cluster.yaml | kubectl --context=$CLUSTER_A apply -f -

    # Cluster B
    CORE_DNS_IP=`kubectl get svc core-dns -n istio-system -o jsonpath='{.spec.clusterIP}' --context=$CLUSTER_B`
    if [ $INGRESS_A_TYPE = "NodePort" ]; then
	    INGRESS_A_IP=`kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}' --context=$CLUSTER_A`
	    INGRESS_A_PORT=`kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' --context=$CLUSTER_A`
    else
	    INGRESS_A_IP=`kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[*].ip}' --context=$CLUSTER_A`
	    INGRESS_A_PORT=80
    fi
	sed -e "s/INGRESS_IP_ADDRESS/$INGRESS_A_IP/g" \
	    -e "s/INGRESS_PORT/$INGRESS_A_PORT/g" \
		-e "s/CORE_DNS_IP/$CORE_DNS_IP/g" \
		$ADMIN_CLUSTER_DIR/cluster-b/cross-cluster.yaml | kubectl  --context=$CLUSTER_B apply -f -
}

bookinfo_app()
{
    echo "Install Bookinfo.."

    for yaml in $BOOKINFO_DEMO_DIR/cluster-a/*.yaml
    do
        kubectl apply -f $yaml --context=$CLUSTER_A
    done

    for yaml in $BOOKINFO_DEMO_DIR/cluster-b/*.yaml
    do
        kubectl apply -f $yaml --context=$CLUSTER_B
    done
}

echo "Installing Istio.."
create_ns
setup_istio

echo
echo "Make sure Istio pods are up and running on both clusters."
echo "Press any key to continue.."
read -n 1 -s

echo "Configuring cross-cluster.."
configure_cross_cluster

echo "Installing the Bookinfo app.."
bookinfo_app

echo
echo "Multi-Clustered Bookinfo is ready"
echo "URL: http://$INGRESS_A_IP:$INGRESS_A_PORT/productpage"