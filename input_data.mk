###   # Ocean Color file
###   # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###   seawifs-clim-1997-2010.nc: tools/interp_and_fill
###   #ocean_hgrid.nc ocean_mask.nc tools/interp_and_fill 
###   	dmget /archive/gold/datasets/obs/SeaWiFS/fill_ocean_color/seawifs-clim-1997-2010.nc
###   	ln -s /archive/gold/datasets/obs/SeaWiFS/fill_ocean_color/seawifs-clim-1997-2010.nc seawifs-clim-1997-2010_source.nc
###   	tools/interp_and_fill/interp_and_fill.py ocean_hgrid.nc ocean_mask.nc seawifs-clim-1997-2010_source.nc  chlor_a --fms $(@F)
###   #	cd $(@D); ncrename -O -v chlor_a,CHL_A seawifs-clim-1997-2010.nc seawifs-clim-1997-2010.nc
###   #	cd $(@D); ncatted -h -a modulo,TIME,c,c,' ' $(@F)
###   
###   
###   #////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
###   #////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
###   #////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
###   
###   
###   # Temperature and Salinity Initialization
###   # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###   #This is already done for 1/2,1/4,1/8 degrees
###   #Use https://github.com/adcroft/convert_WOA13
###   WOA05_ptemp_salt_monthly.nc: ocean_hgrid.nc ocean_topog.nc
###   	python tools/convert_WOA13/
###   	ncatted -h -a modulo,TIME,c,c,' ' WOA05_ptemp_salt_monthly.nc
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
###   
###   
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
###   
###   
###   # Geothermal Flux
###   # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###   #regrid geothermal_davies2013
###   geothermal_davies2013_v1.nc: tools/preprocessing_geothermal/Makefile convert_Davies_2013/ggge20271-sup-0003-Data_Table1_Eq_lon_lat_Global_HF.nc
###   	\rm convert_Davies_2013 ; ln -s /archive/gold/datasets/obs/convert_Davies_2013 .; python tools/preprocessing_geothermal/regrid_geothermal.py
###   convert_Davies_2013/ggge20271-sup-0003-Data_Table1_Eq_lon_lat_Global_HF.nc:
###   	\rm convert_Davies_2013 ; ln -s /archive/gold/datasets/obs/convert_Davies_2013 .
###   tools/preprocessing_geothermal/Makefile:
###   	git clone https://github.com/adcroft/OM4_05_preprocessing_geothermal.git $(@D)
###   	#cd $(@D); make convert_Davies_2013/ggge20271-sup-0003-Data_Table1_Eq_lon_lat_Global_HF.nc
###   
###   
###   
###   # Ocean Color file
###   # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###   tidal_amplitude.nc: ocean_hgrid.nc ocean_topog.nc
###   	python tools/remap_Tidal_forcing_TPXO9.py 
###   
###   
###   
###   clean:
###   #	-rm -rf fre_nctools local tools
###   	-rm -rf stdout *.nc logfile* input.nml 
###   
###   tools/md5sums.txt:
###   	md5sum *.nc >> $@
###   
###   mosaic.tar:
###   	tar cvf $(@F) ocean_hgrid.nc ocean_topog.nc ocean_mosaic.nc land_mask.nc ocean_mask.nc atmos_mosaic_tile*.nc land_mosaic_tile*.nc grid_spec.nc salt_restore.nc geothermal_davies2013_v1.nc Makefile.* tidal_amplitude.nc mask_table.* runoff.daitren.iaf.nc seawifs-clim-1997-2010.nc
