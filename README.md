# MPAS-A Setup and Initial Testing

## Overview

This repository documents the setup, compilation, and initial testing of the MPAS-Atmosphere model on a Linux system using GNU compilers and MPI.

The goal is to create a reproducible workflow for building and running MPAS, while documenting issues encountered and solutions applied.

---

## 1. System Requirements

The following tools were installed on the system:

- **Git**
- **GNU Compilers** (`gcc`, `gfortran`)
- **MPI** (`mpicc`, `mpirun`)
- **NetCDF**
- **Parallel-NetCDF (PNETCDF)**

---

## 2. Repository Setup

Clone the MPAS repository:

```bash
git clone https://github.com/MPAS-Dev/MPAS-Model.git
cd MPAS-Model
```

---

## 3. Setting Up PNETCDF

Set the required environment variable:

```bash
export PNETCDF=/usr
```

Verify:

```bash
echo $PNETCDF
```

---

## 4. Compiling MPAS (Atmosphere Core)

Clean previous builds automatically and compile the atmosphere core:

```bash
make -j4 gnu CORE=atmosphere AUTOCLEAN=true
```

This produces the executable:

```bash
atmosphere_model
```

---

## 5. Compiling `init_atmosphere` (Optional)

If generating new initialization files:

```bash
make clean
make -j4 gnu CORE=init_atmosphere
```

This produces:

```bash
init_atmosphere_model
```

---

## 6. Running the `global_240km` Test Case

Download the example test case:

```bash
wget https://www2.mmm.ucar.edu/people/duda/files/mpas/global_240km.tar.bz2
tar -xvjf global_240km.tar.bz2
```

Link the executable:

```bash
cd global_240km
ln -s ../atmosphere_model .
```

Run with MPI:

```bash
mpirun -n 1 ./atmosphere_model
```

Monitor output:

```bash
tail -f log.atmosphere.0000.out
```

---

## 7. Important Configuration Files

### `namelist.atmosphere`

Controls:

- Simulation start time  
- Run duration  
- Time step  
- Physics options  
- Output configuration  

### `streams.atmosphere`

Defines:

- Input files  
- Output files  
- File writing frequency  

### Initialization File

Example:

```
x1.40962.init.nc
```

This file contains:

- Mesh/grid information  
- Initial atmospheric state  
- Temperature, pressure, wind fields  

Without this file, the model cannot start.

---

## 8. Problems Encountered

### Issue 1 – PNETCDF Not Set

Error: Compilation failure due to missing PNETCDF.

**Solution:**

```bash
export PNETCDF=/usr
```

---

### Issue 2 – Build Incompatibility

**Solution:**

```bash
make -j4 gnu CORE=atmosphere AUTOCLEAN=true
```

---

### Issue 3 – Missing Input File

Error:

```
CRITICAL ERROR: Could not open input file 'x1.40962.init.nc'
```

Cause: 

- Missing or incorrectly linked initialization file  

Result:

- Model aborts before simulation starts  

---

## 9. Current Status

- Model compiles successfully  
- MPI execution works  
- Executable launches correctly 
- `Global-240km` test case run succesfully after restoring the correct input filename(init.nc) in stream.atmosphere.
- log files generated correctly in global-240km directory.
  - log.atmosphere.0000.out (standard output)
  - log.atmosphere.0000.err (standard error if any). 

---

## 10. Automation Using Shell Script

To simplify setup and ensure reproducibility, a shell script `setup_mpas.sh` has been provided.  

This script performs the following tasks:

- Clones the MPAS-Model repository
- Sets the required PNETCDF environment variable
- Cleans previous builds
- Compiles the atmosphere core
- Downloads the `global_240km` test case
- Links the executable in the test case directory

### How to use

1. Make the script executable: 

```bash
chmod +x setup_mpas.sh
```
2. Run the script:

```bash
./setup_mpas.sh
```
---

---
## 11- MPAS-Atmosphere Model – Horizontal Divergence Modification

I modified the **horizontal mass-flux divergence calculation** in `mpas_atm_time_integration.F` to simplify the code and improve performance.  

---

### What Was Changed
Previously, the code computed horizontal divergence in **two separate loops**:

1. Loop 1: accumulate `h_divergence` using edge flux `ru(k,iEdge)`.
2. Loop 2: multiply by `r = 1 / AreaCell` to scale the divergence.

**Modification:**  

- Combined both steps into **one loop** by multiplying by `r` during accumulation.  
- This reduces the number of loops and simplifies the OpenACC parallel regions.  
- The old code is kept **commented** for reference.  

---

### Why This Change
- Makes the code more **efficient** (fewer loops).  
- Easier to **read and maintain**.  
- Produces **numerically identical results** to the original code.  

---

### 12- Comparing Simulation Outputs

After running the MPAS model, it is important to verify that any code changes or optimizations do not alter the scientific results. This can be done by comparing the NetCDF output files from the original and optimized runs.

