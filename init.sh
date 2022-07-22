#!/bin/bash

CURRENT_FOLDER=$(pwd)
SHELL_FOLDER=$(cd "$(dirname "$1")" || exit;pwd)
cd "${SHELL_FOLDER}"
# VM_FOLDER=SHELL_FOLDER/VirtualMachines/

# build tools
if [ -e "${SHELL_FOLDER}"/Tools/FixVhdWr/FixVhdWr ]; then
    echo -e "FixVhdWr exists"
else
    echo -e "Build FixVhdWr"
    cd "${SHELL_FOLDER}"/Tools/FixVhdWr || exit
    make
    cd "${SHELL_FOLDER}" || exit
fi

cd "${CURRENT_FOLDER}" || exit

# Add tools
PATH=$PATH:$SHELL_FOLDER/Tools
export PATH

