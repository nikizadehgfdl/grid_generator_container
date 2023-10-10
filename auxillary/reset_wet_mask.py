import sys
import numpy as np
import datetime
import netCDF4
import xarray as xr
from scipy.ndimage import generic_filter


def interp_and_reset_mask(arr, arr_mask, target_mask):
    def _filling_function(values):
        """Function to compute the value for filling missing entries. Only considers positive values."""
        positive_values = values[values > 0]
        return np.mean(positive_values) if positive_values.size else np.nan

    def _fill_missing_values(array):
        """Fills missing values (np.nan) in the array by considering adjacent valid positive points."""

        # Define a footprint for the filter to consider all 8 neighbors + the center point
        footprint = np.ones((3, 3), dtype=bool)

        changes_made = True
        while changes_made:
            changes_made = False
            # Apply the generic filter to compute the mean of the positive neighboring values for each point
            filled_values = generic_filter(
                array,
                _filling_function,
                footprint=footprint,
                mode="constant",
                cval=np.nan,
            )

            # Fill the missing values in the array with the computed means, if they are not NaN
            mask = np.isnan(array) & ~np.isnan(filled_values)
            if np.any(mask):
                changes_made = True
                array[mask] = filled_values[mask]

        return array

    mask_diff = target_mask - arr_mask

    candidate = xr.where(mask_diff != 0, np.nan, arr)
    candidate = xr.where(candidate == 0, -999, candidate)
    candidate = np.array(candidate)
    candidate = _fill_missing_values(candidate)

    candidate = candidate * target_mask
    candidate = np.where(candidate < 0, 0, candidate)

    verification = np.where(candidate > 0.0, 1.0, 0.0)
    try:
        error = (verification - target_mask).sum()
        assert error == 0.0
    except AssertionError as exc:
        raise ValueError(f"Mask difference not zero: {error}")

    return candidate


target_topog_file = sys.argv[1]
existing_topog_file = sys.argv[2]
outfile = sys.argv[3]

target_topog_file = xr.open_dataset(target_topog_file)
existing_topog_file = xr.open_dataset(existing_topog_file)

target_wet_mask = xr.where(target_topog_file["depth"] > 0.0, 1.0, 0.0)
existing_wet_mask = xr.where(existing_topog_file["depth"] > 0.0, 1.0, 0.0)

adjusted_depth = interp_and_reset_mask(
    existing_topog_file["depth"], existing_wet_mask, target_wet_mask
)

dsout = xr.Dataset()
dsout["depth"] = xr.DataArray(adjusted_depth, dims=("ny", "nx")).astype("float32")

dsout["depth"].attrs = {
    "units": "meters",
    "standard_name": "topographic depth at T-cell centers",
    "description": "Non-negative nominal thickness of the ocean at cell centers",
    "comment": "Wet mask was adjusted to match another dataset",
}

# for var in ["h2","h_std","h_min","h_max","iEdit","jEdit","zEdit"]:
for var in ["h2", "iEdit", "jEdit", "zEdit"]:
    if var in list(existing_topog_file.keys()):
        dsout[var] = existing_topog_file[var]

encoding = {x: {"_FillValue": None} for x in list(dsout.keys())}
dsout.to_netcdf(outfile, encoding=encoding, format="NETCDF3_CLASSIC")

with netCDF4.Dataset(outfile, "a") as rootgrp:
    rootgrp.createDimension("ntiles", 1)
