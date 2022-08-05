#!/bin/bash

declare -a arr=(
"v1"
"v1_8bit"
"v1_16bit"
"v2"
"v3"
"v4"
"v5"
"v6"
)

make clean
for i in "${arr[@]}"
do
	echo "$i"
	make $i
	make clean
done

