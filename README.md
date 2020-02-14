# kos-test

This repo is about scale-testing of https://github.com/MikeSpreitzer/kube-examples/tree/add-kos/staging/kos

## Main Experiment

### Independent variables

- OPS: average operations per second from driver during cruise phase.

- NCA: number of connection agents.  Values: 600, 1200, 1800.

- POP: cruise phase nominal number of NetworkAttachments.  Values 1X, 3X, 9X for as big an X as we can manage.

- NNA: number of network-apiservers.  Values: 1, 3, 9.

- NKA: number of kube-apiservers.  Values: 1, 3, 9 if it's interesting; just 3 if not.

### Dependent variables

We have two sorts of dependent variables: global and per-node.  There is one global dependent variable: latency from
(a) when the client starts to make a request to (b) when the connection agent fulfils the request.

The per-node variables are the following cost metrics.

- CPU usage
- memory usage
- network bytes in
- network bytes out

We plan on using single-purpose nodes; we care about the per-node cost metrics
only for the nodes corresponding to certain purposes.

The purposes for whom we plan to compute the cost metrics are:

- compN: Run the KOS connection agent
- nctrlN: Run the KOS central controllers (including etcd operator for KOS etcd servers)
- napiN: Run the KOS network-apiserver
- netcdN: Run the KOS etcd servers
- kctrlN: Run the Kubernetes central controllers (including the scheduler)
- kapiN: Run the kube-apiservers
- ketcdN: Run the kube etcd servers

The purposes for whom we won't compute the cost metrics are:

- base: Operations base & run the driver
- obs: Run centralized logs/metrics services (if we have any of these)
- data: Run Prometheus server

### Development configuration

One L0 host with 64 "CPUs", 512 GB of main memory, and no persistent storage.
L1 disks are implemented by QCOW2 that is backed by L0 memory.
Thus, L0 memory consumption by L1 disks grows over time according to usage.
20 L1 nodes.

| purpose | number | CPUs | mem GB |
| ------- | ------ | ---- | ------ |
| base    |   1    |   4  |   32   |
| ketcd   |   3    |   4  |   12   |
| kapi    |   1    |   4  |   12   |
| kctrl   |   1    |   2  |   12   |
| netcd   |   3    |   4  |   12   |
| napi    |   1    |   4  |   12   |
| nctrl   |   1    |   2  |   12   |
| data    |   1    |   2  |   12   |
| comp    |   8    |   2  |    8   |

## Operations

On your management machine let `/etc/ansible/hosts` be a directory
with various inventory files, writable by you.

### Kubectl configuration

On your laptop, there are two ways to make `kubectl` work without
explicit server or config arguments.  One is to `ssh
-L8080:localhost:8080 ...` to a host running a kube-apiserver with the
insecure port 8080 open.

Another is to
- copy a secured kubeconfig file to your laptop somewhere,
- change the server address inside it to `127.0.0.1`,
- `ssh -L6443:localhost:6443 ...` to a host running a kube-apiserver, and
- set your KUBECONFIG envar to point to the modified kubeconfig file.

### Creating an Ansible inventory file

While logged into your management machine, with this repo's directory
current, and `kubectl` addressing your cluster:

```
export clustername=somethingappropriate
ops/make-inventory.sh $clustername
```

Since the kubernetes-etcd nodes are not part of the kubernetes
cluster, an extra step is needed to get them in the ansible inventory.
Copy the relevant cluster-specific file from `ops/extra-inventory/`
into your `/etc/ansible/hosts`.

### Differentiating Kubernetes API and Control nodes

The Kubernetes deployment tech deploys all the master components
(kube-apiserver, kube-scheduler, kube-controller-manager) to both the
kapi and the kctrl nodes.  The following Ansible playbook usage trims
what is running on those nodes.

```
ansible-playbook ops/plays/diff-kctl.yaml -e clustername=$clustername
```

### Preparing Prometheus file-based service discovery of external etcd nodes

Define a configmap with a key named `file-sd` and a value appropriate
for your cluster.  The value should be a `<file_sd_config>` as defined
at
https://prometheus.io/docs/prometheus/latest/configuration/configuration/#file_sd_config
.

For example:

```
kubectl create cm prom-file-sd --from-file=file-sd.yaml=ops/prom-file-sd/r12s24-k14-xetcd.yaml
```

### Labeling nodes

While logged into your management machine, with this repo's directory
current, and `kubectl` addressing your cluster:

```
ops/label-nodes.sh
```

To display the results:
```
kubectl get Node -L kos-role/ketcd,kos-role/kapi,kos-role/kctrl,kos-role/netcd,kos-role/napi,kos-role/nctrl,kos-role/netcd-op,kos-role/comp,kos-role/data
```

### Installing cadvisor on the nodes

```
ansible-playbook ops/plays/install-cadvisor.yaml -e clustername=$clustername -f 8
```
