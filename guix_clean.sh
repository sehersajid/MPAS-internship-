#! /bin/bash

echo "Running $@"

source guix_env.sh

make -j CORE=atmosphere AUTOCLEAN=true clean
