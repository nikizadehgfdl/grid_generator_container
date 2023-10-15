# Dockerfile for container used to generate OM5 grids and datasets
# J. Krasting NOAA/GFDL
# Last updated: 15 August 2023
# (See usage instructions below)


# Stage 00: Establish the base container
#----------------------------------------------
# Use Miniconda3 as base image
#FROM continuumio/miniconda3:23.3.1-0 as base
FROM condaforge/miniforge3 as base

# Turn off prompts
ARG DEBIAN_FRONTEND=noninteractive

# Set the name for the non-privilged user
ARG UNPRIV_USER=griduser

ARG GIT_VER=1:2.30.2-1+deb11u2
ARG LIBNETCDF_VER=1:4.7.4-1
ARG LIBNETCDFF_VER=4.5.3+ds-2
ARG MAKE_VER=4.3-4.1
ARG NCO_VER=4.9.7-1
ARG WGET_VER=1.21-1+deb11u1
ARG LIBC_VER=2.31-13+deb11u5

# # Install Fortran Libraries & make
# RUN apt-get update && apt-get install -y \
#     git=$GIT_VER \
#     libnetcdf-dev=$LIBNETCDF_VER \
#     libnetcdff-dev=$LIBNETCDFF_VER \
#     make=$MAKE_VER \
#     nco=$NCO_VER \
#     wget=$WGET_VER \
#     libc-bin=$LIBC_VER \
#     less \
#     ucommon-utils \
#     patch \
#     tcsh \
# #    emacs \
#     vim

# Install Fortran Libraries & make
RUN apt-get update && apt-get install -y \
    git \
    libnetcdf-dev \
    libnetcdff-dev \
    make \
    nco \
    wget \
    libc-bin \
    less \
    ucommon-utils \
    patch \
    tcsh \
    emacs \
    vim

# Create the non-privilged user
RUN groupadd $UNPRIV_USER && useradd -ms /bin/bash -g $UNPRIV_USER $UNPRIV_USER
RUN mkdir -p /pad/$UNPRIV_USER
RUN chown $UNPRIV_USER:$UNPRIV_USER /pad/$UNPRIV_USER
RUN usermod -d /pad/$UNPRIV_USER $UNPRIV_USER


# Stage 0: Compiler Tools
#----------------------------------------------
FROM base as compiler

# OS-Specific Versions
ARG AUTOCONF_VER=2.69-14
ARG GCC_VER=4:10.2.1-1
ARG GFORTRAN_VER=4:10.2.1-1

## Install git, C-compiler, Fortran-compiler and autoreconf
#RUN apt-get update && apt-get install -y \
#    autoconf=$AUTOCONF_VER \
#    gcc=$GCC_VER \
#    gfortran=$GFORTRAN_VER

# Install git, C-compiler, Fortran-compiler and autoreconf
RUN apt-get update && apt-get install -y \
    autoconf \
    gcc-10 \
    gfortran-10

RUN ln -s /usr/bin/gcc-10 /usr/bin/gcc
RUN ln -s /usr/bin/gfortran-10 /usr/bin/gfortran


# Stage 1: Build the Python environment with tools
#----------------------------------------------
FROM compiler as python

# Specific Conda Builds
ARG NUMPY_BLD=1.24.4\=py311h64a7726_0
ARG MATPLOTLIB_BLD=3.7.2\=py311h38be061_0
ARG CARTOPY_BLD=0.22.0\=py311h320fe9a_0
ARG NETCDF4_BLD=1.6.4\=nompi_py311h4d7c953_100
ARG PYTEST_BLD=7.4.0\=pyhd8ed1ab_0
ARG XARRAY_BLD=2023.7.0\=pyhd8ed1ab_0
ARG DASK_BLD=2023.8.0\=pyhd8ed1ab_0
ARG NUMBA_BLD=0.57.1\=py311h96b013e_0
ARG TQDM_BLD=4.66.0\=pyhd8ed1ab_0
ARG XESMF_BLD=0.7.1\=pyhd8ed1ab_0
ARG XGCM_BLD=0.8.1\=pyhd8ed1ab_0
ARG SEAWATER_BLD=3.3.4\=py_1

