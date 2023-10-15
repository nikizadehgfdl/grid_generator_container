import os 
import sys
import netCDF4

def modify_netcdf(file_path, offset, min_j=None):
    # Open the original NetCDF file
    with netCDF4.Dataset(file_path, 'r') as nc_orig:
        # Get the variables
        jEdit = nc_orig.variables['jEdit'][:]
        nj = nc_orig.variables['nj']

        # Add offset to jEdit values
        jEdit += offset

        # Add offset to nj
        nj_value = nj[()] + offset

        # min_j should be specified on the `adjusted` grid, so add the offset
        min_j = 0 if min_j is None else min_j+offset

        # Filter out negative jEdit values and associated iEdit and zEdit values
        valid_indices = [idx for idx, val in enumerate(jEdit) if val >= min_j]
        if len(valid_indices) != len(jEdit):
            print("Warning: Some jEdit entries were deleted. Make sure this was intended")

        # Create a new NetCDF file
        new_file_path = file_path.replace('.nc', '_modified.nc')
        with netCDF4.Dataset(new_file_path, 'w') as nc_new:
            # Copy global attributes from the original file
            nc_new.setncatts(nc_orig.__dict__)

            # Define the dimensions
            nc_new.createDimension('nEdits', len(valid_indices))

            # Define the variables and copy the attributes from the original file
            for var_name, var_data in nc_orig.variables.items():
                nc_new.createVariable(var_name, var_data.dtype, var_data.dimensions)
                nc_new.variables[var_name].setncatts(var_data.__dict__)
                if var_name in ['iEdit', 'zEdit']:
                    nc_new.variables[var_name][:] = var_data[valid_indices]
                elif var_name == 'jEdit':
                    nc_new.variables[var_name][:] = jEdit[valid_indices]
                elif var_name == 'nj':
                    nc_new.variables[var_name][:] = nj_value
                else:
                    nc_new.variables[var_name][:] = var_data[:]

            # Add a global attribute noting that the offset was performed
            nc_new.setncattr('Note', f"Offset of {offset} was applied to jEdit and nj")

    # Optionally: Replace the original file with the modified file
    os.rename(new_file_path, file_path)


if __name__ == '__main__':
    # Check if the correct number of arguments are provided
    if len(sys.argv) < 3:
        print("Usage: python script_name.py <netcdf_file_path> <offset> <min_j>")
        sys.exit(1)

    # Parse arguments
    file_path = sys.argv[1]
    try:
        offset = int(sys.argv[2])
    except ValueError:
        print("Error: The offset must be an integer.")
        sys.exit(1)

    if len(sys.argv) == 4:
        min_j = int(sys.argv[3])
    else:
        min_j = 0

    modify_netcdf(file_path, offset, min_j)

