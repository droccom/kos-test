#!/bin/bash

kubectl get node --no-headers -o custom-columns=Name:.metadata.name | while read nodename; do
	kubectl annotate --overwrite Node $nodename prometheus.io/scrape=true
	if false; then
		:
	elif egrep 'ketcd[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/ketcd=true
	elif egrep 'kapi[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kapi=true
	elif egrep 'kctrl[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kctrl=true

	elif egrep 'netcd[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/netcd=true
	elif egrep 'napi[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/napi=true
	elif egrep 'nctrl[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/nctrl=true kos-role/netcd-op=true

	elif egrep 'comp[0-9]+$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/comp=true
	elif egrep 'data[0-9]+$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/data=true
	else
		:
	fi
done
