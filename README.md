# Istio Multi-Clusters Demos
A bunch of demos that show how to install and configure Istio on a Multi-Clusters environment.

The approach taken in this demos is to use the Istio Ingress and Egress Gateways to integrate two clusters. This is different than the one used with [Istio Multicluster](https://istio.io/docs/setup/kubernetes/multicluster-install/) and can be used for cases when the [Istio Multicluster Prerequisites](https://istio.io/docs/setup/kubernetes/multicluster-install/#prerequisites) can't be fulfilled, when its design of one big mesh isn't desired or as an alternative way to deploy Multi-Cluster.

The following demos are available:
* [Distributed Bookinfo](bookinfo/README.md) - This demonstrates the use of Istio ingress/egress gatways to integrate two clusters where both of them are public (e.g. IBM Kubernets Clusters) or one of them is private (e.g. IBM Cloud Private).
* [Secured Distributed Bookinfo](bookinfo_secured/README.md) - Similar to the Distributed Bookinfo demo with the change of using a Root CA to enable an end-to-end secured communication.

# Credits
The demos in this repository are based on work done by @rshriram [https://github.com/rshriram/istio_federation_demo] and @ZackButcher [https://github.com/ZackButcher/hybrid-demo].
