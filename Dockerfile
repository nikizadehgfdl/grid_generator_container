# Dockerfile for container used to generate OM5 grids and datasets
# J. Krasting NOAA/GFDL
# Last updated: 18 October 2023


# Stage 00: Establish the base container
#----------------------------------------------
# Use Miniconda3 as base image
#FROM continuumio/miniconda3:23.3.1-0 as base
FROM condaforge/miniforge3 as base

# Turn off prompts
ARG DEBIAN_FRONTEND=noninteractive

# Set the name for the non-privilged user
ARG UNPRIV_USER=griduser

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

# Update system level conda and add conda-forge as a channel
RUN conda install mamba

# Switch to non-privileged user
ARG UNPRIV_USER=griduser
USER $UNPRIV_USER

# Create a new conda environment with Python 3.11 and the necessary packages
RUN mamba create -y -n py311 python=3.11 numpy scipy matplotlib cartopy netcdf4 pytest xarray dask numba tqdm xesmf xgcm seawater

# Create a Python 2.7 environment for the legacy tools
RUN mamba create -y -n py27 python=2.7 numpy basemap blas cftime geos glib gstreamer hdf4 hdf5 matplotlib netcdf4 proj4 pyproj scipy gsw

# Create a Python 3.7 environment for the river runoff regridding
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
ARG TOOLDIR=/opt
RUN mkdir -p $TOOLDIR
RUN chown $UNPRIV_USER $TOOLDIR
RUN chgrp $UNPRIV_USER $TOOLDIR

# Switch to non-privileged user
USER $UNPRIV_USER

RUN cd $TOOLDIR && git clone --recursive https://github.com/jkrasting/grid_generator_container.git tools && cd tools && git submodule update --recursive


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
from python-installed as om4preprocess

#ARG UNPRIV_USER=griduser
#
## Open up permissions
#USER root
#RUN mkdir -p $TOOLDIR
#RUN chown $UNPRIV_USER $TOOLDIR
#RUN chgrp $UNPRIV_USER $TOOLDIR

ARG TOOLDIR=/opt/tools

USER $UNPRIV_USER

SHELL ["conda", "run", "-n", "py27", "/bin/bash", "-c"]

RUN cd $TOOLDIR/MOM6-examples \
    && cd ice_ocean_SIS2/OM4_025/preprocessing \
    && make MIDAS \
    && make local


# Stage 6: Assemble the container
#---------------------------------------------
FROM om4preprocess

SHELL ["/bin/bash", "-c"]

ARG UNPRIV_USER=griduser
USER root

COPY --from=fretools /opt/fre-nctools /opt/fre-nctools

# Activate conda environment in .bashrc
RUN echo "export TERM=xterm" > /pad/$UNPRIV_USER/.bashrc
RUN echo "source activate py311" >> /pad/$UNPRIV_USER/.bashrc
RUN echo "echo 'OM5 Preprocessing Container'" >> /pad/$UNPRIV_USER/.bashrc

# Make mount point for GOLD datasets (GFDL-specific)
RUN mkdir -p /archive/gold

# Make results directory
RUN cp -r /opt/tools/results /results
RUN chown -R $UNPRIV_USER /results
RUN chgrp -R $UNPRIV_USER /results

USER $UNPRIV_USER

CMD ["/bin/bash"]
