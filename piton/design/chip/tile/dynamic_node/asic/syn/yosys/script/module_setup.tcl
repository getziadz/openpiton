set PITON_ROOT $::env(PITON_ROOT)
set DV_ROOT $::env(DV_ROOT)
set DESIGN_NAME dynamic_node_top_wrap

# Preprocess the RTL with PyHP
eval "source ${DV_ROOT}/tools/asic/common/synopsys/script/design_setup.tcl"
eval "source ${DV_ROOT}/tools/asic/common/synopsys/script/pyhp_preprocess_setup.tcl"

# Get custom functions
eval "source ${DV_ROOT}/tools/asic/common/func/func.tcl"

# Files just for PyHP pre-processing
set RTL_SOURCE_FILES "${DV_ROOT}/design/include/define.h "

# Preprocess the RTL with PyHP
eval "pyhp_preprocess ${RTL_SOURCE_FILES}"

# Design files
set RTL_SOURCE_FILES "${PITON_ROOT}/pickles/dynamic_node/NETWORK_2dmesh/dynamic_node.pickle.v "

# Preprocess the RTL with PyHP
eval "pyhp_preprocess ${RTL_SOURCE_FILES}"

yosys verilog_defaults -add -I${DV_ROOT}/design/include

foreach RTL_SOURCE_FILE ${RTL_SOURCE_FILES} {
    yosys read_verilog "${RTL_SOURCE_FILE}"
}

# check design hierarchy
yosys hierarchy -top ${DESIGN_NAME}
