import sys
import netCDF4

def append_entry_to_netcdf(file_path, i_val, j_val, z_val):
    # Open the NetCDF file in append mode
    with netCDF4.Dataset(file_path, 'r+') as nc:
        # Get the current values from the NetCDF file
        iEdit_values = nc.variables['iEdit'][:]
        jEdit_values = nc.variables['jEdit'][:]
        
        # Check if the entry already exists
        if (i_val in iEdit_values) and (j_val in jEdit_values):
            print("Warning: Entry with the given iEdit and jEdit values already exists.")
            return

        # Append the new values to the respective variables
        nc.variables['iEdit'][:] = list(iEdit_values) + [i_val]
        nc.variables['jEdit'][:] = list(jEdit_values) + [j_val]
        nc.variables['zEdit'][:] = list(nc.variables['zEdit'][:]) + [z_val]

if __name__ == '__main__':
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 5:
        print("Usage: python script_name.py <netcdf_file_path> <iEdit_value> <jEdit_value> <zEdit_value>")
        sys.exit(1)

    # Parse arguments
    file_path = sys.argv[1]
    try:
        i_val = int(sys.argv[2])
        j_val = int(sys.argv[3])
        z_val = int(sys.argv[4])
    except ValueError:
        print("Error: iEdit, jEdit, and zEdit values must be integers.")
        sys.exit(1)

    append_entry_to_netcdf(file_path, i_val, j_val, z_val)

