# Salt Restoring File
# -------------------
# The JRA55-do dataset provides an annual cycle climatology file to use
# for salt restoring. The climatology spans years 1955 to 2012 and is
# derived from World Ocean Atlas 2013 v2. The salinity is averaged over
# the uppermost 10-m in the water column and is better interpreted as
# salinity at 5-m depth rather than at the surface. (Tsijuno et al. 2018)
# https://doi.org/10.1016/j.ocemod.2018.07.002

# The climatology file used here was downloaded with JRA v1.4. It is
# assumed that this file is unchanged for future versions of JRA.
# This needs to be verified, but the download from ESGF is not working
# as of 13-Oct-2013

sos_climatology_WOA13v2_provided_by_JRA55-do_v1_4.nc:
	cp $(GOLD_DIR)/reanalysis/JRA55-do/v1.4.0/original/sos_input4MIPs_atmosphericState_OMIP_MRI-JRA55-do-1-4-0_gr_195501-201212-clim.nc $(@F)
	ncap2 -h -O -s 'time(:)={15,45,76,106,136,168,198,228,258,288,320,350}' $(@F) $(@F)
	ncatted -h -O -a units,time,o,c,'days since 1900-01-01 00:00:00' $(@F)
	ncatted -h -O -a long_name,time,o,c,'Day of year' $(@F)
	ncatted -h -O -a calendar,time,o,c,'julian' $(@F)
	ncatted -h -O -a modulo,time,c,c,' ' $(@F)
	ncatted -h -O -a calendar_type,time,c,c,'julian' $(@F)

salt_restore_JRA.nc: sos_climatology_WOA13v2_provided_by_JRA55-do_v1_4.nc
	$(TOOLDIR)/interp_and_fill/interp_and_fill.py \
        ocean_hgrid.nc \
        ocean_mask.nc \
	sos_climatology_WOA13v2_provided_by_JRA55-do_v1_4.nc \
        sos --fms --closest $(@F)


# JRA Runoff Files
# ----------------
JRA_VER = v1.4.0
pad_JRA:
	rm -fR pad_JRA
	mkdir pad_JRA
	cp -v $(GOLD_DIR)/reanalysis/JRA55-do/$(JRA_VER)/padded/friver_*.nc pad_JRA/.
	cp -v $(GOLD_DIR)/reanalysis/JRA55-do/$(JRA_VER)/padded/licalvf_*.nc pad_JRA/.

JRA_DIR = pad_JRA
#JRA_DIR = $(GOLD_DIR)/reanalysis/JRA55-do/$(JRA_VER)/padded
JRA_FILES = $(wildcard $(JRA_DIR)/friver_*.nc $(JRA_DIR)/licalvf_*.nc)
TARGS = $(subst padded.,padded.compressed.,$(notdir $(JRA_FILES)))
COMPRESS =

all: $(TARGS) hash.md5
	md5sum -c hash.md5

friver_%padded.nc: $(JRA_DIR)/friver_%padded.nc
	@echo "Executing rule for $@"
	$(TOOLDIR)/OM4_025_runoff_JRA/regrid_runoff/regrid_runoff.py --fast_pickle ocean_hgrid.nc ocean_mask.nc $< --fms -r friver $(COMPRESS) $@
licalvf_%padded.nc: $(JRA_DIR)/licalvf_%padded.nc
	$(TOOLDIR)/OM4_025_runoff_JRA/regrid_runoff/regrid_runoff.py --fast_pickle ocean_hgrid.nc ocean_mask.nc $< --fms -r licalvf $(COMPRESS) $@
%padded.compressed.nc: %padded.nc
	nccopy -d 9 $< $@

hash.md5: | $(TARGS)
	md5sum $(TARGS) > $@
