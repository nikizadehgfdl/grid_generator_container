# Ocean color / chlorophyll file
# ------------------------------
seawifs-clim-1997-2010.nc: ocean_hgrid.nc ocean_mask.nc
	$(TOOLDIR)/interp_and_fill/interp_and_fill.py \
        ocean_hgrid.nc \
        ocean_mask.nc \
        $(GOLD_DIR)/obs/SeaWiFS/fill_ocean_color/seawifs-clim-1997-2010.nc  \
        chlor_a --fms $(@F)


# Tidal amplitude file
# --------------------
# Script writted by Raf Dussin
tidal_amplitude.nc: ocean_hgrid.nc ocean_topog.nc
	$(PYTHON3) \
        $(TOOLDIR)/auxillary/remap_Tidal_forcing_TPXO9.py \
        ocean_hgrid.nc \
        ocean_topog.nc \
        $(GOLD_DIR)/obs


# Geothermal Flux
# ---------------
# Geothermal flux is a time-invariant field. The source data are a CSV
# CSV file that is contained in the supplemental material of 
# Davies et al. 2013 (https://doi.org/10.1002/ggge.20271). The CSV file
# was converted to a NetCDF file using the `convert_Davies_2013.py` script.
# A copy of the NetCDF file is stored in $(GOLD_DIR) and is regridded to
# the model horizontal grid using `regrid_geothermal.py`

geothermal_davies2013_v1.nc:
	rm -f convert_Davies_2013
	ln -s /archive/gold/datasets/obs/convert_Davies_2013 .
	$(PYTHON3) $(TOOLDIR)/OM4_05_preprocessing_geothermal/regrid_geothermal.py
	rm -f convert_Davies_2013

INPUT: seawifs-clim-1997-2010.nc tidal_amplitude.nc geothermal_davies2013_v1.nc
	mkdir -p INPUT
	mv -v seawifs-clim-1997-2010.nc INPUT/.
	mv -v tidal_amplitude.nc INPUT/.
	mv -v geothermal_davies2013_v1.nc INPUT/.
