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


###   # Salt Restore File
###   # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###   salt_restore.nc: ocean_hgrid.nc ocean_mosaic.nc PHC2_salx.2004_08_03.corrected.nc tools/interp_and_fill
###   	tools/interp_and_fill/interp_and_fill.py  ocean_hgrid.nc ocean_mask.nc PHC2_salx.2004_08_03.corrected.nc SALT --fms --closest $(@F)
###   	ncatted -h -a modulo,time,c,c,' ' $(@F)
###   	ncatted -h -a units,time,m,c,'days since 0001-01-01 00:00:00' $(@F)
###   
###   PHC2_salx.2004_08_03.corrected.nc: PHC2_salx.2004_08_03.nc
###   	ncap2 -h -O -s 'time(:)={15,45,76,106,136,168,198,228,258,288,320,350}' PHC2_salx.2004_08_03.nc PHC2_salx.2004_08_03.corrected.nc
###   	ncatted -h -O -a units,time,o,c,'days since 1900-01-01 00:00:00' PHC2_salx.2004_08_03.corrected.nc
###   	ncatted -h -O -a long_name,time,o,c,'Day of year' PHC2_salx.2004_08_03.corrected.nc
###   	ncatted -h -O -a calendar,time,c,c,'julian' PHC2_salx.2004_08_03.corrected.nc
###   	ncatted -h -O -a modulo,time,c,c,' ' PHC2_salx.2004_08_03.corrected.nc
###   	ncatted -h -O -a calendar_type,time,c,c,'julian' PHC2_salx.2004_08_03.corrected.nc
###   
###   PHC2_salx.2004_08_03.nc:
###   	wget http://data1.gfdl.noaa.gov/~nnz/mom4/COREv1/support_data/PHC2_salx.2004_08_03.nc
###   
###   
###   # River Runoff File
###   # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###   $(TOOLS)/regrid_runoff:
###   	mkdir -p $(TOOLS) 
###   	cd $(TOOLS); git clone -b nikizadehgfdl/use_netcdf4_deflation https://github.com/nikizadehgfdl/regrid_runoff.git
###   
###   runoff.daitren.clim.nc: $(TOOLS)/regrid_runoff ocean_mosaic.nc ocean_mask.nc
###   #This needs python 3 + numba
###   #	(cd $(@D); time /net2/nnz/adcroft/regrid_runoff/regrid_runoff.py ocean_hgrid.nc ocean_mask.nc ../runoff.daitren.clim.v2011.02.10.nc --fms runoff_tmp.nc
###   #This needs python 3 
###   	cd $(@D); time ../tools/regrid_runoff/regrid_runoff_nonumba.py ocean_hgrid.nc ocean_mask.nc /archive/gold/datasets/CORE/NYF_v2.0/runoff.daitren.clim.v2011.02.10.nc --fms $(@F)  --progress
###   	cd $(@D); ncks -h -3 -O $(@F) $(@F)
###   	cd $(@D); ncatted -h -O -a 'modulo,time,c,c, ' $(@F)
###   
###   runoff.daitren.iaf.nc: ocean_mosaic.nc ocean_mask.nc tools/regrid_runoff
###   	cd $(@D); time $(TOOLS)/regrid_runoff/regrid_runoff_nonumba.py ocean_hgrid.nc ocean_mask.nc /archive/gold/datasets/CORE/IAF_v2.0/runoff.daitren.iaf.v2011.02.10.nc --fms $(@F) --progress
###   	cd $(@D); ncks -h -3 -O $(@F) $(@F)
###   	cd $(@D); ncatted -h -O -a 'modulo,time,c,c, ' $(@F)
###   	cd $(@D); ncatted -h -O -a modulo_beg,time,a,c,"1948-01-01 00:00:00" $(@F)
###   	cd $(@D); ncatted -h -O -a modulo_end,time,a,c,"2008-01-01 00:00:00" $(@F)
