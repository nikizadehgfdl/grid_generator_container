# Use Miniconda3 as base image
FROM continuumio/miniconda3 as builder

# Set the working directory in the container
WORKDIR /app

# Update conda and add conda-forge as a channel
RUN conda update -n base -c defaults conda
RUN conda config --add channels conda-forge

# Create a new conda environment with Python 3.11 and the necessary packages
RUN conda create -y -n env python=3.11 numpy matplotlib cartopy netcdf4 pytest

# Install git
RUN apt-get update && apt-get install -y git

# Activate the Conda environment and install the GitHub package
SHELL ["conda", "run", "-n", "env", "/bin/bash", "-c"]
RUN pip install git+https://github.com/underwoo/numpypi@pip.installable

# Clone and install the ocean model grid generator
RUN git clone https://github.com/nikizadehgfdl/ocean_model_grid_generator.git
RUN cd ocean_model_grid_generator && pip install .

# Clone and install the ocean model topography generator
RUN git clone https://github.com/nikizadehgfdl/ocean_model_topog_generator.git
RUN cd ocean_model_topog_generator && pip install .

#----------------------------------------------
# Build the FRE NCtools
FROM continuumio/miniconda3 as fretools

# Install git, C-compiler, Fortran-compiler and autoreconf
RUN apt-get update && apt-get install -y git gcc gfortran autoconf libnetcdf-dev libnetcdff-dev make

# Clone and install FRE-NCtools
RUN git clone https://github.com/NOAA-GFDL/FRE-NCtools.git
RUN cd FRE-NCtools && git checkout dcbfc10
RUN cd FRE-NCtools && autoreconf -i && ./configure --prefix=/opt/fre-nctools && make install

#---------------------------------------------
# Start new stage
FROM continuumio/miniconda3

COPY --from=builder /opt/conda/envs/env /opt/conda/envs/env
COPY --from=fretools /opt/fre-nctools /opt/fre-nctools

# Install Fortran Libraries & make
RUN apt-get update && apt-get install -y libnetcdf-dev libnetcdff-dev make

# Activate conda environment in .bashrc
RUN echo "source activate env" > ~/.bashrc

# When the container is run, start a bash shell
CMD ["/bin/bash"]

