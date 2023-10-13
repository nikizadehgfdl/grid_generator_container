#!/usr/bin/env python
####Credits: 
####This tool is based on the following Jupyter Notebook from Raphael Dussin 
####https://github.com/raphaeldussin/OM4p25_tideamp/blob/master/Tidal_forcing_TPXO9_OM4p25.ipynb
####
####It is generalized to work for any given ocean_hgrid.nc and ocean_topog.nc within this toolset. 
#
# Creating the tidal amplitudes forcing for OM4p25 using TPXO9
# NB: this takes about 30 minutes and requires a machine with at least 64GB or RAM. I ran it on PP/AN an008.
# To provide the tidal amplitudes array for OM4, we use the tidal velocities coming from TPXO for the following harmonics:
# 
# M2, S2, N2, K2, K1, O1, P1, Q1.

import xarray as xr
import cartopy.crs as ccrs
import xesmf
from xgcm import Grid
import numpy as np
import sys

_ = xr.set_options(display_style='text')

# Set some defaults; this should be done via argparse
#gridfile = './ocean_hgrid.nc'
#topofile = './ocean_topog.nc'
#tpxodir = '/net2/rnd/TPXO/'
gridfile = sys.argv[1]
topofile = sys.argv[2]
tpxodir = sys.argv[3]

# Model grid file to use is:
#Get the lon,lat from ocean supergrid
hgrid = xr.open_dataset(gridfile)
lon = hgrid['x'].values[1::2,1::2].copy()
lon_bnds = hgrid['x'].values[0::2,0::2].copy()
lat = hgrid['y'].values[1::2,1::2].copy()
lat_bnds = hgrid['y'].values[0::2,0::2].copy()

OM4grid = xr.Dataset()
OM4grid['lon']   = xr.DataArray(data=lon, dims=('yh','xh'))
OM4grid['lat']   = xr.DataArray(data=lat, dims=('yh', 'xh'))
#The above lon, lat come as double increasing the file size! How can I make these to be float instead? 
# Create the mask for xESMF: copy the wet array is just what we need!
#Get the mask from ocean topog file
topo = xr.open_dataset(topofile)
#wet = topo['wet'].values[:,:].copy()
#topo['wet'] might not be present or consitent with topo['depth']
wet = np.where(topo['depth']>0,1.0,0.0)
OM4grid['wet'] = xr.DataArray(data=wet, dims=('yh', 'xh'))

## Load the TPXO dataset and create a grid object
# The dataset is not given in CF-compliant format so there is a bit of dataset manipulation involved here. First let's define the harmonics we're gonna be using:
harmonics = ["m2", "s2", "n2", "k2", "k1", "o1", "p1", "q1"]
tpxo_gridfile = f'{tpxodir}/TPXO9/grid_tpxo9_atlas_30_v2.nc'
tpxo_files = []
for harm in harmonics:
    tpxo_files.append(f'{tpxodir}/TPXO9/u_{harm}_tpxo9_atlas_30_v2.nc')

# Open all tidal velocity files and concatenate along harmonic dimension:
tpxo9 = xr.open_mfdataset(tpxo_files, concat_dim='harmonic', combine='nested')

# Longitude/Latitude do not need to be dependent on harmonics:
tpxo9 = tpxo9.assign_coords({'lon_u': xr.DataArray(tpxo9['lon_u'].isel(harmonic=0), dims=['lon_u'])})
tpxo9 = tpxo9.assign_coords({'lat_u': xr.DataArray(tpxo9['lat_u'].isel(harmonic=0), dims=['lat_u'])})
tpxo9 = tpxo9.assign_coords({'lon_v': xr.DataArray(tpxo9['lon_v'].isel(harmonic=0), dims=['lon_v'])})
tpxo9 = tpxo9.assign_coords({'lat_v': xr.DataArray(tpxo9['lat_v'].isel(harmonic=0), dims=['lat_v'])})

# harmonics needs its own data array:
tpxo9['harmonic'] = xr.DataArray(data=harmonics, dims=['harmonic'])
# Dimensions (nx,ny) are not giving information on the data point locations, renamed to something more explicit:
tpxo9['uRe'] = tpxo9['uRe'].rename({'nx': 'lon_u', 'ny': 'lat_u'})
tpxo9['uIm'] = tpxo9['uIm'].rename({'nx': 'lon_u', 'ny': 'lat_u'})
tpxo9['vRe'] = tpxo9['vRe'].rename({'nx': 'lon_v', 'ny': 'lat_v'})
tpxo9['vIm'] = tpxo9['vIm'].rename({'nx': 'lon_v', 'ny': 'lat_v'})
tpxo9

