DOCKER_PREFIX=mspreitz
DOCKER_TAG=bf325084e7187592607677f4aae2d912edce0f9f
KOS_PERSIST=${HOME}/.kos-perf-study
SMALL=false

clean: noinst
	rm -rf "${KOS_PERSIST}/tls"

noinst:
	rm -f deploy/main/[57]0-*

%.key:
	mkdir -p $$(dirname $@)
	openssl genrsa -out $@ 4096

# Carefully engineered to work on both MacOS X and Linux,
# which differ in their interpretation of `-i` and vary
# in default and arguments regarding line wrapping.
%.b64: %
	[ $$(uname) = Darwin ] && base64 -i "$<" -o "$@" || base64 -w 0 "$<" > "$@"

${KOS_PERSIST}/tls/ca.pem: ${KOS_PERSIST}/tls/ca.key
	cd "${KOS_PERSIST}/tls" && \
	echo 01 > ca.srl && \
	openssl req -x509 -new -nodes -key ca.key -days 10000 \
		-out ca.pem -subj "/CN=kos-ca"

${KOS_PERSIST}/tls/etcd/peer.crt: ${KOS_PERSIST}/tls/ca.key ${KOS_PERSIST}/tls/ca.pem ${KOS_PERSIST}/tls/etcd/peer.key tls/etcd/cnf/peer.cnf
	openssl req -new -key "${KOS_PERSIST}/tls/etcd/peer.key" \
		-out "${KOS_PERSIST}/tls/etcd/peer.csr" -subj "/CN=kos-etcd-peer" \
		-config tls/etcd/cnf/peer.cnf && \
	openssl x509 -req -in "${KOS_PERSIST}/tls/etcd/peer.csr" \
		-CA "${KOS_PERSIST}/tls/ca.pem" \
		-CAserial "${KOS_PERSIST}/tls/ca.srl" \
		-CAkey "${KOS_PERSIST}/tls/ca.key" \
		-out "${KOS_PERSIST}/tls/etcd/peer.crt" \
		-days 1500 -extensions v3_req \
		-extfile tls/etcd/cnf/peer.cnf && \
	rm "${KOS_PERSIST}/tls/etcd/peer.csr"

${KOS_PERSIST}/tls/etcd/server.crt: ${KOS_PERSIST}/tls/ca.key ${KOS_PERSIST}/tls/ca.pem ${KOS_PERSIST}/tls/etcd/server.key tls/etcd/cnf/server.cnf
	openssl req -new -key "${KOS_PERSIST}/tls/etcd/server.key" \
		-out "${KOS_PERSIST}/tls/etcd/server.csr" \
		-subj "/CN=kos-etcd-server" \
		-config tls/etcd/cnf/server.cnf && \
	openssl x509 -req -in "${KOS_PERSIST}/tls/etcd/server.csr" \
		-CA "${KOS_PERSIST}/tls/ca.pem" \
		-CAserial "${KOS_PERSIST}/tls/ca.srl" \
		-CAkey "${KOS_PERSIST}/tls/ca.key" \
		-out "${KOS_PERSIST}/tls/etcd/server.crt" \
		-days 1500 -extensions v3_req \
		-extfile tls/etcd/cnf/server.cnf && \
	rm "${KOS_PERSIST}/tls/etcd/server.csr"

${KOS_PERSIST}/tls/etcd/client.crt: ${KOS_PERSIST}/tls/ca.key ${KOS_PERSIST}/tls/ca.pem ${KOS_PERSIST}/tls/etcd/client.key tls/etcd/cnf/client.cnf
	openssl req -new -key "${KOS_PERSIST}/tls/etcd/client.key" \
		-out "${KOS_PERSIST}/tls/etcd/client.csr" \
		-subj "/CN=kos-etcd-client" \
		-config tls/etcd/cnf/client.cnf && \
	openssl x509 -req -in "${KOS_PERSIST}/tls/etcd/client.csr" \
		-CA "${KOS_PERSIST}/tls/ca.pem" \
		-CAserial "${KOS_PERSIST}/tls/ca.srl" \
		-CAkey "${KOS_PERSIST}/tls/ca.key" \
		-out "${KOS_PERSIST}/tls/etcd/client.crt" \
		-days 1500 -extensions v3_req \
		-extfile tls/etcd/cnf/client.cnf && \
	rm "${KOS_PERSIST}/tls/etcd/client.csr"

