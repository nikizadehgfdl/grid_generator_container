USAGE INSTRUCTIONS
--------------------------------------------

CASE 1: Docker
++++++++++++++

To build the container:
    docker build -t grid_generator:latest .

To start the container:
    mkdir results
    docker run -it -v `pwd`results:/results grid_generator:latest

Working inside the container:
    cd /results
    ocean_grid_generator.py -f ocean_hgrid_res0.5.nc -r 2 --write_subgrid_files --no_changing_meta
    ocean_grid_generator.py -f ocean_hgrid_res0.25.nc -r 4 --r_dp 0.2 --south_cutoff_row 83 --write_subgrid_files --no_changing_meta
    exit

Use conda environment inside container:
    conda run -n py27 --no-capture-output /bin/bash

Exporting a copy of the container: 
    docker save -o grid_generator.tar grid_generator:latest

Uploading container to DockerHub:
    docker tag grid_generator:latest username/grid_generator:vYYYYMMDD
    docker tag grid_generator:latest username/grid_generator:latest


CASE 2: Singularity
+++++++++++++++++++

Convert the docker container to a writable "sandbox" container directory:
    (1)  singularity build --sandbox grid_generator docker-archive://grid_generator.tar

To start the container:
    singularity shell --writable grid_generator


Building OM5 Grid, Topography, and Input Datasets on GFDL PPAN
++++++++++++++++++++++++++++++

Build the container using the singularity instructions above, then start the container:

    singularity shell --writable -B /archive/gold:/archive/gold grid_generator_20231009

Inside the container:

    source activate /pad/griduser/.conda/envs/py311/
    cd /results
    make -f Makefile_OM5_rp
