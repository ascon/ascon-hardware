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

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

make clean
for i in "${arr[@]}"
do
	echo "Running testbench for $i..."
	res=$(make $i | grep "\[")
	if [[ $res == *"PASS"* ]]; then
		printf "${GREEN}PASS!${NC}\n"
	else
    		printf "${RED}FAIL!${NC}\n"
	fi
	make clean
done

