apiVersion: apps/v1
kind: Deployment
metadata:
  name: network-apiserver
  namespace: example-com
spec:
  replicas: 1
  selector:
    matchLabels:
      kos-app: network-apiserver
  template:
    metadata:
      labels:
        kos-app: network-apiserver
    spec:
      serviceAccountName: network-apiserver
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: kubernetes.io/hostname
            labelSelector:
              matchLabels:
                kos-app: network-apiserver
      nodeSelector:
        kos-role/napi: "true"
      containers:
      - name: apiserver
        image: DOCKER_PREFIX/kos-network-apiserver:DOCKER_TAG
        imagePullPolicy: Always
        volumeMounts:
        - name: network-api-certs
          mountPath: /network-api-certs
          readOnly: true
        - name: etcd-certs
          mountPath: /etcd-certs
          readOnly: true
        command:
        - /network-apiserver
        - --tls-cert-file=/network-api-certs/server-and-ca.crt
        - --tls-private-key-file=/network-api-certs/server.key
        - --etcd-servers=https://the-etcd-cluster-client:2379
        - --etcd-certfile=/etcd-certs/etcd-client.crt
        - --etcd-keyfile=/etcd-certs/etcd-client.key
        - --etcd-cafile=/etcd-certs/etcd-client-ca.crt
        - --etcd-servers-overrides=network.example.com/iplocks#https://the-etcd-cluster-2-client:2379
        - --default-watch-cache-size=1000
        - -v=5
      volumes:
      - name: network-api-certs
        secret:
          secretName: network-api
      - name: etcd-certs
        secret:
          secretName: etcd-client
