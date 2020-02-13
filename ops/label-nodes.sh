#!/bin/bash

kubectl get Node | grep -vw NAME | while read nodename rest; do
	if false; then
		:
	elif egrep 'ketcd[0-9]*$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/ketcd=true
	elif egrep 'kapi[0-9]*$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kapi=true
	elif egrep 'kctrl[0-9]*$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kctrl=true

	elif egrep 'netcd[0-9]*$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/netcd=true
	elif egrep 'napi[0-9]*$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/napi=true
	elif egrep 'nctrl[0-9]*$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/nctrl=true
		kubectl label --overwrite Node $nodename kos-role/netcd-op=true

	elif egrep 'comp[0-9]*$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/comp=true
	else
		:
	fi
done
