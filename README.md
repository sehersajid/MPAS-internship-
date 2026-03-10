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

### OutputFiles
- the output from differnet runs are stored in seperate files for comaprison.
- `Original_output.log` output from the original code before modification.
- `new_output.log` output from modified/fused divergence code.

you can compare them using:

```bash
diff original_output.log new_output.log

```
---

## 11. Notes

- Large data files are **not uploaded** to this repository.
- Only configuration files, scripts, and documentation are tracked.