### 12.1 Setting Up the Python Environment

Create and activate a Python virtual environment to isolate dependencies:

```bash
python3 -m venv mpas-venv
source mpas-venv/bin/activate

python3 -m pip install --upgrade pip
pip install ncompare
```

#### To compare individual NetCDF files from different runs:
```bash
ncompare original_run/history.2014-09-15_00.00.00.nc \
         optimize_run/history.2014-09-15_00.00.00.nc --summary
```

---
### 13. Loop Fusion & Annotation Study

The main objective is to compare three different versions of the same MPAS codebase:

1. **Original Code (Master Branch)**  
   Unmodified MPAS source code used as the baseline.

2. **Hand-Fused Code (Main Branch / hand_fused)**  
   Manually optimized version where loop fusion is applied by restructuring loops to improve performance.

3. **Annotated Code (Annotated Branch)**  
   Original code enhanced with compiler directives (`!$pos kernel`) to indicate potential fusion regions without modifying the physics or numerical logic.

---

### Work Done So Far (Related to Loop Fusion)

#### 1. Hand-Fused Version
- Manual loop fusion applied in key computational kernels in `mpas_atm_time_integration.F`.
- Optimized nested loops to reduce redundant memory access and improve data locality.
- Targeted performance-critical sections in atmospheric dynamics.

---

#### 2. Annotated Version
- Added **POS kernel annotations** without changing physics:
  - `!$pos kernel(fusable, depth=1)`
  - `!$pos kernel(target, depth=1)`
- Marked potential fusion regions such as:
  - Edge-based momentum update loops
  - Cell-based thermodynamic update loops
- Maintained full compatibility with original MPAS logic.

---

#### Example Annotation

```fortran
!$pos kernel(fusable, depth=1)
do iEdge = edgeStart, edgeEnd
   ...
end do

!$pos kernel(target, depth=1)
do iCell = cellSolveStart, cellSolveEnd
   ...
end do

```

### 14. Manual Producer-Consumer Fusion Test

The goal of this test are:

* first, an intermediate value is produced;
* later, the value is consumed through mesh connectivity;
* in the modified version, the consumer recomputes the needed value locally instead of reading the intermediate array.

#### 14.1 Selected Subroutine

The selected subroutine was:

```fortran
atm_recover_large_step_variables_work
```

This subroutine contains a producer-consumer pattern involving `ru`.

#### 14.2 Original Producer-Consumer Pattern

In the original code, `ru` is produced on edges:

```fortran
ru(k,iEdge) = ru_save(k,iEdge) + ru_p(k,iEdge)
```

Later, `ru` is consumed inside a cell-based loop through `edgesOnCell`:

```fortran
iEdge = edgesOnCell(i,iCell)

flux = (fzm(k)*ru(k,iEdge)+fzp(k)*ru(k-1,iEdge))

w(k,iCell) = w(k,iCell) + edgesOnCell_sign(i,iCell) * &
             (zb_cell(k,i,iCell)+sign(1.0_RKIND,flux)*zb3_cell(k,i,iCell))*flux
```

This matches the producer-consumer pattern because the value is produced on edges and later used by cells through the connectivity array `edgesOnCell`.

#### 14.3 Manual Fusion Idea

Instead of reading:

```fortran
ru(k,iEdge)
```

inside the consumer loop, the modified version recomputes the same value locally:

```fortran
local_ru_k = ru_save(k,iEdge) + ru_p(k,iEdge)
```

For `k-1`, it similarly uses:

```fortran
local_ru_km1 = ru_save(k-1,iEdge) + ru_p(k-1,iEdge)
```

Then the flux computation uses the local values:

```fortran
flux = (fzm(k)*local_ru_k + fzp(k)*local_ru_km1)
```

This follows the manual fusion idea:

```text
Before:
consumer reads intermediate array value

After:
consumer recomputes the needed value locally
```

#### 14.4 Important Safety Decision

The original producer loop was not removed.

This is because `ru` and `u` are still output arrays of the subroutine. If the producer loop were deleted, the final values of `ru` and `u` would be wrong.

Therefore, the safe version keeps the original edge loop, but changes the later consumer loop so that it recomputes the needed `ru` values locally.

#### 14.5 Build Commands for Manual Fusion Branch

The manual fusion version was compiled using the Guix build scripts:

```bash
cd ~/MPAS-work

bash guix_clean
bash guix_compile 2>&1 | tee build_manual_fusion.log
```

After compilation, the executable was saved separately:

```bash
mkdir -p ~/MPAS-bitwise-test/bin
cp atmosphere_model ~/MPAS-bitwise-test/bin/atmosphere_model_manual_fusion
```

#### 14.6 Running the Manual Fusion Version

A clean test directory was created:

```bash
mkdir -p ~/MPAS-bitwise-test
cd ~/MPAS-bitwise-test

cp -r ~/MPAS-work/global_240km manual_run
cd manual_run
```

