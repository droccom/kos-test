# kos-test

This repo is about scale-testing of https://github.com/MikeSpreitzer/kube-examples/tree/add-kos/staging/kos

## Main Experiment

### Independent variables

- OPS: average operations per second from driver during cruise phase

- NCA: number of connection agents.  Values: 600, 1200, 1800.

- POP: cruise phase nominal number of NetworkAttachments.  Values 1X, 3X, 9X for as big an X as we can manage.

- NKA: number of kube-apiservers.  Values: 1, 3, 9.

- NNA: number of network-apiservers.  Values: 1, 3, 9.

### Dependent variables

We have two sorts of dependent variables: global and per-node.  There is one global dependent variable: latency from
(a) when the client starts to make a request to (b) when the connection agent fulfils the request.

The per-node variables are the following cost metrics.

- CPU usage
- memory usage
- network bytes in
- network bytes out

We plan on using single-purpose nodes.  We have the following purposes.  We care about the cost metrics from nodes that
run KOS or Kubernetes components.

- base: Operations base & run the driver
- obs: Run centralized logs/metrics services (if we have any of these)
- compNNNN: Run the KOS connection agent
- nctrlN: Run the KOS central controllers
- napiN: Run the KOS network-apiserver
- netcdN: Run the KOS etcd servers
- kctrlN: Run the Kubernetes central controllers
- kapiN: Run the kube-apiservers
- ketcdN: Run the kube etcd servers
