# Automated River Routing
*Based on notes provided by Krista Dunne
Last Updated: November 2023*

Prerequisites:
* Coupled model gridspec 
* Source river network
* Lake data
 
```
GRIDSPEC="/archive/cm6/datasets/CM4/common/c96_grid/c96_OM4_025_grid_No_mg_drag_v20160808.unpacked/grid_spec.nc"

RIVERS="/archive/kap/lmdt/river_network/netcdf/0.5deg/disagg/river_network_mrg_0.5deg_ad3nov_fill_coast_auto2_0.125.nc"

LAKES="/archive/pcm/land_data/cover_lad/gigbp2_0ll.nc"
```

When using the OM5 preprocessing container, it must be started with additional mountpoints:
```
singularity shell --writable \
    -B /archive/gold:/archive/gold \
    -B /archive/kap:/archive/kap \
    -B /archive/cm6:/archive/cm6 \
    -B /archive/pcm:/archive/pcm \
    grid_generator
```

(For instructions on using the grid container, see this [README](https://github.com/jkrasting/grid_generator_container/blob/main/README.md).)

## Step 1: Regrid river data to model grid

```
# Change to the /results directory
cd /results

# Make an output directory
mkdir -p OUTPUT/river_regrid

cd OUTPUT/river_regrid && \
  /opt/fre-nctools/bin/river_regrid \
  --mosaic ${GRIDSPEC} \
  --river_src ${RIVERS} \
  --min_frac 0. \
  --land_thresh 1.e-5
```

## Step 2: Post-process the regridded river files
```
cd /results

river_input_files=(OUTPUT/river_regrid/river_output*nc)
echo ${#river_input_files[@]} > fort.5

for file in "${river_input_files[@]}"
do
    echo "${file}" >> fort.5
done

/opt/fre-nctools/bin/cp_river_vars < fort.5

mkdir -p OUTPUT/post_regrid
mv -v river_network*nc OUTPUT/post_regrid/
```

## Step 3: Eliminate cases of parallel rivers
```
cd /results

add_ocean_const="F"
river_input_files=(OUTPUT/post_regrid/river_network*nc)
echo ${#river_input_files[@]} > fort.5
for file in "${river_input_files[@]}"
do
    echo "$file" >> fort.5
done
echo "$add_ocean_const" >> fort.5

/opt/fre-nctools/bin/rmv_parallel_rivers < fort.5

mkdir -p OUTPUT/rmv_parallel_rivers
mv -v river_network*nc OUTPUT/rmv_parallel_rivers/
```

## Step 4: Post-process output again after removing parallel rivers
```
cd /results

river_input_files=(OUTPUT/rmv_parallel_rivers/river_network*nc)
echo ${#river_input_files[@]} > fort.5

for file in "${river_input_files[@]}"
do
   echo "$file" >> fort.5
done
echo "" >> fort.5

/opt/fre-nctools/bin/cp_river_vars < fort.5

mkdir -p OUTPUT/post_rmvp/
mv -v river_network*nc OUTPUT/post_rmvp/
```

## Step 5: Produce the lake data
```
cd /results

travel_thresh=2.

river_input_files=(OUTPUT/post_rmvp/river_network*nc)
echo ${#river_input_files[@]} > fort.5

for file in "${river_input_files[@]}"
do
   echo "$file" >> fort.5
done

echo $LAKES >> fort.5
echo "$travel_thresh" >> fort.5
touch input.nml

/opt/fre-nctools/bin/cr_lake_files < fort.5

mkdir -p OUTPUT/post_lakes/
mv -v lake_frac*nc OUTPUT/post_lakes/
```

## Step 6: Assemble the hydrography files
```
cd /results/OUTPUT

k=0
river_input_files=(post_rmvp/river_network.tile*.nc)

while [ $k -lt ${#river_input_files[@]} ]
do
  k=$((k + 1))
  cp "post_rmvp/river_network.tile$k.nc" "hydrography.tile$k.nc"
done

hydro_files=(hydrography*.nc)

for file in "${hydro_files[@]}"
do
   tn=$(echo "$file" | awk -Ftile '{print $2}')
   ncks -A -v lake_frac,lake_depth_sill,lake_tau,WaterBod,PWetland,connected_to_next,whole_lake_area,max_slope_to_next \
     post_lakes/lake_frac.tile"$tn" "${file##*/}"
done
```
