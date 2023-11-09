## BUILDING INSTRUCTIONS

To build the container from the Dockerfile:
```
docker build -t grid_generator:latest .
```

Exporting a copy of the container:
```
docker save -o grid_generator.tar grid_generator:latest
```

Uploading container to DockerHub:
```
docker tag grid_generator:latest $USER/grid_generator:vYYYYMMDD
docker tag grid_generator:latest $USER/grid_generator:latest
```