#-- uncecessary??
# Set the working directory in the container
#WORKDIR /app

# Update system level conda
# RUN conda update -n base -c defaults conda

# Update system level conda and add conda-forge as a channel
#RUN conda config --add channels conda-forge
#RUN conda install -y --override-channels -c conda-forge mamba
RUN conda install mamba

# Switch to non-privileged user
ARG UNPRIV_USER=griduser
USER $UNPRIV_USER

# Create a new conda environment with Python 3.11 and the necessary packages
#RUN conda config --add channels conda-forge
#RUN mamba create -y -n py311 python=3.11 numpy=1.17.3 scipy=1.3.1 matplotlib cartopy netcdf4=1.4.2 pytest xarray dask numba=0.50.1 tqdm xesmf xgcm seawater
RUN mamba create -y -n py311 python=3.11 numpy scipy matplotlib cartopy netcdf4 pytest xarray dask numba tqdm xesmf xgcm seawater

#RUN mamba create -y --prefix /pad/$UNPRIV_USER/py311 python=3.11 numpy matplotlib cartopy netcdf4 pytest scipy xarray dask numba tqdm xesmf xgcm seawater

# RUN conda create -y -n env \
#     python=3.11 \
#     numpy=$NUMPY_BLD \
#     matplotlib=$MATPLOTLIB_BLD \
#     cartopy=$CARTOPY_BLD \
#     netcdf4=$NETCDF4_BLD \
#     pytest=$PYTEST_BLD \
#     scipy=$SCIPY_BLD \
#     xarray=$XARRAY_BLD \
#     dask=$DASK_BLD \
#     numba=$NUMBA_BLD \
#     tqdm=$TQDM_BLD \
#     xesmf=$XESMF_BLD \
#     xgcm=$XGCM_BLD \
#     seawater=$SEAWATER_BLD
   
# Create a Python 2.7 environment for the legacy tools
#RUN mamba create -y -n py27 python=2.7 numpy basemap blas cftime geos glib gstreamer hdf4 hdf5 intel-openmp matplotlib netcdf4 proj4 pyproj scipy gsw
RUN mamba create -y -n py27 python=2.7 numpy basemap blas cftime geos glib gstreamer hdf4 hdf5 matplotlib netcdf4 proj4 pyproj scipy gsw

RUN mamba create -y -n py37 python=3.7 numpy=1.17.3 scipy=1.3.1 netcdf4=1.4.2 numba=0.50.1

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



# Stage 3: Assemble Python Toolsets
#---------------------------------------------
FROM base as tools

ARG UNPRIV_USER=griduser

# Specify tool directory
ARG TOOLDIR=/opt/tools
RUN mkdir -p $TOOLDIR
RUN chown $UNPRIV_USER $TOOLDIR
RUN chgrp $UNPRIV_USER $TOOLDIR

# Switch to non-privileged user
USER $UNPRIV_USER

# Specific Repository Commits
ARG NUMPYPI_COMMIT=493d489
ARG GRIDGEN_COMMIT=4add8f6
ARG TOPOGEN_COMMIT=fc722bb
ARG SLOPPY_COMMIT=f016c3e
ARG GEOCONV_COMMIT=8631ac5
ARG GEOPROC_COMMIT=5846be6
ARG INTERPF_COMMIT=05686cd
ARG RVRUNOFF_COMMIT=e7f26be

# The following (4) should be pip-installed
# 1. Bootstrapped NumPy
RUN cd $TOOLDIR \
    && git clone https://github.com/underwoo/numpypi \
    && cd numpypi \
    && git checkout $NUMPYPI_COMMIT

# 2. NNZ Grid Generator
RUN cd $TOOLDIR \
    && git clone https://github.com/nikizadehgfdl/ocean_model_grid_generator \
    && cd ocean_model_grid_generator \
    && git checkout $GRIDGEN_COMMIT

# 3. NNZ Refine-Sample-Coarsen (RSC) topography generator
RUN cd $TOOLDIR \
    && git clone https://github.com/nikizadehgfdl/ocean_model_topog_generator \
    && cd ocean_model_topog_generator \
    && git checkout $TOPOGEN_COMMIT

