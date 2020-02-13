#!/bin/bash

kubectl get node --no-headers -o custom-columns=Name:.metadata.name | while read nodename; do
	if false; then
		:
	elif egrep 'ketcd[0-2]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/ketcd=true
	elif egrep 'kapi[0-8]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kapi=true
	elif egrep 'kctrl0$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kctrl=true

	elif egrep 'netcd[0-2]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/netcd=true
	elif egrep 'napi[0-8]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/napi=true
	elif egrep 'nctrl0$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/nctrl=true kos-role/netcd-op=true

	elif egrep 'comp[0-9]+$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/comp=true
	else
		:
	fi
done
