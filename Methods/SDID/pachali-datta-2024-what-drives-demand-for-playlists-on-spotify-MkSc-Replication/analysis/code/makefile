# Makefile
# Installation instructions: https://tilburgsciencehub.com/learn/makefile

# Define directories
TEMP_DIR = ../temp
OUTPUT_DIR = ../output
EXT_DIR = ../externals

# Main parameters for production (remove # of next lines)
controlsize = 2500
nrepl = 200
fullsamplesize = 99999 # 99999 is interpreted as full sample estimation downstream

# Use for testing only (remove # of next lines)
# controlsize = 500
# nrepl = 10
# fullsamplesize = 200

# Define part of file naming convention
filename = $(controlsize)_$(nrepl)

# Build rules
all: loglog sdid

sdid: $(OUTPUT_DIR)/syndid_results.RData $(OUTPUT_DIR)/syndid_summary.csv \
		  $(OUTPUT_DIR)/covariate_balance.RData
		  
did: $(OUTPUT_DIR)/did_results.txt 

loglog: $(OUTPUT_DIR)/loglogmodels.RData

main_models.txt: $(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_promo_logfollowers.RData \
						$(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_ml_logfollowers.RData
	touch main_models.txt
	
robustness.txt: $(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_promoremoveotherseasonal_logfollowers.RData \
						$(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_promo_logfollowers_ihs.RData \
						$(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_ml_logfollowers_ihs.RData
	touch robustness.txt

required_models.txt: main_models.txt robustness.txt
	touch required_models.txt
	
clean:
	Rscript -e "unlink('../temp/*')"
	Rscript -e "unlink('../output/*')"
	Rscript -e "unlink('../externals/*')"
	

raw: $(EXT_DIR)/data.log # download data
unzip: $(TEMP_DIR)/unzipping.log $(TEMP_DIR)/panel.csv $(TEMP_DIR)/promotions.csv $(TEMP_DIR)/playlists.csv $(TEMP_DIR)/playlist-categories.csv $(TEMP_DIR)/platform_promo_releases.csv $(EXT_DIR)/placements-firstadded.csv

############
# Workflow #
############

# Getting and unzipping the raw data
$(EXT_DIR)/data.log: get_externals.R
	R --vanilla < get_externals.R

$(TEMP_DIR)/unzipping.log $(TEMP_DIR)/panel.csv $(TEMP_DIR)/playlists.csv $(TEMP_DIR)/playlist-categories.csv $(TEMP_DIR)/promotions.csv $(TEMP_DIR)/top_artists_placements.csv $(TEMP_DIR)/top_artists.csv &: unzip.R $(EXT_DIR)/data.log
	Rscript unzip.R

# Pre-cleaning
# =================

# Pre cleaning panel data
$(OUTPUT_DIR)/paneldata.csv: preclean.R $(TEMP_DIR)/playlists.csv $(TEMP_DIR)/panel.csv $(TEMP_DIR)/playlist-categories.csv $(TEMP_DIR)/top_artists_placements.csv $(TEMP_DIR)/top_artists.csv $(TEMP_DIR)/promotions_cleaned.csv
	R --vanilla < preclean.R

# Pre-cleaning promotions
$(TEMP_DIR)/promotions_cleaned.csv: preclean_promotions.R $(TEMP_DIR)/promotions.csv $(TEMP_DIR)/playlists.csv
	R --vanilla < preclean_promotions.R

# Event selection
# ==================

# DiD event selection
$(TEMP_DIR)/treated_ml.csv: find_treated_ml.R $(OUTPUT_DIR)/paneldata.csv $(TEMP_DIR)/panel.csv $(TEMP_DIR)/top_artists_placements.csv $(TEMP_DIR)/top_artists.csv $(TEMP_DIR)/playlists.csv
	R --vanilla < find_treated_ml.R

$(TEMP_DIR)/treated_promo.csv: find_treated_promo.R $(OUTPUT_DIR)/paneldata.csv $(TEMP_DIR)/panel.csv $(TEMP_DIR)/promotions.csv $(TEMP_DIR)/playlists.csv
	R --vanilla < find_treated_promo.R

# Synthetic DiD
# ===================

# Building the DiD panel
$(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData: build_balanced_panels.R $(OUTPUT_DIR)/paneldata.csv $(TEMP_DIR)/panel.csv $(TEMP_DIR)/promotions.csv $(TEMP_DIR)/playlists.csv $(TEMP_DIR)/treated_promo.csv $(TEMP_DIR)/treated_ml.csv
	R --vanilla < build_balanced_panels.R
	
# Synthetic DiD estimation: promotions
$(OUTPUT_DIR)/synthdid_results_matched_$(filename)_promo_logfollowers.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(controlsize) $(nrepl) promo

# Synthetic DiD estimation: promotions (with full control sample)
$(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_promo_logfollowers.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(fullsamplesize) $(nrepl) promo

# Synthetic DiD estimation: promotions (IHS)
$(OUTPUT_DIR)/synthdid_results_matched_$(filename)_promo_logfollowers_ihs.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(controlsize) $(nrepl) promo logfollowers_ihs

# Synthetic DiD estimation: promotions (IHS, with full control sample)	
$(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_promo_logfollowers_ihs.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(fullsamplesize) $(nrepl) promo logfollowers_ihs

# Synthetic DiD estimation: promotions (remove other seasonal)
$(OUTPUT_DIR)/synthdid_results_matched_$(filename)_promoremoveotherseasonal_logfollowers.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(controlsize) $(nrepl) promoremoveotherseasonal

# Synthetic DiD estimation: promotions (remove other seasonal, with full control sample)
$(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_promoremoveotherseasonal_logfollowers.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(fullsamplesize) $(nrepl) promoremoveotherseasonal

# Synthetic DiD estimation: major-label superstars
$(OUTPUT_DIR)/synthdid_results_matched_$(filename)_ml_logfollowers.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(controlsize) $(nrepl) ml

# Synthetic DiD estimation: major-label superstars (with full control sample)
$(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_ml_logfollowers.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(fullsamplesize) $(nrepl) ml

# Synthetic DiD estimation: major-label superstars (IHS)
$(OUTPUT_DIR)/synthdid_results_matched_$(filename)_ml_logfollowers_ihs.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(controlsize) $(nrepl) ml logfollowers_ihs

# Synthetic DiD estimation: major-label superstars (IHS, with full control sample)
$(OUTPUT_DIR)/synthdid_results_matched_$(fullsamplesize)_$(nrepl)_ml_logfollowers_ihs.RData: synthetic_did.R $(OUTPUT_DIR)/estpanel_sdid_minwindow_15.RData
	R --vanilla < synthetic_did.R --args $(fullsamplesize) $(nrepl) ml logfollowers_ihs

# Aggregate synthetic DiD results
$(OUTPUT_DIR)/syndid_results.RData $(OUTPUT_DIR)/syndid_summary.csv &: aggregate_synthdid.R required_models.txt
	R --vanilla < aggregate_synthdid.R


# Estimation of 2WFE model
# ==========================

# Estimation of log-log model
$(OUTPUT_DIR)/loglogmodels.RData: loglog-regressions.R $(OUTPUT_DIR)/paneldata.csv
	R --vanilla < loglog-regressions.R
	
# Assess covariate balance for synthetic DiD models
$(OUTPUT_DIR)/covariate_balance.RData: covariate_balance.R $(OUTPUT_DIR)/synthdid_results_matched_$(filename)_ml_logfollowers.RData \
																						$(OUTPUT_DIR)/synthdid_results_matched_$(filename)_promo_logfollowers.RData $(OUTPUT_DIR)/paneldata.csv
	R --vanilla < covariate_balance.R
