# Secured Distributed Bookinfo

In this demo we took Istio's [Bookinfo sample application](https://istio.io/docs/guides/bookinfo/) and configured our Multi-Cluster so that the `Productpage` and `Ratings` microservices are running on one cluster and the `Details` and `Reviews v1/v2/v3` are running on the other. This demonstrates a two way communication between the clusters as `Productpage`, for instance, is calling the `Reviews` service on the remote cluster while `Reviews v2/v3` themselves are calling the `Ratings` service from the first cluster.

The communication between the clusters is going through a set of Ingress and Egress Gateways that both clusters have by deploying Istio to each one of them.

__WORK IN PROGRESS!__ Currently this demo is not functional. Once I'm done with the security configuration to make this demo work I will update this page.