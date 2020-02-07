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

We plan on using single-purpose nodes.  We have the following purposes.  We care about the cost metrics from nodes that
run KOS or Kubernetes components.

- base: Operations base & run the driver
- obs: Run centralized logs/metrics services (if we have any of these)
- compN: Run the KOS connection agent
- nctrlN: Run the KOS central controllers
- napiN: Run the KOS network-apiserver
- netcdN: Run the KOS etcd servers
- kctrlN: Run the Kubernetes central controllers (including the scheduler)
- kapiN: Run the kube-apiservers
- ketcdN: Run the kube etcd servers

### Development configuration

20 VMs on a host with 64 "CPUs" and 512 GB of memory.

| purpose | number | CPUs | mem GB |
| ------- | ------ | ---- | ------ |
| base    |   1    |   4  |   32   |
| ketcd   |   3    |   4  |   20   |
| kapi    |   1    |   4  |   20   |
| kctrl   |   1    |   2  |   20   |
| netcd   |   3    |   4  |   20   |
| napi    |   1    |   4  |   20   |
| nctrl   |   1    |   2  |   20   |
| comp    |   9    |   2  |   20   |
