#!/bin/bash

echo $1
__TMP=$(dirname "$(readlink -f \"$1\")")

export PITON_ROOT=${__TMP}
echo "PITON_ROOT=${PITON_ROOT}"

. ${PITON_ROOT}/piton/piton_settings.bash

function urg() { command urg -full64 "$@"; }; export -f urg
function vcs() { command vcs -full64 "$@"; }; export -f vcs


if [ -x `command -v iverilog` ];
then
    echo "IVERILOG in PATH"
    ICARUS_HOME=`command -v iverilog`
    ICARUS_HOME=$(dirname ${ICARUS_HOME})
    ICARUS_HOME=$(dirname ${ICARUS_HOME})
elif [ "${HOSTNAME}" == "della2.princeton.edu" ] || 
   [ "${HOSTNAME}" == "della2.princeton.edu" ];
then
    echo "IVERILOG in DELLA node"
    ICARUS_HOME=/tigress/jbalkind/utils
fi
echo "ICARUS_HOME=${ICARUS_HOME}"
export ICARUS_HOME
