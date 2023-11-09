import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
from pyproj import CRS, Transformer
from cartopy import crs as ccrs

from sloppy.distrib import compute_block
from sloppy.distrib import compute_block_brute


def proj_xy(lon, lat, PROJSTRING):
    """ """
    from pyproj import CRS, Transformer

    # create the coordinate reference system
    crs = CRS.from_proj4(PROJSTRING)
    # create the projection from lon/lat to x/y
    proj = Transformer.from_crs(crs.geodetic_crs, crs)
    # compute the lon/lat
    xx, yy = proj.transform(lon, lat, direction="FORWARD")
    return xx, yy


PROJSTRING = "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"

#---------------- bedmachine + reduction
bedmachine = xr.open_dataset(
    "/net2/rnd/BedMachineAntarctica_2020-07-15_v02.nc"
)

xx_bm_full, yy_bm_full = np.meshgrid(bedmachine["x"].values, bedmachine["y"].values)


#----------------- read lon/lat MOM6 grid corners until 60S

gridname = "ocean_hgridSP_025deg"
hgrid = xr.open_dataset(f"/work/ovs/iOM4/{gridname}.nc")
iOM4dir = "/work/ovs/iOM4/"
j60s=562

lon_model = hgrid["x"][0:j60s:2, 0::2]
lat_model = hgrid["y"][0:j60s:2, 0::2]

xx_model, yy_model = proj_xy(lon_model, lat_model, PROJSTRING)

### remapping

out = xr.Dataset()

bed = compute_block(
    xx_model,
    yy_model,
    bedmachine["bed"].values,
    xx_bm_full,
    yy_bm_full,
    is_stereo=False,
    is_carth=True,
    PROJSTRING=PROJSTRING,
    residual=True,
)

out = xr.Dataset()
out["bed"] = xr.DataArray(data=bed[0, :, :], dims=("y", "x"))
out["h2"] = xr.DataArray(data=bed[3, :, :], dims=("y", "x"))

out.to_netcdf(f"{iOM4dir}/bed_bedmachine_remapped_iOM4_SP_025deg.nc")
#





#plt.figure()
#plt.pcolormesh(xx_model, yy_model, thk10x[0, :, :], vmax=5000)
#plt.colorbar()
#plt.title("10x downsampled - thickness")
#
#plt.show()

#subplot_kws = dict(
#    projection=ccrs.SouthPolarStereo(central_longitude=0.0), facecolor="grey"
#)
#plt.figure(figsize=[10, 8])
#ax = plt.axes(projection=ccrs.SouthPolarStereo(central_longitude=0.0))
## ax.stock_img()
#plt.pcolormesh(
#    lon_model,
#    lat_model,
#    thk5x[0, :, :],
#    shading="auto",
#    cmap="jet",
#    transform=ccrs.PlateCarree(),
#), plt.clim(-0, 4000), plt.colorbar()
#ax.set_extent([-180, 180, -55, -90], ccrs.PlateCarree())
#ax.gridlines(color="black", alpha=0.5, linestyle="--")
#
#plt.show()


# wrong
# lon_model = hgrid["x"][1::2,1::2]
# lat_model = hgrid["y"][1::2,1::2]
# and does not reproduce olga's problem

#out10x = compute_block(
#    lon_model,
#    lat_model,
#    bedmachine_10x["lat"].values,
#    bedmachine_10x["lon"].values,
#    bedmachine_10x["lat"].values,
#    is_stereo=True,
#    is_carth=True,
#    PROJSTRING=PROJSTRING,
#    residual=False,
#    algo="fast",
#)
#
#out5x = compute_block(
#    lon_model,
#    lat_model,
#    bedmachine_5x["lat"].values,
#    bedmachine_5x["lon"].values,
#    bedmachine_5x["lat"].values,
#    is_stereo=True,
#    is_carth=True,
#    PROJSTRING=PROJSTRING,
#    residual=False,
#    algo="fast",
#)
#
#
#mask_5x = np.where(hgrid["area"][0::2, 0::2] > 2500 * 2500, 1, 0)
#mask_10x = np.where(hgrid["area"][0::2, 0::2] > 5000 * 5000, 1, 0)
#
#plt.figure()
#plt.pcolormesh(mask_5x, cmap="binary_r")
#plt.title("5x downsampled")
#
#plt.figure()
#plt.pcolormesh(mask_10x, cmap="binary_r")
#plt.title("10x downsampled")
#
## create the coordinate reference system
#crs = CRS.from_proj4(PROJSTRING)
## create the projection from lon/lat to x/y
#proj = Transformer.from_crs(crs.geodetic_crs, crs)
#xx, yy = proj.transform(lon_model, lat_model)
#
#plt.figure()
#plt.pcolormesh(xx, yy, mask_5x, cmap="binary_r")
#plt.title("5x downsampled")
#
#plt.figure()
#plt.pcolormesh(xx, yy, mask_10x, cmap="binary_r")
#plt.title("10x downsampled")
#
#plt.figure()
#plt.pcolormesh(xx, yy, out10x[0, :, :], vmax=-60)
#plt.colorbar()
#plt.title("10x downsampled - lat")
#
#plt.figure()
#plt.pcolormesh(xx, yy, out10x[4, :, :])
#plt.colorbar()
#plt.title("10x downsampled - npts")
#
#plt.figure()
#plt.pcolormesh(xx, yy, out5x[0, :, :], vmax=-60)
#plt.colorbar()
#plt.title("5x downsampled - lat")
#
#plt.figure()
#plt.pcolormesh(xx, yy, out5x[4, :, :])
#plt.colorbar()
#plt.title("5x downsampled - npts")
#
#plt.show()
#
#
## topo test
#
#thk5x = compute_block(
#    lon_model,
#    lat_model,
#    bedmachine_5x["thickness"].values,
#    bedmachine_5x["lon"].values,
#    bedmachine_5x["lat"].values,
#    is_stereo=True,
#    is_carth=True,
#    PROJSTRING=PROJSTRING,
#    residual=True,
#)
#
#
#plt.figure()
#plt.pcolormesh(xx, yy, thk5x[0, :, :], vmax=5000)
#plt.colorbar()
#plt.title("5x downsampled - thickness")
#
#subplot_kws = dict(
#    projection=ccrs.SouthPolarStereo(central_longitude=0.0), facecolor="grey"
#)
#plt.figure(figsize=[10, 8])
#ax = plt.axes(projection=ccrs.SouthPolarStereo(central_longitude=0.0))
## ax.stock_img()
#plt.pcolormesh(
#    lon_model,
#    lat_model,
#    thk5x[0, :, :],
#    shading="auto",
#    cmap="jet",
#    transform=ccrs.PlateCarree(),
#), plt.clim(-0, 4000), plt.colorbar()
#ax.set_extent([-180, 180, -55, -90], ccrs.PlateCarree())
#ax.gridlines(color="black", alpha=0.5, linestyle="--")
#
#plt.show()
