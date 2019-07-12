#!/bin/bash

echo 'iverilog -f flist.dynamic_node_dc -I${PITON_ROOT}/piton/design/include'
iverilog -f flist.dynamic_node_dc -I${PITON_ROOT}/piton/design/include
sleep 1
echo ""
echo ""

echo "./a.out +stim_file=./stimuli.txt"
./a.out +stim_file=./stimuli.txt 
