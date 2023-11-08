# OM5 Horizontal Grid, Topography, and Preprocessing Datasets
# GFDL Ocean Division - October 2023
#
# Makefile for OM5 (Standard South Pole)
# -------------------------------
#
# This Makefile is broken into the following sections
#
#     Part 1: Horizontal Grid
#
#     Part 2: Topography Generation
#        2a: Interpolared Topography with Subgrid Tiles
#        2b: Topgraphy Edits
#        2c: Flood-filling & Connectivity (ICE-9)
#        2d: Reset the wet mask to match OM4
#
#     Part 3: FMS Grid Spec, Mosaic Files, and Mask Tables
#
# Example Usage:
#    make -f Makefile_OM5_rp grid_spec.nc
#    make -f Makefile_OM5_rp mask_tables


# Include additional makefile(s) defining input datasets
include *.mk


# COMMON PATHS & SETTINGS
# -----------------------

# This Makefile relies on two different versions of Python. The updated
# new tools rely on Python 3 while the legacy OM4 tools rely on Python 2.
PYTHON2 = /pad/griduser/.conda/envs/py27/bin/python
PYTHON3 = /pad/griduser/.conda/envs/py311/bin/python

# GFDL O-division has a central repository for common datasets
GOLD_DIR = /archive/gold/datasets

# Directories inside the container with tools
TOOLDIR = /opt/tools
FRE_NCTOOLS = /opt/fre-nctools/bin


# Part 1: Horizontal Grid
# ------------------------

# Use N. Zadeh's `ocean_grid_gnerator.py` tool to create the horizontal grid.
# The resolution is specificed as an "inverse resolution" specified with the
# `-r` flag. The 0.25-degree (1/4) is specified as `-r 4`.

ocean_hgrid.nc:
	ocean_grid_generator.py \
            --write_subgrid_files \
            -f $(@F) \
            -r 4 \
            --south_ocean_lower_lat -88.57 \
            --no_south_cap \
            --match_dy so
 

# Part 2a: Interpolared Topography with Subgrid Tiles
# ---------------------------------------------------

OCEAN_TOPOG_TOOL = create_topog_refinedSampling.py

# The source topography for OM5 is GEBCO 2023, which incorporates IBCAO and
# BEDMACHINE updates that were processed separately in OM4. This command
# below specifies the source location for the GEBCO 2023 data and the variable
# names contained within the file.

OCEAN_TOPOG_SRC = --source_file $(GOLD_DIR)/topography/GEBCO_2023/GEBCO_2023.nc \
                  --source_lon lon \
                  --source_lat lat \
                  --source_elv elevation 

# Bipolar Cap
ocean_topog_BP.nc: 
	$(OCEAN_TOPOG_TOOL) --hgridfilename ./ocean_hgrid.ncBP.nc \
        --max_refine=5 --nxblocks=4 \
        --outputfilename $(@F) $(OCEAN_TOPOG_SRC)

# Mercator Region
ocean_topog_MERC.nc: 
	$(OCEAN_TOPOG_TOOL) --hgridfilename ./ocean_hgrid.ncMerc.nc \
        --max_refine=5 --nxblocks=4 \
        --outputfilename $(@F) $(OCEAN_TOPOG_SRC)

# Southern Ocean Spherical Grid
ocean_topog_SO.nc: 
	$(OCEAN_TOPOG_TOOL) --hgridfilename ./ocean_hgrid.ncSO.nc \
        --max_refine=5 --nxblocks=4 \
        --outputfilename $(@F) $(OCEAN_TOPOG_SRC)

# Merge all tiles together
ocean_topog_merged.nc: ocean_topog_MERC.nc ocean_topog_SO.nc ocean_topog_BP.nc
	merge_topog_tiles.py \
        --tilefiles ocean_topog_SO.nc,ocean_topog_MERC.nc,ocean_topog_BP.nc \
        --outputfilename $(@F)


# Part 2b: Topgraphy Edits
# ------------------------

# Topography edits are applied both in the preprocessing workflow and
# also at model runtime. The preprocessing edits are necessary in order
# to create connectivity that is required for the flood-filling
# alogiright (ICE-9) used in the next step.

