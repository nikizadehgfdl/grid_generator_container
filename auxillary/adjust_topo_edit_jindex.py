import sys
import netCDF4

def modify_netcdf(file_path, offset):
    # Open the NetCDF file in append mode
    with netCDF4.Dataset(file_path, 'r+') as nc:
        # Get the variables
        jEdit = nc.variables['jEdit'][:]
        nj = nc.variables['nj']

        # Add offset to jEdit values
        jEdit += offset

        # Add offset to nj
        nj.assignValue(nj[()] + offset)

        # Filter out negative jEdit values and associated iEdit and zEdit values
        valid_indices = [idx for idx, val in enumerate(jEdit) if val >= 0]
        if len(valid_indices) != len(jEdit):
            print("Warning: Entries with negative jEdit values were deleted.")

        nc.variables['iEdit'][:] = nc.variables['iEdit'][valid_indices]
        nc.variables['jEdit'][:] = jEdit[valid_indices]
        nc.variables['zEdit'][:] = nc.variables['zEdit'][valid_indices]

        # Add a global attribute noting that the offset was performed
        nc.setncattr('Note', f"Offset of {offset} was applied to jEdit and nj")

if __name__ == '__main__':
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 3:
        print("Usage: python script_name.py <netcdf_file_path> <offset>")
        sys.exit(1)

    # Parse arguments
    file_path = sys.argv[1]
    try:
        offset = int(sys.argv[2])
    except ValueError:
        print("Error: The offset must be an integer.")
        sys.exit(1)

    modify_netcdf(file_path, offset)

