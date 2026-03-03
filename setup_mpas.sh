
#!/bin/bash

# ===============================================
# MPAS-A Setup Automation Script
# ===============================================
# This script will:
# 1. Clone the MPAS repository
# 2. Set up PNETCDF environment variable
# 3. Clean previous builds
# 4. Compile the atmosphere core with AUTOCLEAN
# 5. Download and extract the global_240km test case
# 6. Link the executable into the test case directory
# ===============================================

# Stop execution if any command fails
set -e

echo "=== Cloning MPAS repository ==="
git clone https://github.com/MPAS-Dev/MPAS-Model.git
cd MPAS-Model

echo "=== Setting PNETCDF environment variable ==="
export PNETCDF=/usr
echo "PNETCDF set to $PNETCDF"

echo "=== Cleaning previous builds ==="
make clean

echo "=== Compiling atmosphere core ==="
make -j4 gnu CORE=atmosphere AUTOCLEAN=true

echo "=== Downloading global_240km test case ==="
wget https://www2.mmm.ucar.edu/people/duda/files/mpas/global_240km.tar.bz2
tar -xvjf global_240km.tar.bz2

echo "=== Linking executable into global_240km directory ==="
cd global_240km
ln -s ../atmosphere_model .

echo "=== Setup complete ==="
echo "You can now run the model with: mpirun -n 1 ./atmosphere_model"