# Path of legacy OM4 preprocessing code
MOM6_EXAMPLES_PREPROC = /opt/tools/MOM6-examples/ice_ocean_SIS2/OM4_025/preprocessing

ocean_topog_edited.nc: ocean_topog_merged.nc
	# Use the existing OM4 topography edits
	cp $(MOM6_EXAMPLES_PREPROC)/OM4_topography_edits.nc adjusted_om4_edits.nc
	
	# Shift OM4 topog edits by 40 points; all edits were done on a 
	# larger grid and last step of the OM4 preprocessing chain was to 
	# drop the first 40 rows. The 120 value below deontes where on the
	# OM4 nj=1080 grid that this new grid diverges from the existing one.
	$(PYTHON3) $(TOOLDIR)/auxillary/adjust_topo_edit_jindex.py \
        adjusted_om4_edits.nc 41 120
	
	# The OM4 convention had a flipped sign convention
	cp ocean_topog_merged.nc tmp.nc 
	ncap2 -hs "depth=depth*(-1)" tmp.nc tmp2.nc
	
	# Apply the topography edits using the legacy OM4 tool
	$(PYTHON2) $(MOM6_EXAMPLES_PREPROC)/apply_edits.py adjusted_om4_edits.nc tmp2.nc
	cp tmp2.nc $(@F)
	
	# Flip the sign back 
	# ncap2 -hs "depth=depth*(-1)" tmp2.nc $(@F)
	
	# Remove temporary files
	rm -f tmp.nc
	rm -f tmp2.nc


# Part 2c: Flood-filling & Connectivity (ICE-9)
# ---------------------------------------------

# This step uses the ICE-9 algorighm to determine the basin conenctivity and
# arrive at a wet mask for the grid. (NOTE: this wet mask may be adjusted by
# any runtime topography edits that are used by the model, so this step should
# not be considered the models' final wet mask; refer to the `ocean_static.nc`
# file written by the model at runtime.)

ocean_topog_ice9ed.nc: ocean_topog_edited.nc
	ice9.py ocean_topog_edited.nc --variable 'depth' \
        --iseed 10 --jseed 200 --output $(@F)
	
	# Flip the sign back 
	# ncap2 -hs "depth=depth*(-1)" tmp3.nc $(@F)


# Part 2d: Reset the wet mask to match OM4
# ----------------------------------------

# This step resets the new wet mask to be identical to the existing OM4
# wet mask.

ocean_topog_adjusted_mask.nc: ocean_topog_ice9ed.nc
	$(PYTHON3) $(TOOLDIR)/auxillary/reset_wet_mask.py \
        $(GOLD_DIR)/OM4_025/mosaic.v20170622.unpacked/ocean_topog.nc \
        ocean_topog_ice9ed.nc $(@F)

ocean_topog.nc: ocean_topog_adjusted_mask.nc
	cp ocean_topog_adjusted_mask.nc topog.nc
	ncatted -h -a creation_date,global,c,c,"`date`" topog.nc
	ncatted -h -a source,global,c,c,"GEBCO 2020 remapped via RSC with OM4_025 land mask applied" topog.nc
	ncatted -h -a topo_edits,global,c,c,"True" topog.nc
	cp topog.nc ocean_topog.nc


# Part 3: FMS Grid Spec, Mosaic Files, and Mask Tables
# --------------------------------------

ocean_mosaic.nc: ocean_hgrid.nc ocean_topog.nc
	$(FRE_NCTOOLS)/make_solo_mosaic \
        --num_tiles 1 \
        --dir . \
        --mosaic_name ocean_mosaic \
        --tile_file ocean_hgrid.nc \
        --periodx 360.

grid_spec.nc: ocean_mosaic.nc
	$(FRE_NCTOOLS)/make_quick_mosaic \
        --reproduce_siena \
        --input_mosaic ocean_mosaic.nc \
        --mosaic_name grid_spec \
        --ocean_topog ocean_topog.nc 

mask_tables: $(FRE_NCTOOLS)/check_mask ocean_mosaic.nc ocean_topog.nc
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 20,10
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 20,20
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 36,18
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 36,6
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 26,4
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 90,45
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 90,72
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 32,72
	$(FRE_NCTOOLS)/check_mask --grid_file ocean_mosaic.nc --ocean_topog ocean_topog.nc --layout 45,72
	touch $@


