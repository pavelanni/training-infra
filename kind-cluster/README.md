# Kind Kubernetes cluster

With this cluster you can practice and demonstrate MinIO features such as:

* Kubernetes Operator
* Monitoring and Alerts
* Multi-tenant deployment
* Multi-node multi-drive configurations
* DirectPV storage class

In addition to that you can test and demonstrate MinIO Enterprise Object Store's features such as:

* Catalog
* Firewall
* Key Management System
* Cache
* Observability
* Enterprise Console

The following instructions cover installation on a macOS system as it's the most common platform among MinIO engineers.
Linux installation is similar (even simpler) and you can easily figure it out from the following instructions.

## Install Podman

We recommend using Podman on a Mac because it's free of charge (unlike Docker Desktop).

Install Podman Desktop: https://podman-desktop.io/docs/installation/macos-install
It's the easiest way to get Podman on a Mac with a nice GUI and several useful extensions such as Podman Compose (compatible with Docker Compose).

### Configure the virtual machine

On a Mac Podman creates a Linux virtual machine using Lima (https://lima-vm.io/) and runs all containers in it.
For a typical MinIO cluster we need at least one control plane node and four worker nodes.
We recommend configuring at least 4 CPU and 10 GB or RAM in the Podman machine.
Click the cog icon in the left-bottom corner of Podman Desktop (**Settings**)  and pick **Resources**.
Edit the Podman Machine resources and save it.
The machine will restart automatically.

## Install Kind

On a Mac the easiest way is to install Kind via Homebrew:

```shell
brew install kind
```

## Kind cluster configurations

Install a Kind cluster using one of the config provided in the `configs` directory.

All configs create a cluster with one control plane node and four worker nodes.

* `kind-config-nodeport.yaml` uses the `extraPortMappings` feature to make it possible to use NodePort type services in the cluster.
* `kind-config-ingress.yaml` prepares the cluster for using Ingress configurations.
* `kind-config-mounts.yaml` demonstrates how to use your host directories inside the cluster.

Create a NodePort cluster with the follosing command:

```shell
kind create cluster --config configs/kind-config-nodeport.yaml
```

## Cloud provider for Kind

When running applications on a Kind cluster you can access them via Services but only from within the cluster.
You can add an Ingress to the deployment, but that requires additional setup.
The Cloud Provider is another option that gives you a cloud-like experience where your Services configured
as LoadBalancer become accessible via an External IP.

Follow the instalaltion instructions from here: https://github.com/kubernetes-sigs/cloud-provider-kind?tab=readme-ov-file#install

After that the services with `type: LoadBalancer` that you create will be exposed with an `EXTERNAL-IP` which you'll be able
to access via a browser.

Make sure you read this part: https://github.com/kubernetes-sigs/cloud-provider-kind?tab=readme-ov-file#mac-and-windows-support
TL;DR: use `sudo` to run it on a Mac.
