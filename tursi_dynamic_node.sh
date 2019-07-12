#!/bin/bash

module load anaconda3/5.3.1
source activate gt5_python

export PATH=/tigress/jbalkind/utils/bin:${PATH}

# . /usr/licensed/synopsys/profile
export PITON_ROOT=`pwd`
 . ${PITON_ROOT}/piton/piton_settings.bash


PICKLE_OUT_DIR=./pickles
mkdir -p ${PICKLE_OUT_DIR}


# Setup Dynamic Node example
CORE="openpiton::dynamic_node"
NETWORK_CONFIG="2dmesh"
V_NAMING='NETWORK_${NETWORK_CONFIG}/'



set -x
tursi --pickle --fusesoc_core ${CORE} --network_config "2dmesh"
set +x

# Copy pickle filed to correct location
CORE_UNDERSCORE=$(echo ${CORE} | tr ':' '_')
MODULE_NAME=$(echo ${CORE} | cut -d ':' -f 3)
PICKLE_OUT=build/build/${CORE_UNDERSCORE}_0.1/pickle-icarus/${CORE_UNDERSCORE}_0.1

# Create folder
PICKLE_FOLDER="${PICKLE_OUT_DIR}/${MODULE_NAME}/`eval echo ${V_NAMING}`"
mkdir -p ${PICKLE_FOLDER}
#echo ${PICKLE_FOLDER}

# Move and rename pickled file
PICKLE_RENAMED_OUT="${PICKLE_FOLDER}/${MODULE_NAME}.pickle.v"
mv ${PICKLE_OUT} ${PICKLE_RENAMED_OUT}

# Move json file
JSON_F=build/build/floorplan.json
mv ${JSON_F} "${PICKLE_FOLDER}/"

#echo ${PICKLE_RENAMED_OUT}
echo "${PICKLE_RENAMED_OUT}"