${KOS_PERSIST}/tls/network-api/server.crt: ${KOS_PERSIST}/tls/ca.key ${KOS_PERSIST}/tls/ca.pem ${KOS_PERSIST}/tls/network-api/server.key tls/network-api/cnf/server.cnf
	openssl req -new -key "${KOS_PERSIST}/tls/network-api/server.key" \
		-out "${KOS_PERSIST}/tls/network-api/server.csr" \
		-subj "/CN=network-api.example-com.svc" \
		-config tls/network-api/cnf/server.cnf && \
	openssl x509 -req -in "${KOS_PERSIST}/tls/network-api/server.csr" \
		-CA "${KOS_PERSIST}/tls/ca.pem" \
		-CAserial "${KOS_PERSIST}/tls/ca.srl" \
		-CAkey "${KOS_PERSIST}/tls/ca.key" \
		-out "${KOS_PERSIST}/tls/network-api/server.crt" \
		-days 1500 -extensions v3_req \
		-extfile tls/network-api/cnf/server.cnf && \
	rm "${KOS_PERSIST}/tls/network-api/server.csr"

${KOS_PERSIST}/tls/etcd/peer-secret.yaml:  ${KOS_PERSIST}/tls/ca.pem.b64 ${KOS_PERSIST}/tls/etcd/peer.key.b64 ${KOS_PERSIST}/tls/etcd/peer.crt.b64 tls/etcd/peer-secret.yaml.m4
	m4	-DPEER_CRT=$$(cat ${KOS_PERSIST}/tls/etcd/peer.crt.b64) \
		-DPEER_KEY=$$(cat ${KOS_PERSIST}/tls/etcd/peer.key.b64) \
		-DCA_CRT=$$(cat ${KOS_PERSIST}/tls/ca.pem.b64) \
		tls/etcd/peer-secret.yaml.m4 > ${KOS_PERSIST}/tls/etcd/peer-secret.yaml

${KOS_PERSIST}/tls/etcd/server-secret.yaml:  ${KOS_PERSIST}/tls/ca.pem.b64 ${KOS_PERSIST}/tls/etcd/server.key.b64 ${KOS_PERSIST}/tls/etcd/server.crt.b64 tls/etcd/server-secret.yaml.m4
	m4	-DSERVER_CRT=$$(cat ${KOS_PERSIST}/tls/etcd/server.crt.b64) \
		-DSERVER_KEY=$$(cat ${KOS_PERSIST}/tls/etcd/server.key.b64) \
		-DCA_CRT=$$(cat ${KOS_PERSIST}/tls/ca.pem.b64) \
		tls/etcd/server-secret.yaml.m4 > ${KOS_PERSIST}/tls/etcd/server-secret.yaml

${KOS_PERSIST}/tls/etcd/client-secret.yaml:  ${KOS_PERSIST}/tls/ca.pem.b64 ${KOS_PERSIST}/tls/etcd/client.key.b64 ${KOS_PERSIST}/tls/etcd/client.crt.b64 tls/etcd/client-secret.yaml.m4
	m4	-DCLIENT_CRT=$$(cat ${KOS_PERSIST}/tls/etcd/client.crt.b64) \
		-DCLIENT_KEY=$$(cat ${KOS_PERSIST}/tls/etcd/client.key.b64) \
		-DCA_CRT=$$(cat ${KOS_PERSIST}/tls/ca.pem.b64) \
		tls/etcd/client-secret.yaml.m4 > ${KOS_PERSIST}/tls/etcd/client-secret.yaml