# 3. RD `sloppy`
RUN cd $TOOLDIR \
    && git clone https://github.com/raphaeldussin/sloppy \
    && cd sloppy \
    && git checkout $SLOPPY_COMMIT

# Convert Davies geothermal
RUN cd $TOOLDIR \
    && git clone https://github.com/adcroft/convert_Davies_2013 \
    && cd convert_Davies_2013 \
    && git checkout $GEOCONV_COMMIT

# Preprocess Geothermal
RUN cd $TOOLDIR \
    && git clone https://github.com/adcroft/OM4_05_preprocessing_geothermal \
    && cd OM4_05_preprocessing_geothermal \
    && git checkout $GEOPROC_COMMIT

# Interp and fill routine
RUN cd $TOOLDIR \
    && git clone https://github.com/adcroft/interp_and_fill \
    && cd interp_and_fill \
    && git checkout $INTERPF_COMMIT

# River runoff
RUN cd $TOOLDIR \
    && git clone --recursive https://github.com/raphaeldussin/OM4_025_runoff_JRA \
    && cd OM4_025_runoff_JRA \
    && git checkout $RVRUNOFF_COMMIT



# Stage 4: Install Python packages in developer mode
#---------------------------------------------
from python as python-installed

# Specify tool directory
ARG TOOLDIR=/opt/tools
COPY --from=tools $TOOLDIR $TOOLDIR

# Switch to non-privileged user
ARG UNPRIV_USER=griduser
USER $UNPRIV_USER

SHELL ["conda", "run", "-n", "py311", "/bin/bash", "-c"]
RUN cd $TOOLDIR/numpypi && pip install -e .
RUN cd $TOOLDIR/ocean_model_grid_generator && pip install -e .
RUN cd $TOOLDIR/ocean_model_topog_generator && pip install -e .
RUN cd $TOOLDIR/sloppy && pip install -e .


# Stage 5: Build OM4 Preprocessing Tools
#---------------------------------------------
from python as om4preprocess

ARG UNPRIV_USER=griduser
ARG TOOLDIR=/opt/tools

# Open up permissions
USER root
RUN mkdir -p $TOOLDIR
RUN chown $UNPRIV_USER $TOOLDIR
RUN chgrp $UNPRIV_USER $TOOLDIR

# Switch back to non-privileged user
USER $UNPRIV_USER

SHELL ["conda", "run", "-n", "py27", "/bin/bash", "-c"]

RUN cd $TOOLDIR \
    && git clone https://github.com/jkrasting/MOM6-examples \
    && cd MOM6-examples \
    && git checkout 4eec19be2 \
    && cd ice_ocean_SIS2/OM4_025/preprocessing \
    && make MIDAS \
    && make local


# Stage 6: Assemble the container
#---------------------------------------------
FROM python-installed

SHELL ["/bin/bash", "-c"]

ARG UNPRIV_USER=griduser
USER root

COPY --from=fretools /opt/fre-nctools /opt/fre-nctools

COPY --from=om4preprocess /opt/tools/MOM6-examples /opt/tools/MOM6-examples
RUN chown -R $UNPRIV_USER /opt/tools/MOM6-examples
RUN chgrp -R $UNPRIV_USER /opt/tools/MOM6-examples

COPY auxillary /opt/tools/auxillary
RUN chown -R $UNPRIV_USER /opt/tools/auxillary
RUN chgrp -R $UNPRIV_USER /opt/tools/auxillary

# Activate conda environment in .bashrc
RUN echo "export TERM=xterm" > /pad/$UNPRIV_USER/.bashrc
RUN echo "source activate py311" >> /pad/$UNPRIV_USER/.bashrc
RUN echo "echo 'OM5 Preprocessing Container'" >> /pad/$UNPRIV_USER/.bashrc

# Make mount point for GOLD datasets (GFDL-specific)
RUN mkdir -p /archive/gold

# Make results directory
COPY results /results
RUN chown -R $UNPRIV_USER /results
RUN chgrp -R $UNPRIV_USER /results

USER $UNPRIV_USER

CMD ["/bin/bash"]
