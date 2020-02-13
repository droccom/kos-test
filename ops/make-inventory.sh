#!/bin/bash

if (( $# != 1 )); then
	echo Usage: %0 clustername >&2
	exit 1
fi

echo "[$1]" > "/etc/ansible/hosts/$1"
kubectl get Node -o $'jsonpath={range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} nodename={.metadata.name}\n{end}' >> "/etc/ansible/hosts/$1"