${KOS_PERSIST}/tls/network-api/server-bundle: ${KOS_PERSIST}/tls/network-api/server.crt ${KOS_PERSIST}/tls/ca.pem
	cat ${KOS_PERSIST}/tls/network-api/server.crt ${KOS_PERSIST}/tls/ca.pem > ${KOS_PERSIST}/tls/network-api/server-bundle

${KOS_PERSIST}/tls/network-api/server-secret.yaml: ${KOS_PERSIST}/tls/network-api/server.key.b64 ${KOS_PERSIST}/tls/network-api/server-bundle.b64 tls/network-api/server-secret.yaml.m4
	m4	-DSERVER_AND_CA_CRTS=$$(cat ${KOS_PERSIST}/tls/network-api/server-bundle.b64) \
		-DSERVER_KEY=$$(cat ${KOS_PERSIST}/tls/network-api/server.key.b64) \
		tls/network-api/server-secret.yaml.m4 > ${KOS_PERSIST}/tls/network-api/server-secret.yaml

${KOS_PERSIST}/tls/network-api/client-secret.yaml:  ${KOS_PERSIST}/tls/ca.pem.b64 tls/network-api/client-secret.yaml.m4
	m4 -DCA_CRT=$$(cat ${KOS_PERSIST}/tls/ca.pem.b64) \
		tls/network-api/client-secret.yaml.m4 > ${KOS_PERSIST}/tls/network-api/client-secret.yaml

deploy/main/50-d-xs.yaml: deploy.m4/main/50-d-xs.yaml.m4
	m4 -DDOCKER_PREFIX=${DOCKER_PREFIX} -DDOCKER_TAG=${DOCKER_TAG} deploy.m4/main/50-d-xs.yaml.m4 > deploy/main/50-d-xs.yaml

deploy/main/50-ds-ca.yaml: deploy.m4/main/50-ds-ca.yaml.m4
	m4 -DDOCKER_PREFIX=${DOCKER_PREFIX} -DDOCKER_TAG=${DOCKER_TAG} -DSMALL=${SMALL} deploy.m4/main/50-ds-ca.yaml.m4 > deploy/main/50-ds-ca.yaml

deploy/main/50-d-kcm.yaml: deploy.m4/main/50-d-kcm.yaml.m4
	m4 -DDOCKER_PREFIX=${DOCKER_PREFIX} -DDOCKER_TAG=${DOCKER_TAG} deploy.m4/main/50-d-kcm.yaml.m4 > deploy/main/50-d-kcm.yaml

deploy/main/70-apiservice.yaml: deploy.m4/main/70-apiservice.yaml.m4 ${KOS_PERSIST}/tls/ca.pem.b64
	m4 -DCA_CRT=$$(cat ${KOS_PERSIST}/tls/ca.pem.b64) \
		deploy.m4/main/70-apiservice.yaml.m4 > deploy/main/70-apiservice.yaml

.PHONY: deploy-etcd
deploy-etcd: ${KOS_PERSIST}/tls/etcd/peer-secret.yaml ${KOS_PERSIST}/tls/etcd/server-secret.yaml ${KOS_PERSIST}/tls/etcd/client-secret.yaml
	kubectl apply -f deploy/ns && \
	kubectl apply -f deploy/etcd-operator-rbac && \
	kubectl apply -f ${KOS_PERSIST}/tls/etcd/peer-secret.yaml && \
	kubectl apply -f ${KOS_PERSIST}/tls/etcd/server-secret.yaml && \
	kubectl apply -f ${KOS_PERSIST}/tls/etcd/client-secret.yaml && \
	kubectl apply -f deploy/etcd-operator && \
	while ! kubectl get EtcdCluster ; do sleep 5 ; done && \
	kubectl apply -f deploy/etcd-cluster && \
	while [ "$$(kubectl get EtcdCluster -n example-com   the-etcd-cluster -o 'jsonpath={.status.conditions[?(@.type=="Available")].status}')" != True ]; do kubectl get Pod -n example-com -l etcd_cluster=the-etcd-cluster -o wide; date; echo; sleep 30; done
	while [ "$$(kubectl get EtcdCluster -n example-com   the-etcd-cluster-2 -o 'jsonpath={.status.conditions[?(@.type=="Available")].status}')" != True ]; do kubectl get Pod -n example-com -l etcd_cluster=the-etcd-cluster-2 -o wide; date; echo; sleep 30; done

