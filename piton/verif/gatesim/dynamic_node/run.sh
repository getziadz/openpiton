#!/bin/bash

iverilog -f flist.dynamic_node_dc -I/tigress/gt5/projects/OpenPiton/openpiton-getziadz/piton/design/include
./a.out +stim_file=./stimuli.txt 
