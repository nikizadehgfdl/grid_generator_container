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

# Start new stage
FROM continuumio/miniconda3

COPY --from=builder /opt/conda/envs/env /opt/conda/envs/env

# Activate conda environment in .bashrc
RUN echo "source activate env" > ~/.bashrc

# When the container is run, start a bash shell
CMD ["/bin/bash"]