# Merge with the grid file (same considerations apply):
tpxo9_grid = xr.open_dataset(tpxo_gridfile)
tpxo9_grid = tpxo9_grid.assign_coords({'lon_u': xr.DataArray(tpxo9_grid['lon_u'], dims=['lon_u']),
                                       'lat_u': xr.DataArray(tpxo9_grid['lat_u'], dims=['lat_u']),
                                       'lon_v': xr.DataArray(tpxo9_grid['lon_v'], dims=['lon_v']),
                                       'lat_v': xr.DataArray(tpxo9_grid['lat_v'], dims=['lat_v']),
                                       'lon_z': xr.DataArray(tpxo9_grid['lon_z'], dims=['lon_z']),
                                       'lat_z': xr.DataArray(tpxo9_grid['lat_z'], dims=['lat_z'])})

tpxo9_grid['hz'] = tpxo9_grid['hz'].rename({'nx': 'lon_z', 'ny': 'lat_z'})
tpxo9_grid['hu'] = tpxo9_grid['hu'].rename({'nx': 'lon_u', 'ny': 'lat_u'})
tpxo9_grid['hv'] = tpxo9_grid['hv'].rename({'nx': 'lon_v', 'ny': 'lat_v'})
tpxo9_grid

tpxo9_merged = xr.merge([tpxo9, tpxo9_grid])
tpxo9_merged

# The TPXO grid follows a C-grid staggering with south-west origin.
# With that knowledge, we can create a xgcm grid object. Notice the order of U,V and Z (center) points:
tpxogrid = Grid(tpxo9_merged, coords={'X': {'center': 'lon_z', 'left': 'lon_u'},
                                      'Y': {'center': 'lat_z', 'left': 'lat_v'}},
                                      periodic=['X'])
tpxogrid

# Now let's get rid of the redondant dimensions:
tpxo9_merged['uRe'] = tpxo9_merged['uRe'].rename({'lat_u': 'lat_z'})
tpxo9_merged['uIm'] = tpxo9_merged['uIm'].rename({'lat_u': 'lat_z'})
tpxo9_merged['hu']  = tpxo9_merged['hu'].rename({'lat_u': 'lat_z'})
tpxo9_merged['vRe'] = tpxo9_merged['vRe'].rename({'lon_v': 'lon_z'})
tpxo9_merged['vIm'] = tpxo9_merged['vIm'].rename({'lon_v': 'lon_z'})
tpxo9_merged['hv']  = tpxo9_merged['hv'].rename({'lon_v': 'lon_z'})

## Computing the tidal velocities amplitude:

# Tidal transports (in the sense of $h \times u$, where $h$ is the total depth and $u$ the tidal velocity) are given in complex form $uRe + j \times uIm$. We obtain the squared amplitude using $U^{2} = uRe^{2} + uIm^{2}$
# 
# We also convert units for $uRe$ and $uIm$ from $cm^{2}.s^{-1}$ to $m^{2}.s^{-1}$ and since we're working with squared values, the conversion factor is then $10^{-8}$.
# 
# Also note that TPXO provides transports encoded as integer!!! Hence we need to convert to double precision otherwise the arrays are meaningless.

tpxo9_merged['U2'] =  1.0e-8 * ((tpxo9_merged['uRe'].astype('f8') * tpxo9_merged['uRe'].astype('f8')) +
                                (tpxo9_merged['uIm'].astype('f8') * tpxo9_merged['uIm'].astype('f8')))

tpxo9_merged['V2'] =  1.0e-8 * ((tpxo9_merged['vRe'].astype('f8') * tpxo9_merged['vRe'].astype('f8')) +
                                (tpxo9_merged['vIm'].astype('f8') * tpxo9_merged['vIm'].astype('f8')))


# Transpose and mask land values:
tpxo9_merged['U2'] = tpxo9_merged['U2'].where(tpxo9_merged['U2'] !=0).transpose(*('harmonic', 'lat_z', 'lon_u'))
tpxo9_merged['V2'] = tpxo9_merged['V2'].where(tpxo9_merged['V2'] !=0).transpose(*('harmonic', 'lat_v', 'lon_z'))
tpxo9_merged['hu'] = tpxo9_merged['hu'].where(tpxo9_merged['hu']).transpose(*('lat_z', 'lon_u'))
tpxo9_merged['hv'] = tpxo9_merged['hv'].where(tpxo9_merged['hv']).transpose(*('lat_v', 'lon_z'))

# Get the corresponding velocities squared, by dividing by the square of ocean depth at U and V points:
tpxo9_merged['u2'] = tpxo9_merged['U2'] / (tpxo9_merged['hu'] * tpxo9_merged['hu'])
tpxo9_merged['v2'] = tpxo9_merged['V2'] / (tpxo9_merged['hv'] * tpxo9_merged['hv'])

