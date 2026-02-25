1. What I Have Done So Far
• Installed required tools: Git, MPI (mpicc, mpirun), GNU compilers.
• Cloned the MPAS-Model repository from GitHub.
• Installed and configured Parallel-NetCDF (PNETCDF).
• Set the PNETCDF environment variable so the Makefile can find libraries and headers.
• Compiled the atmosphere core using:
make -j 4 gnu CORE=atmosphere
• Linked the atmosphere_model executable into the global_240km directory.
• Tried running the model with:
mpirun -n 1 ./atmosphere_model
------------------------------------------------------------
2. Problems I Faced
Problem 1: PNETCDF environment variable not set
Solution: Installed PnetCDF and exported:
export PNETCDF=/usr
Problem 2: Build incompatibility error
Solution: Used:
make gnu CORE=atmosphere AUTOCLEAN=true
Problem 4: Missing input files
Some required files were missing:
x1.40962.sfc_update.nc
I tried:
• Renaming init.nc to x1.40962.init.nc
• Modifying namelist.atmosphere
• Modifying streams.atmosphere
• Running without MPI
But the model still stops.
3. What is namelist.atmosphere?
The namelist.atmosphere file controls:
• Simulation start time
• Run duration
• Time step (dt)
• Physics options
• Output settings
It tells the model HOW to run.What is streams.atmosphere?
4. The streams.atmosphere file tells the model:
• Which input files to read
• What output files to write
• When to write output
It defines all NetCDF files used during simulation.
5. What is init file?The init file (example: x1.40962.init.nc) contains:
• Initial atmospheric conditions
• Grid information
• Temperature, pressure, wind fields
Without this file, the model cannot start.
6. Current Status
• Model compiles successfully.
• MPI works.
• Main issue: Missing required input/static files for the 240 km setup.
• The executable runs but aborts due to missing or mismatched files.
7. Downloading Example Input Files
 Downloaded prepared input files for the global_240km test case:
wget https://www2.mmm.ucar.edu/people/duda/files/mpas/global_240km.tar.bz2
tar -xvjf global_240km.tar.bz2
Linked the compiled executable to the test case directory:
cd global_240km
ln -s ../atmosphere_model .
 Running the Test Simulation
 Executed the model using
1
MPI task:
mpirun -n 1 ./atmosphere_model
MPAS created a log file
log.atmosphere.0000.out where all output messages are written.
 Monitored the simulation using:
tail -f log.atmosphere.0000.out
8. Error Encountered
CRITICAL ERROR: Could not open input file 'x1.40962.init.nc' to read mesh fields
• MPAS could not find the mesh file, so the simulation stopped immediately.
• Without the mesh file, the model cannot run because it doesn’t know the grid.