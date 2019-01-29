- [Building a Kubernetes Cluster](#h:DA34BC11)
    - [Define cluster with cluster.tf](#h:F44D1317)
    - [Create VMs with kube-setup.sh](#h:0C658E7B)
    - [Install Kubernetes with kube-setup2.sh](#h:05F9D0A2)
    - [Check Master Node](#h:D833684A)
    - [Adding Nodes to Cluster](#orgedac321)
    - [Removing Nodes to Cluster](#org7e048af)


<a id="h:DA34BC11"></a>

# Building a Kubernetes Cluster

It is possible to create a Kubernetes cluster with the Docker container described here. We employ [Andrea Zonca's modification of the kubespray project](https://github.com/zonca/jetstream_kubespray). Andrea's recipe to build a Kubernetes cluster on Jetstream with kubespray is described [here](https://zonca.github.io/2018/09/kubernetes-jetstream-kubespray.html). These instructions have been codified with the `kube-setup.sh` and `kube-setup2.sh` scripts.


<a id="h:F44D1317"></a>

## Define cluster with cluster.tf

First, modify `~/jetstream_kubespray/inventory/zonca_kubespray/cluster.tf` to specify the number of nodes in the cluster and the size (flavor) of the VMs. For example,

```sh
# nodes
number_of_k8s_nodes = 0
number_of_k8s_nodes_no_floating_ip = 2
flavor_k8s_node = "4"
```

will create a 2 node cluster of m1.large VMs. [See Andrea's instructions for more details](https://zonca.github.io/2018/09/kubernetes-jetstream-kubespray.html).

`openstack flavor list` will gives the IDs of the desired VM size.

Also, note that `cluster.tf` assumes you are building a cluster at the TACC data center with the sections pertaining to IU commented out. If you would like to set up a cluster at IU, make the necessary modifications located at the end of `cluster.tf`.


<a id="h:0C658E7B"></a>

## Create VMs with kube-setup.sh

At this point, to create the VMs that will house the kubernetes cluster (named "k8s-unidata", for example) run

`kube-setup.sh -n k8s-unidata`

This script essentially wraps terraform install scripts to launch the VMs according to `cluster.tf`.

Sometimes, this process does not go completely smoothly with VMs stuck in `ERROR` state. You may be able to fix this problem with:

```sh
cd ./jetstream_kubespray/inventory/k8s-unidata/
CLUSTER=k8s-unidata bash -c 'sh terraform_apply.sh'
```

Once, the script is complete, let the VMs settle for a while (let's say an hour). Behind the scenes `dpkg` is running on the newly created VMs which can take some time to complete.


<a id="h:05F9D0A2"></a>

## Install Kubernetes with kube-setup2.sh

Next, run

`kube-setup2.sh -n k8s-unidata`

If seeing errors related to `dpkg`, wait and try again.

If this command is still giving errors, try rebooting VMs with:

```sh
osl | grep k8s-unidata | awk '{print $2}' | xargs -n1 openstack server reboot
```

and running `kube-setup2.sh -n k8s-unidata` again.


<a id="h:D833684A"></a>

## Check Master Node

`ssh` into master node of cluster (discover the IP through `openstack server list`) and run:

```
kubectl get pods --all-namespaces
```

to ensure the Kubernetes cluster is running.


<a id="orgedac321"></a>

## Adding Nodes to Cluster

You can augment the computational capacity of your cluster by adding nodes. In theory, this is just a simple matter of adding worker nodes in `cluster.tf` followed by running

```sh
cd ./jetstream_kubespray/inventory/k8s-unidata/
CLUSTER=k8s-unidata bash -c 'sh terraform_apply.sh'
```

and

`kube-setup2.sh -n k8s-unidata`

The problem is the latter command may give errors pertaining to unavailable namespaces in the Kubernetes cluster. If this happens, you may have to try again a few times until it works.


<a id="org7e048af"></a>

## Removing Nodes to Cluster

It is also possible to remove nodes from a Kubernetes cluster. From the Kubernetes master node:

```sh
kubectl get nodes
kubectl drain <node-name> --ignore-daemonsets
```

followed by running

`teardown.sh -n <VM name of node>`
