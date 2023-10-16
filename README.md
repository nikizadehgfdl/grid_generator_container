# OM5 Grid Generator Container

Tools and scripts to generate the horizontal grids, topography, and input datasets for OM5.


## Usage Instructions: Singularity on GFDL PPAN

For best performance, the container should be executed in the `/vftmp` directory on an big memory analysis node.
```
ssh analysis
cd $TMPDIR
```

Convert the container to a writable "sandbox" directory. (Note: `grid_generator_latest.tar` is a link to the latest version. 
Date-stamped versions are available in the same directory as well)
```
singularity build --sandbox grid_generator docker-archive:///archive/jpk/OM5/containers/grid_generator_latest.tar
```

Start the container and mount the O-Division datasets directory:
```
singularity shell --writable -B /archive/gold:/archive/gold grid_generator
```

Generate the `grid_spec.nc` file, which will include the horizontal grid and topography:
```
source activate /pad/griduser/.conda/envs/py311/
cd /results/OM5_025_dsp
make grid_spec.nc
```

Generate the input datasets:
```
make seawifs-clim-1997-2010.nc
make geothermal_davies2013_v1.nc
make tidal_amplitude.nc
```

Generate the grid-dependent JRA input files:
```
make salt_restore_JRA.nc
```

Notes/Caveats:
* The `tidal_amplitude.nc` file has significant differences compared to the version used in OM4
* The JRA runoff and liquid calving fluxes need to be regridded but current script is too slow to be practical


## Usage Instructions: Docker (outside GFDL)

```
docker pull krasting/grid_generator:latest
docker run -it grid_generator
```
