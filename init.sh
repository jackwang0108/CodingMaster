#!/bin/bash

SHELL_FOLDER=$(cd "$(dirname "$1")" || exit;pwd)
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


# Add tools
PATH=$PATH:$SHELL_FOLDER/Tools
export PATH

