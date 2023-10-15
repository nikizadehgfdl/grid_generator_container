USAGE INSTRUCTIONS
--------------------------------------------

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
