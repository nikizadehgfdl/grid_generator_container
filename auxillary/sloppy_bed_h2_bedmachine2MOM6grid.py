#!/usr/bin/env python
""" Script to Remap BedMachine Data """


import sys

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


def main(hgrid, src, dest):
    PROJSTRING = "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"

    # ---------------- bedmachine + reduction
    bedmachine = xr.open_dataset(src)

    xx_bm_full, yy_bm_full = np.meshgrid(bedmachine["x"].values, bedmachine["y"].values)

    # ----------------- read lon/lat MOM6 grid corners until 60S
    hgrid = xr.open_dataset(hgrid)
    j60s = 562

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

    out.to_netcdf(dest)


if __name__ == "__main__":
    print("Running BedMachine Remapping")
    # original source: /net2/rnd/BedMachineAntarctica_2020-07-15_v02.nc
    # hgrid can be the South Pole subgrid: i.e. ocean_hgridSP_025deg
    hgrid = sys.argv[1]
    src = sys.argv[2]
