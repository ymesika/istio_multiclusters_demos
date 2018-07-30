#!/bin/bash

kubectl get secret -n istio-system --context=$1 | grep "istio.io/key-and-cert" |  while read -r entry; do
  name=$(echo $entry | awk '{print $1}')
  echo "Deleting secret with name: $name"
  kubectl delete secret $name -n istio-system --context=$1
done
