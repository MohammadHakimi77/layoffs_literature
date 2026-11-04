# Makefile

# Installation instructions: https://tilburgsciencehub.com/learn/makefile

# Define directories
TEMP_DIR = ../temp
OUTPUT_DIR = ../output
TABFIG_DIR = ../output/figures_and_tables
EXT_DIR = ../externals

# Define documents/figures to be created
all: $(TEMP_DIR)/descriptives.txt \
		 $(TABFIG_DIR)/browsesection_changes.pdf $(TABFIG_DIR)/promoplaylist.tex \
		 $(TABFIG_DIR)/residuals_ml_featuring.pdf \
		 $(TABFIG_DIR)/residual_variation_featuring_hist.pdf \
		 $(TABFIG_DIR)/residual_variation_mlshare_hist.pdf \
		 $(TABFIG_DIR)/treatmentvar_ml.pdf \
		 $(TABFIG_DIR)/treatmentvar_promo.pdf \
		 $(TABFIG_DIR)/content.tex \
		 $(TABFIG_DIR)/results_robust_seasonal.tex \
		 $(TABFIG_DIR)/results_robust_ihs.tex \
		 $(TABFIG_DIR)/covariatebalance.tex \
		 $(TABFIG_DIR)/results.tex

# Individual build rules

# Results table
$(TABFIG_DIR)/results.tex: tables_result.R template_results.tex ../../analysis/output/loglogmodels.RData
	Rscript tables_result.R

# Robustness checks
$(TABFIG_DIR)/results_robust_seasonal.tex $(TABFIG_DIR)/results_robust_ihs.tex: tables_robustness.R template_results_robust_seasonal.tex ../../analysis/output/loglogmodels.RData
	Rscript tables_robustness.R

# Descriptive statistics and figures
$(TABFIG_DIR)/distribution.tex $(TABFIG_DIR)/curatorswide.tex $(TABFIG_DIR)/categories.tex \
	$(TABFIG_DIR)/figure_mlshares.pdf $(TABFIG_DIR)/figure_followers_mlshare.pdf \
	$(TEMP_DIR)/descriptives.txt &: use_tablefill.R proc_aux.R tables_descriptives.R \
	../../analysis/temp/playlists.csv \
	../../analysis/temp/playlist-categories.csv ../../analysis/output/paneldata.csv \
	template_curatorswide.tex template_distribution.tex template_categories.tex
		Rscript tables_descriptives.R
		Rscript personalized_playlists.R
		Rscript tables_categories.R
		
# Overview about content on playlists
$(TABFIG_DIR)/content.tex $(TABFIG_DIR)/superstarplaylist.tex: ../../analysis/temp/placements-selected-only.csv \
	../../analysis/output/paneldata.csv ../../analysis/temp/top_artists_placements.csv template_content.tex tables_content.R
	Rscript tables_content.R
	
# Treatment variation plots
$(TABFIG_DIR)/treatmentvar_ml.pdf $(TABFIG_DIR)/treatmentvar_promo.pdf &: ../../analysis/temp/treated_promo.csv \
  ../../analysis/temp/treated_ml.csv ../../analysis/temp/playlists.csv ../../analysis/output/paneldata.csv figures_treatment_variation.R
	Rscript figures_treatment_variation.R

# Plot with overview about when playlists get promoted by category
$(TABFIG_DIR)/browsesection_changes.pdf $(TABFIG_DIR)/promoplaylist.tex &: proc_aux.R use_tablefill.R ../../analysis/temp/promotions.csv ../../analysis/temp/playlists.csv ../../analysis/output/paneldata.csv plot_promo.R
	Rscript plot_promo.R

# Residual variation plots
$(TABFIG_DIR)/residuals_ml_featuring.pdf $(TABFIG_DIR)/residual_variation_featuring_hist.pdf $(TABFIG_DIR)/residual_variation_mlshare_hist.pdf &: figures_resid_variation.R ../../analysis/output/loglogmodels.RData
	Rscript figures_resid_variation.R

# Evidence on covariate balance
$(TABFIG_DIR)/covariatebalance.tex: tables_covariatebalance.R ../../analysis/output/covariate_balance.RData
	R --vanilla < tables_covariatebalance.R

# Download necessary results data (not necessary to run if receiving all files in \externals)
$(EXT_DIR)/data.log: get_externals.R 
	R --vanilla < get_externals.R