.PHONY: deploy
deploy: deploy/main/50-d-xs.yaml deploy/main/50-ds-ca.yaml deploy/main/50-d-kcm.yaml deploy/main/70-apiservice.yaml ${KOS_PERSIST}/tls/network-api/server-secret.yaml ${KOS_PERSIST}/tls/network-api/client-secret.yaml deploy-etcd
	kubectl apply -f ${KOS_PERSIST}/tls/network-api/server-secret.yaml && \
	kubectl apply -f ${KOS_PERSIST}/tls/network-api/client-secret.yaml && \
	kubectl apply -f deploy/main

.PHONY: undeploy
undeploy: deploy/main/50-d-xs.yaml deploy/main/50-ds-ca.yaml deploy/main/50-d-kcm.yaml deploy/main/70-apiservice.yaml ${KOS_PERSIST}/tls/network-api/server-secret.yaml ${KOS_PERSIST}/tls/network-api/client-secret.yaml ${KOS_PERSIST}/tls/etcd/peer-secret.yaml ${KOS_PERSIST}/tls/etcd/server-secret.yaml ${KOS_PERSIST}/tls/etcd/client-secret.yaml
	kubectl delete --ignore-not-found -f deploy/main && \
	kubectl delete --ignore-not-found -f ${KOS_PERSIST}/tls/network-api/server-secret.yaml && \
	kubectl delete --ignore-not-found -f ${KOS_PERSIST}/tls/network-api/client-secret.yaml && \
	! kubectl get EtcdCluster || kubectl delete --ignore-not-found -f deploy/etcd-cluster && \
	while kubectl get EtcdCluster -n example-com the-etcd-cluster ; do sleep 15; done && \
	while kubectl get EtcdCluster -n example-com the-etcd-cluster-2 ; do sleep 15; done && \
	kubectl delete --ignore-not-found -f deploy/etcd-operator && \
	kubectl delete --ignore-not-found Endpoints etcd-operator && \
	kubectl delete --ignore-not-found crd etcdclusters.etcd.database.coreos.com && \
	kubectl delete --ignore-not-found -f ${KOS_PERSIST}/tls/etcd/peer-secret.yaml && \
	kubectl delete --ignore-not-found -f ${KOS_PERSIST}/tls/etcd/server-secret.yaml && \
	kubectl delete --ignore-not-found -f ${KOS_PERSIST}/tls/etcd/client-secret.yaml && \
	kubectl delete --ignore-not-found -f deploy/etcd-operator-rbac && \
	kubectl delete --ignore-not-found -f deploy/ns

# The following just document how these files were originally made.
# FYI, this what when master pointed to commit aeb3e3e0835ec5135cfe50340f59853b5b6fc407

deploy/etcd-operator-rbac/47-eo-role.yaml:
	curl https://raw.githubusercontent.com/coreos/etcd-operator/master/example/rbac/cluster-role-template.yaml | sed -e "s/<ROLE_NAME>/kos-etcd-operator/g" > deploy/etcd-operator-rbac/47-eo-role.yaml

deploy/etcd-operator-rbac/47-eo-rolebind.yaml:
	curl https://raw.githubusercontent.com/coreos/etcd-operator/master/example/rbac/cluster-role-binding-template.yaml | sed -e "s/<ROLE_NAME>/kos-etcd-operator/g" -e "s/<ROLE_BINDING_NAME>/kos-etcd-operator/g" -e "s/<NAMESPACE>/example-com/g" > deploy/etcd-operator-rbac/47-eo-rolebind.yaml