Old output files were removed:

```bash
rm -f log.atmosphere.* diag.*.nc history.*.nc restart.*.nc
```

The manual-fusion executable was linked:

```bash
ln -sf ~/MPAS-bitwise-test/bin/atmosphere_model_manual_fusion atmosphere_model
```

The model was run with one MPI process:

```bash
mpirun -n 1 ./atmosphere_model 2>&1 | tee run_manual_fusion.log
```

The run completed successfully. The log showed:

```text
Error messages = 0
Critical error messages = 0
```

The output files were created:

```text
diag.2014-09-10_00.00.00.nc
history.2014-09-10_00.00.00.nc
```

The manual-fusion output was saved:

```bash
cd ~/MPAS-bitwise-test/manual_run

cp history.2014-09-10_00.00.00.nc ../history_manual_fusion.nc
cp diag.2014-09-10_00.00.00.nc ../diag_manual_fusion.nc
cp log.atmosphere.0000.out ../log_manual_fusion.out
```

#### 14.7 Building and Running the Original Version

The original branch was checked out and compiled:

```bash
cd ~/MPAS-work

git checkout master
bash guix_clean
bash guix_compile 2>&1 | tee build_original.log
```

The original executable was saved:

```bash
mkdir -p ~/MPAS-bitwise-test/bin
cp atmosphere_model ~/MPAS-bitwise-test/bin/atmosphere_model_original
```

A separate clean run directory was created:

```bash
cd ~/MPAS-bitwise-test

cp -r ~/MPAS-work/global_240km original_run
cd original_run
```

Old output files were removed:

```bash
rm -f log.atmosphere.* diag.*.nc history.*.nc restart.*.nc
```

The original executable was linked:

```bash
ln -sf ~/MPAS-bitwise-test/bin/atmosphere_model_original atmosphere_model
```

The original model was run:

```bash
mpirun -n 1 ./atmosphere_model 2>&1 | tee run_original.log
```

The original output was saved:

```bash
cd ~/MPAS-bitwise-test/original_run

cp history.2014-09-10_00.00.00.nc ../history_original.nc
cp diag.2014-09-10_00.00.00.nc ../diag_original.nc
cp log.atmosphere.0000.out ../log_original.out
```

#### 14.8 Variable-Level Bitwise Comparison Script

The following Python script was used to compare the actual NetCDF variable values:

```bash
cd ~/MPAS-bitwise-test

cat > compare_nc_values.py <<'EOF'
from netCDF4 import Dataset
import numpy as np
import sys

if len(sys.argv) != 3:
    print("Usage: python3 compare_nc_values.py file1.nc file2.nc")
    sys.exit(1)

f1 = sys.argv[1]
f2 = sys.argv[2]

a = Dataset(f1)
b = Dataset(f2)

all_ok = True

print("Comparing:")
print("  file1:", f1)
print("  file2:", f2)
print()

for name in a.variables:
    if name not in b.variables:
        print("MISSING in file2:", name)
        all_ok = False
        continue

    va = a.variables[name]
    vb = b.variables[name]

    xa = np.array(va[:])
    xb = np.array(vb[:])

    if xa.shape != xb.shape:
        print("SHAPE DIFFERENT:", name, xa.shape, xb.shape)
        all_ok = False
        continue

    if xa.dtype != xb.dtype:
        print("DTYPE DIFFERENT:", name, xa.dtype, xb.dtype)
        all_ok = False
        continue

    if xa.tobytes() != xb.tobytes():
        all_ok = False
        print()
        print("DIFFERENT VARIABLE:", name)
        print("  shape:", xa.shape)
        print("  dtype:", xa.dtype)

        if np.issubdtype(xa.dtype, np.floating):
            diff = np.abs(xa - xb)
            print("  max abs diff:", np.nanmax(diff))
            bad = np.argwhere(diff != 0)
            if bad.size > 0:
                idx = tuple(bad[0])
                print("  first bad index:", idx)
                print("  original value:", xa[idx])
                print("  manual value:  ", xb[idx])
        else:
            bad = np.argwhere(xa != xb)
            if bad.size > 0:
                idx = tuple(bad[0])
                print("  first bad index:", idx)
                print("  original value:", xa[idx])
                print("  manual value:  ", xb[idx])

a.close()
b.close()

print()
if all_ok:
    print("RESULT: all variables are bitwise identical.")
else:
    print("RESULT: some variables are different.")
EOF
```

The history files were compared with:

```bash
python3 compare_nc_values.py history_original.nc history_manual_fusion.nc | tee compare_history_values.log
```

The result was:

```text
RESULT: all variables are bitwise identical.
```

This means that all variables in the history output were bitwise identical between the original version and the manual-fusion version.

The diagnostic files can be checked with:

```bash
python3 compare_nc_values.py diag_original.nc diag_manual_fusion.nc | tee compare_diag_values.log
```