# Now we sum the two components on the center of the cells:
tpxo9_merged['umod2'] = tpxogrid.interp(tpxo9_merged['u2'], 'X', boundary='fill') +                         tpxogrid.interp(tpxo9_merged['v2'], 'Y', boundary='fill')

# Sum over all the harmonics:
tpxo9_merged['tideamp2'] = tpxo9_merged['umod2'].sum(dim='harmonic')

# Take the square-root lazily:
tpxo9_merged['tideamp'] = xr.apply_ufunc(np.sqrt, tpxo9_merged['tideamp2'],
                                         dask='parallelized',
                                         output_dtypes=[np.dtype('f8')])
tpxo9_merged['tideamp'].load()

### Create a mask for the source array:

# xESMF recognize a DataArray named 'mask' as the mask to use for the regridding:
binarymask = xr.where(tpxo9_merged['hz'] >0, 1, 0)
tpxo9_merged['mask'] = binarymask.transpose(*('lat_z', 'lon_z'))

tpxo9_merged = tpxo9_merged.rename({'lon_z': 'lon', 'lat_z': 'lat'})

# Verification plot (subsampled for speed)
# plt.figure(figsize=[10,6])
#plt.pcolormesh(tpxo9_merged['mask'].values[::10, ::10], cmap='binary')
#plt.colorbar()

tideamp_masked = tpxo9_merged['tideamp'].where(tpxo9_merged['mask'] != 0)

#plt.figure(figsize=[10,6])
#plt.pcolormesh(tideamp_masked.values[::10, ::10], 
#               vmin=0, vmax=1, cmap='viridis')
#plt.colorbar()

## Regrid tidal amplitude to model grid:
# Create the regridder:
regrid = xesmf.Regridder(tpxo9_merged, OM4grid, 'bilinear', periodic=True, reuse_weights=False,
                         extrap_method='nearest_s2d', extrap_num_src_pnts=1,
                         filename='regrid_wgts_TPXOv9_OM.nc')

# then regrid the tidal amplitude array:
tideamp_regridded = regrid(tideamp_masked)
tideamp_regridded.load()

# plt.figure(figsize=[10,6])
# tideamp_regridded.plot(vmin=0, vmax=1,
#                       x='lon', y='lat',
#                       cmap='viridis')

## Apply model mask

# xESMF returns zeros for masked values, so we need to mask with the model's wet array:
tideamp_regridded = tideamp_regridded.where(OM4grid['wet'] !=0)

#plt.figure(figsize=[10,6])
#tideamp_regridded.plot(vmin=0, vmax=1,
#                       x='lon', y='lat',
#                       cmap='viridis')

# verify the masking is consistent:
masked = xr.where(~np.isnan(tideamp_regridded), 1,0)
np.allclose(masked.values, OM4grid['wet'].values)

## Create the dataset
out = xr.Dataset()
out['tideamp'] = xr.DataArray(data=tideamp_regridded.values,
                              dims=('ny', 'nx'),
                              attrs = {'units': "m.s-1"})
                              
out['lon'] = xr.DataArray(data=tideamp_regridded.lon.values,
                          dims=('ny', 'nx'),
                          attrs = {'axis': 'X', 'units': 'degrees_east',
                                   'long_name': 'Longitude',
                                   'standard_name': 'longitude'})

out['lat'] = xr.DataArray(data=tideamp_regridded.lat.values,
                          dims=('ny', 'nx'),
                          attrs = {'axis': 'Y', 'units': 'degrees_north',
                                   'long_name': 'Latitude',
                                   'standard_name': 'latitude'})

encoding = {'lon': {'_FillValue': -1e+20},
            'lat': {'_FillValue': -1e+20},
            'tideamp': {'_FillValue': -1e+20,
                        'missing_value': -1e+20}}

out.to_netcdf('tidal_amplitude.nc',
              format='NETCDF3_64BIT', engine='netcdf4',
              encoding=encoding)

## Appendix: checking grids are the same in TPXO v8 and v9
import xarray as xr
import numpy as np

grid8 = xr.open_dataset(f'{tpxodir}/TPXO8/grid_tpxo8atlas_30.nc')
grid9 = xr.open_dataset(f'{tpxodir}/TPXO9/grid_tpxo9_atlas_30_v2.nc')

for var in ['lon_z', 'lon_u', 'lon_v', 'lat_z', 'lat_u', 'lat_v']:
    print(np.allclose(grid8[var], grid9[var], atol=1e-16))

# However this is not true for bathymetry:
for var in ['hz', 'hu', 'hv']:
    print(np.allclose(grid8[var], grid9[var], atol=1e-16))

