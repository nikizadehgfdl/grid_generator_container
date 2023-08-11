# Dockerfile for container used to generate OM5 grids and datasets
# J. Krasting NOAA/GFDL - July 2023
# (See usage instructions below)


# Stage 0: Establish the base container
#----------------------------------------------
# Use Miniconda3 as base image
FROM continuumio/miniconda3:23.3.1-0 as base

ARG GIT_VER=1:2.30.2-1+deb11u2
ARG LIBNETCDF_VER=1:4.7.4-1
ARG LIBNETCDFF_VER=4.5.3+ds-2
ARG MAKE_VER=4.3-4.1
ARG NCO_VER=4.9.7-1
ARG WGET_VER=1.21-1+deb11u1
ARG LIBC_VER=2.31-13+deb11u5

# Install Fortran Libraries & make
RUN apt-get update && apt-get install -y \
    git=$GIT_VER \
    libnetcdf-dev=$LIBNETCDF_VER \
    libnetcdff-dev=$LIBNETCDFF_VER \
    make=$MAKE_VER \
    nco=$NCO_VER \
    wget=$WGET_VER \
    libc-bin=$LIBC_VER \
    emacs \
    vim


# Stage 00: Compiler Tools
#----------------------------------------------
FROM base as compiler

# OS-Specific Versions
ARG AUTOCONF_VER=2.69-14
ARG GCC_VER=4:10.2.1-1
ARG GFORTRAN_VER=4:10.2.1-1

# Install git, C-compiler, Fortran-compiler and autoreconf
RUN apt-get update && apt-get install -y \
    autoconf=$AUTOCONF_VER \
    gcc=$GCC_VER \
    gfortran=$GFORTRAN_VER


# Stage 1: Build the Python environment with tools
#----------------------------------------------
FROM compiler as python

# Specific Conda Builds
ARG NUMPY_BLD=1.25.1\=py311h64a7726_0
ARG MATPLOTLIB_BLD=3.7.2\=py311h38be061_0
ARG CARTOPY_BLD=0.21.1\=py311hd88b842_1
ARG NETCDF4_BLD=1.6.4\=nompi_py311h9a7c333_101
ARG PYTEST_BLD=7.4.0\=pyhd8ed1ab_0

# Specific Repository Commits
ARG NUMPYPI_COMMIT=493d489
ARG GRIDGEN_COMMIT=a1664f1
ARG TOPOGEN_COMMIT=1b089bc

# Set the working directory in the container
WORKDIR /app

# Update conda and add conda-forge as a channel
RUN conda update -n base -c defaults conda
RUN conda config --add channels conda-forge

# # Create a new conda environment with Python 3.11 and the necessary packages
# RUN conda create -y -n env \
#     python=3.11 \
#     numpy=$NUMPY_BLD \
#     matplotlib=$MATPLOTLIB_BLD \
#     cartopy=$CARTOPY_BLD \
#     netcdf4=$NETCDF4_BLD \
#     pytest=$PYTEST_BLD

RUN conda create -y -n env python=3.11 numpy matplotlib cartopy netcdf4 pytest scipy xarray dask numba tqdm xesmf xgcm seawater

# Install git
RUN apt-get update && apt-get install -y git=$GIT_VER

# Activate the Conda environment and install the GitHub package
SHELL ["conda", "run", "-n", "env", "/bin/bash", "-c"]
RUN pip install git+https://github.com/underwoo/numpypi@$NUMPYPI_COMMIT

# Clone and install the ocean model grid generator
RUN pip install git+https://github.com/nikizadehgfdl/ocean_model_grid_generator.git@$GRIDGEN_COMMIT

# Clone and install the ocean model topography generator
RUN pip install git+https://github.com/nikizadehgfdl/ocean_model_topog_generator.git@$TOPOGEN_COMMIT

# Clone and install `sloppy`
RUN pip install git+https://github.com/raphaeldussin/sloppy.git@f016c3e


# Stage 2: Build the FRE NCtools
#----------------------------------------------
FROM compiler as fretools

# FRE-NCtools version
ARG FRENC_COMMIT=dcbfc10

# Clone and install FRE-NCtools
RUN git clone https://github.com/NOAA-GFDL/FRE-NCtools.git
RUN cd FRE-NCtools && git checkout $FRENC_COMMIT
RUN cd FRE-NCtools && autoreconf -i && ./configure --prefix=/opt/fre-nctools && make install
RUN apt list --installed > /opt/fre-nctools/version_record.txt


# Stage 3: Various Toolsets
#---------------------------------------------
FROM base as tools

ARG TOOLDIR=/opt/tools

RUN mkdir -p $TOOLDIR

# Convert Davies geothermal
RUN cd $TOOLDIR \
    && git clone https://github.com/adcroft/convert_Davies_2013 \
    && cd convert_Davies_2013 \
    && git checkout 8631ac5

# Preprocess Geothermal
RUN cd $TOOLDIR \
    && git clone https://github.com/adcroft/OM4_05_preprocessing_geothermal \
    && cd OM4_05_preprocessing_geothermal \
    && git checkout 5846be6

# Interp and fill routine
RUN cd $TOOLDIR \
    && git clone https://github.com/adcroft/interp_and_fill \
    && cd interp_and_fill \
    && git checkout 05686cd

# River runoff
RUN cd $TOOLDIR \
    && git clone --recursive https://github.com/raphaeldussin/OM4_025_runoff_JRA \
    && cd OM4_025_runoff_JRA \
    && git checkout e7f26be


# Stage 4: Build MIDAS
#---------------------------------------------
# from python as python-midas
#
# RUN apt-get update && apt-get install -y tcsh
#
# RUN git clone https://github.com/jkrasting/MIDAS && cd MIDAS && git checkout 875ef79 && make -f Makefile_gfortran


# Stage 5: Assemble the container
#---------------------------------------------
FROM base

COPY --from=python /opt/conda/envs/env /opt/conda/envs/env
COPY --from=fretools /opt/fre-nctools /opt/fre-nctools
COPY --from=tools /opt/tools /opt/tools

# Activate conda environment in .bashrc
RUN echo "source activate env" > ~/.bashrc

# When the container is run, start a bash shell
CMD ["/bin/bash"]


# USAGE INSTRUCTIONS
#---------------------------------------------
#
# CASE 1: Docker
# ++++++++++++++
#
# To build the container:
#     docker build -t grid_generator:latest .
#
# To start the container:
#     mkdir results
#     docker run -it -v `pwd`results:/results grid_generator:latest
#
# Working inside the container:
#     cd /results
#     ocean_grid_generator.py -f ocean_hgrid_res0.5.nc -r 2 --write_subgrid_files --no_changing_meta
#     ocean_grid_generator.py -f ocean_hgrid_res0.25.nc -r 4 --r_dp 0.2 --south_cutoff_row 83 --write_subgrid_files --no_changing_meta
#     exit
#
# Exporting a copy of the container: 
#     docker save -o grid_generator.tar grid_generator:latest
#
# Uploading container to DockerHub:
#     docker tag grid_generator:latest username/grid_generator:vYYYYMMDD
#     docker tag grid_generator:latest username/grid_generator:latest
#
#
# CASE 2: Singularity
# +++++++++++++++++++
#
# Convert the docker container to a SIF image file (two approaches):
#     (1)  singularity build grid_generator.sif docker-archive://path/to/grid_generator.tar
#     (2)  singularity build grid_generator.sif docker://krasting/grid_generator:latest
#
# To start the container:
#     cd /path/to/some/workdir
#     singularity exec grid_generator.sif bash -c "source /opt/conda/etc/profile.d/conda.sh && conda activate env && bash"
