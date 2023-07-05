docker build -t grid_generator .

docker run -it --memory-swap=-1 --memory=0 -it -v results:/app grid_generator
docker run -it -v results:/app grid_generator

Inside the container,

cd app
ocean_grid_generator.py -f ocean_hgrid_res0.5.nc -r 2    --write_subgrid_files --no_changing_meta
ocean_grid_generator.py -f ocean_hgrid_res0.25.nc -r 4 --r_dp 0.2 --south_cutoff_row 83 --write_subgrid_files --no_changing_meta
exit

singularity exec grid_generator.sif bash -c "source /opt/conda/etc/profile.d/conda.sh && conda activate env && bash"


Notes on saving docker to tar to SIF:
docker save -o /path/to/save/my_image.tar my_image:tag
singularity build my_image.sif docker-archive://path/to/my_image.tar

docker build -t grid_generator .
docker tag grid_generator krasting/grid_generator:v20230703
docker push krasting/grid_generator:v20230703

To build from docker hub

