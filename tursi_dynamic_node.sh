#!/bin/bash

module load anaconda3/5.3.1
source activate gt5_python

export PATH=/tigress/jbalkind/utils/bin:${PATH}

# . /usr/licensed/synopsys/profile
export PITON_ROOT=/tigress/gt5/projects/OpenPiton/openpiton-getziadz
 . ${PITON_ROOT}/piton/piton_settings.bash


PICKLE_OUT_DIR=./pickles
mkdir -p ${PICKLE_OUT_DIR}



function tursi_all() {
    echo "tursi_all()"
    for _X_TILE in "${X_TILES[@]}"; do
        for _Y_TILE in "${Y_TILES[@]}"; do
            for _NETWORK_CONFIG in "${NETWORK_CONFIGS[@]}"; do
                for _L1I_SIZE in "${L1I_SIZES[@]}"; do
                    for _L1D_SIZE in "${L1D_SIZES[@]}"; do
                        for _L15_SIZE in "${L15_SIZES[@]}"; do
                            for _L2_SIZE in "${L2_SIZES[@]}"; do
                                for _L1I_ASSOC in "${L1I_ASSOCS[@]}"; do
                                    for _L1D_ASSOC in "${L1D_ASSOCS[@]}"; do
                                        for _L15_ASSOC in "${L15_ASSOCS[@]}"; do
                                            for _L2_ASSOC in "${L2_ASSOCS[@]}"; do
                                                for CORE in "${CORES[@]}"; do
                                                    VALID_CONF=$((
                                                            (${_L1I_SIZE} <= ${_L2_SIZE}) &&
                                                            (${_L1D_SIZE} <= ${_L15_SIZE}) &&
                                                            (${_L15_SIZE} <= ${_L2_SIZE})))
                                                    INVALID_ASSOC=$((
                                                            (
                                                                (${_L1I_SIZE}  == 8192) &&
                                                                (${_L1I_ASSOC} != 2)) ||
                                                            (
                                                                (${_L1D_SIZE} == 4096) &&
                                                                (${_L1D_ASSOC} != 2))))
                                                    if [ ${INVALID_ASSOC} == "1" ]; then
                                                        echo "INVALID ASSOC: ${PICKLE_OUT_DIR}/${CORE}_-_${_X_TILE}x${_Y_TILE}_${_NETWORK_CONFIG}_${_L1I_SIZE}-${_L1D_SIZE}-${_L15_SIZE}-${_L2_SIZE}_${_L1I_ASSOC}-${_L1D_ASSOC}-${_L15_ASSOC}-${_L2_ASSOC}.pickle.v"
                                                        VALID_CONF=0
                                                    fi
                                                    
                                                    if [ ${VALID_CONF} == "1" ]; then
                                                        tursi --pickle --fusesoc_core ${CORE} \
                                                            --network_config  ${_NETWORK_CONFIG} \
                                                            --x_tiles ${_X_TILE} \
                                                            --y_tiles ${_Y_TILE} \
                                                            --config_l1i_size ${_L1I_SIZE} \
                                                            --config_l1d_size ${_L1D_SIZE} \
                                                            --config_l15_size ${_L15_SIZE} \
                                                            --config_l2_size ${_L2_SIZE} \
                                                            --config_l1i_associativity ${_L1I_ASSOC} \
                                                            --config_l1d_associativity ${_L1D_ASSOC}  \
                                                            --config_l15_associativity ${_L15_ASSOC} \
                                                        --config_l2_associativity  ${_L2_ASSOC}
                                                        CORE_UNDERSCORE=$(echo ${CORE} | tr ':' '_')
                                                        MODULE_NAME=$(echo ${CORE} | cut -d ':' -f 3)
                                                        PICKLE_OUT=build/build/${CORE_UNDERSCORE}_0.1/pickle-icarus/${CORE_UNDERSCORE}_0.1
 
                                                        # Create folder
                                                        PICKLE_FOLDER="${PICKLE_OUT_DIR}/${MODULE_NAME}/`eval echo ${V_NAMING}`"
                                                        mkdir -p ${PICKLE_FOLDER}
                                                        echo ${PICKLE_FOLDER}

                                                        # Move and rename pickled file
                                                        PICKLE_RENAMED_OUT="${PICKLE_FOLDER}/${MODULE_NAME}.pickle.v"
                                                        mv ${PICKLE_OUT} ${PICKLE_RENAMED_OUT}

                                                        # Move json file
                                                        JSON_F=build/build/floorplan.json
                                                        mv ${JSON_F} "${PICKLE_FOLDER}/"

                                                        echo ${PICKLE_RENAMED_OUT}
                                                        exit
                                                    fi
                                                        
                                                done
                                            done
                                        done
                                    done
                                done
                            done
                        done
                    done
                done
            done
        done
    done   
}

CORES=(
"openpiton::dynamic_node"
)

X_TILES=(1)
Y_TILES=(1)
NETWORK_CONFIGS=("2dmesh")

L1I_SIZES=(8192) # 8K   16K 32K
L1D_SIZES=(4096)  # 4K    8K 16K
L15_SIZES=(16384) # 8K   16K 32K
L2_SIZES=(65536)      # 64K 128K

L1I_ASSOCS=(2) # if smallest 2 otherwise 4
L1D_ASSOCS=(2)
L15_ASSOCS=(4)
L2_ASSOCS=(4)

V_NAMING='NETWORK_${_NETWORK_CONFIG}/'
tursi_all;
