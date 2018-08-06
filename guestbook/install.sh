#!/bin/bash

set +e
set +x

. ./config.sh

CLUSTER_A_NAME=`echo $CLUSTER_A | tr A-Z a-z` # Lower case of context name
CLUSTER_B_NAME=`echo $CLUSTER_B | tr A-Z a-z` # Lower case of context name

create_ns()
{
    kubectl create namespace istio-system --context=$CLUSTER_A
    kubectl create namespace istio-system --context=$CLUSTER_B
}

setup_istio()
{
    # Cluster A
    # Install Istio
    sed -e "s/__INGRESS_GATEWAY_TYPE__/LoadBalancer/g" \
        $ISTIO_FILE_NAME | kubectl --context=$CLUSTER_A apply -f -
    # Install CoreDNS
    kubectl apply -f $ADMIN_CLUSTER_DIR/coredns.yaml --context=$CLUSTER_A
    
    # Cluster B
    # Install Istio
    if [ $CLUSTER_B_TYPE = "ICP" ]; then
        INGRESS_B_TYPE="NodePort"
    else
	    INGRESS_B_TYPE="LoadBalancer"
    fi
    sed -e "s/__INGRESS_GATEWAY_TYPE__/$INGRESS_B_TYPE/g" \
        $ISTIO_FILE_NAME | kubectl --context=$CLUSTER_B apply -f -
    # Install CoreDNS
    kubectl apply -f $ADMIN_CLUSTER_DIR/coredns.yaml --context=$CLUSTER_B
}

configure_cross_cluster()
{
    # Cluster A
    CORE_DNS_IP=`kubectl get svc core-dns -n istio-system -o jsonpath='{.spec.clusterIP}' --context=$CLUSTER_A`
    if [ $CLUSTER_B_TYPE = "ICP" ]; then
        INGRESS_B_IP=`kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.clusterIP}' --context=$CLUSTER_B`
        INGRESS_B_PORT=`kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="http2")].port}' --context=$CLUSTER_B`
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
    INGRESS_A_IP=`kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[*].ip}' --context=$CLUSTER_A`
	INGRESS_A_PORT=80
	sed -e "s/INGRESS_IP_ADDRESS/$INGRESS_A_IP/g" \
	    -e "s/INGRESS_PORT/$INGRESS_A_PORT/g" \
		-e "s/CORE_DNS_IP/$CORE_DNS_IP/g" \
		$ADMIN_CLUSTER_DIR/cluster-b/cross-cluster.yaml | kubectl  --context=$CLUSTER_B apply -f -
}

install_app()
{
    echo "Install App.."

    for yaml in $APP_DEMO_DIR/cluster-a/*.yaml
    do
        if [ "$MANUAL_INJECTION" = true ]; then
            kubectl apply --context=$CLUSTER_A -f <(../istioctl kube-inject -f $yaml)
        else
            kubectl apply --context=$CLUSTER_A -f $yaml
        fi
    done

    for yaml in $APP_DEMO_DIR/cluster-b/*.yaml
    do
        if [ "$MANUAL_INJECTION" = true ]; then
            kubectl apply --context=$CLUSTER_B -f <(../istioctl kube-inject --context $CLUSTER_B \
                -f <(sed -e "s/__TONE_ANALYZER_USERNAME__/$TONE_ANALYZER_USERNAME/g" \
                -e "s/__TONE_ANALYZER_PASSWORD__/$TONE_ANALYZER_PASSWORD/g" $yaml))
        else
            kubectl apply --context=$CLUSTER_B -f $yaml
            sed -e "s/__TONE_ANALYZER_USERNAME__/$TONE_ANALYZER_USERNAME/g" \
            -e "s/__TONE_ANALYZER_PASSWORD__/$TONE_ANALYZER_PASSWORD/g" \
            $yaml | kubectl --context=$CLUSTER_B apply -f -
        fi
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

echo "Installing the app.."
install_app

echo
echo "Multi-Clustered is ready"
echo "URL: http://$INGRESS_A_IP"
