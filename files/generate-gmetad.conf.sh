#!/bin/bash

cat $1/*

for clusterf in $1/collect_*; do
    cluster=$(cat "${clusterf}" |cut -f 1 -d\;|sed s/#//|uniq)
	port=$(cat "${clusterf}" | head -1 |cut -d: -f2)
    echo "data_source \"${cluster}\" localhost:${port}"
done
