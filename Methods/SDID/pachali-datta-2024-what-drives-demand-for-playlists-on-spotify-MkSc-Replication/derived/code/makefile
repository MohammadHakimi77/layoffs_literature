# Makefile for \derived of the platform power project
# by Hannes Datta
# requires GNU Make

TEMP_DIR = ../temp
OUTPUT_DIR = ../output
EXT_DIR = ../externals
EXPORT_DIR = ../export

#go: $(OUTPUT_DIR)/platformpower.zip

all: pclean categories merge_all diddata zip 

zip: $(EXPORT_DIR)/platformpower.zip

audit: $(TEMP_DIR)/audit.txt

###### BUILD COMMANDS ######

test0: $(OUTPUT_DIR)/placements-below150k.csv
rec: $(OUTPUT_DIR)/recommendations.csv
agg: $(OUTPUT_DIR)/placements-aggregated.csv

place: $(OUTPUT_DIR)/placements.csv

diddata: $(OUTPUT_DIR)/top_artists.csv $(OUTPUT_DIR)/top_artists_placements.csv

test:
	R -e "source('test.R')"

# clean directories
clean:
	RM -f -r "$(TEMP_DIR)"
	RM -f -r "$(OUTPUT_DIR)"
	MKDIR "$(OUTPUT_DIR)"

labels: $(OUTPUT_DIR)/labels.csv

##############################
###### DOWNLOAD RAW DATA #####
##############################

$(EXT_DIR)/data.log $(EXT_DIR)/chartmetric.zip $(EXT_DIR)/cm-export_playlist.csv $(EXT_DIR)/cm-export_artist.csv \
	$(EXT_DIR)/everynoise-new-releases.csv $(EXT_DIR)/webapi-new-releases.csv \
	$(EXT_DIR)/webapi-new-releases-acoustics.csv $(EXT_DIR)/kaggle/billboardHot100_1999-2019.csv $(EXT_DIR)/kaggle/spotifyWeeklyTop200Streams.csv: get_externals.R
	Rscript get_externals.R

$(EXT_DIR)/all-playlists.csv $(EXT_DIR)/playlist-placements.csv $(EXT_DIR)/playlist-placements-below150k.csv $(EXT_DIR)/playlist-placements-recommendations.csv ../externals/playlist-followers.csv ../externals/playlist-followers-recommendations.csv ../externals/fans-instagram.csv: $(EXT_DIR)/data.log
	python3 unzip.py

#####################
###### PRECLEAN #####
#####################

pclean: $(OUTPUT_DIR)/playlists.csv $(OUTPUT_DIR)/placements.csv $(OUTPUT_DIR)/placements-below150k.csv $(OUTPUT_DIR)/placements-recommendations.csv $(TEMP_DIR)/followers.csv $(OUTPUT_DIR)/artists.csv $(OUTPUT_DIR)/labels.csv 

$(OUTPUT_DIR)/playlists.csv: $(EXT_DIR)/all-playlists.csv preclean_playlists.R $(OUTPUT_DIR)/labels.csv $(OUTPUT_DIR)/artists.csv
	R --vanilla --args "" < "preclean_playlists.R"

$(TEMP_DIR)/followers.csv: $(EXT_DIR)/playlist-followers.csv $(EXT_DIR)/playlist-followers-recommendations.csv preclean_followers.R
	R --vanilla --args "" < "preclean_followers.R"

$(OUTPUT_DIR)/followers-listeners.csv:  $(TEMP_DIR)/followers.csv interpolate_followers-listeners.R 
	R --vanilla --args "" < "interpolate_followers-listeners.R"
	
$(OUTPUT_DIR)/placements.csv $(OUTPUT_DIR)/artist-ids.csv: $(EXT_DIR)/playlist-placements.csv preclean_placements.R
	R --vanilla < preclean_placements.R --args $(EXT_DIR)/playlist-placements.csv $(OUTPUT_DIR)/placements.csv $(OUTPUT_DIR)/artist-ids.csv

$(OUTPUT_DIR)/placements-below150k.csv  $(OUTPUT_DIR)/artist-ids-below150k.csv: $(EXT_DIR)/playlist-placements-below150k.csv preclean_placements.R 
	R --vanilla < preclean_placements.R --args $(EXT_DIR)/playlist-placements-below150k.csv $(OUTPUT_DIR)/placements-below150k.csv $(OUTPUT_DIR)/artist-ids-below150k.csv

$(OUTPUT_DIR)/placements-recommendations.csv $(OUTPUT_DIR)/artist-ids-recommendations.csv: $(EXT_DIR)/playlist-placements-recommendations.csv preclean_placements.R 
	R --vanilla < preclean_placements.R --args $(EXT_DIR)/playlist-placements-recommendations.csv $(OUTPUT_DIR)/placements-recommendations.csv $(OUTPUT_DIR)/artist-ids-recommendations.csv


$(OUTPUT_DIR)/fans.csv: $(EXT_DIR)/fans-instagram.csv preclean_fans.R 
	R --vanilla --args "" < "preclean_fans.R"
		
$(TEMP_DIR)/fans_interpolated.csv: $(OUTPUT_DIR)/fans.csv interpolate_fans.R
	R --vanilla --args "" < "interpolate_fans.R"

$(OUTPUT_DIR)/labels.csv: $(EXT_DIR)/playlist-placements.csv $(EXT_DIR)/playlist-placements-below150k.csv $(EXT_DIR)/playlist-placements-recommendations.csv labels.R 
	R --vanilla --args "" < "labels.R"

$(OUTPUT_DIR)/artists.csv: $(EXT_DIR)/playlist-placements.csv get_artists.R
	R --vanilla --args "" < "get_artists.R"

# classify labels into major versus indie labels 
# as well as the identification of playlist owners on the platform


##########################
# DYNAMIC CATEGORIZATION #
##########################

categories: $(OUTPUT_DIR)/playlist-categories.csv

# extract static tag words from raw data
$(OUTPUT_DIR)/tags-playlists.csv $(OUTPUT_DIR)/tags-playlists.txt $(OUTPUT_DIR)/tags-playlists-meta.csv $(OUTPUT_DIR)/tags-playlists-meta.txt: extract-tags-playlists.R $(EXT_DIR)/all-playlists.csv
	R --vanilla < "extract-tags-playlists.R"

# extract dynamic tag words from raw data
$(TEMP_DIR)/tags-placements.csv: extract-tags-placements.R $(EXT_DIR)/all-playlists.csv $(OUTPUT_DIR)/placements.csv
		R --vanilla < extract-tags-placements.R

# combine static and dynamic tag words
$(OUTPUT_DIR)/tags-playlists-placements.csv $(OUTPUT_DIR)/tags-playlists-placements-meta.csv: tags_combine.R $(OUTPUT_DIR)/tags-playlists.csv $(OUTPUT_DIR)/tags-playlists-meta.csv $(OUTPUT_DIR)/playlists.csv $(TEMP_DIR)/tags-placements.csv
		R --vanilla < tags_combine.R

# learn association rules
$(TEMP_DIR)/rules.csv: $(OUTPUT_DIR)/tags-playlists-placements.csv $(OUTPUT_DIR)/tags-playlists-placements-meta.csv $(OUTPUT_DIR)/playlists.csv tags_learn_rules.R
		R --vanilla < tags_learn_rules.R

# apply association rules dynamically
$(OUTPUT_DIR)/playlist-categories.csv: tags_apply.R $(TEMP_DIR)/tags-placements.csv $(TEMP_DIR)/rules.csv $(OUTPUT_DIR)/playlists.csv
		R --vanilla < tags_apply.R

#############
# WRANGLING #
#############

# classify artists and tracks in ML vs. not
$(OUTPUT_DIR)/artist-labels.csv $(OUTPUT_DIR)/track-labels.csv: $(OUTPUT_DIR)/placements.csv $(OUTPUT_DIR)/placements-below150k.csv $(OUTPUT_DIR)/placements-recommendations.csv  $(OUTPUT_DIR)/labels.csv classify_artist-track-labels.R
	R --vanilla --args "" < "classify_artist-track-labels.R"

$(TEMP_DIR)/track_popularity.csv $(TEMP_DIR)/track_popularity_raw.csv: track_popularity.R aggregate_setup.R $(OUTPUT_DIR)/playlists.csv $(OUTPUT_DIR)/placements.csv $(TEMP_DIR)/fans_interpolated.csv
	R --vanilla --args "" < track_popularity.R
	
# aggregate to playlist-period
$(OUTPUT_DIR)/placements-aggregated.csv $(OUTPUT_DIR)/playlist-category-selection.csv: $(OUTPUT_DIR)/placements.csv $(TEMP_DIR)/fans_interpolated.csv \
			aggregate_placements.R $(OUTPUT_DIR)/playlists.csv aggregate_setup.R $(OUTPUT_DIR)/track-labels.csv $(OUTPUT_DIR)/playlist-categories.csv \
			$(TEMP_DIR)/extract-collaborations.csv $(TEMP_DIR)/track_popularity.csv
	R --vanilla --args "" < "aggregate_placements.R"

# merge and preclean placements-recommendations
$(TEMP_DIR)/placements-recommendations-filtered.csv: $(OUTPUT_DIR)/placements-below150k.csv $(OUTPUT_DIR)/placements.csv $(OUTPUT_DIR)/placements-recommendations.csv preclean_recommendations.R $(OUTPUT_DIR)/playlists.csv 
	R --vanilla < preclean_recommendations.R
	
$(OUTPUT_DIR)/recommendations.csv $(OUTPUT_DIR)/recommendations-by-category.csv: $(TEMP_DIR)/placements-recommendations-filtered.csv $(TEMP_DIR)/rules.csv
	R --vanilla < recommendations.R

#########
# MERGE #
#########

merge_all: $(OUTPUT_DIR)/panel.csv $(OUTPUT_DIR)/panel.txt
# $(OUTPUT_DIR)/placements-aggregated.csv

# remaining documentation
$(EXPORT_DIR)/promotions.csv $(EXPORT_DIR)/placements-selected-only.csv $(EXPORT_DIR)/playlist-categories.csv $(EXPORT_DIR)/playlists.csv $(EXPORT_DIR)/top_artists_placements.csv $(EXPORT_DIR)/panel.csv: doc.R
	R --vanilla < doc.R

# merge

merge: $(OUTPUT_DIR)/panel.csv

$(OUTPUT_DIR)/panel.csv $(OUTPUT_DIR)/panel.txt: $(OUTPUT_DIR)/placements-aggregated.csv $(OUTPUT_DIR)/playlists.csv $(TEMP_DIR)/followers.csv merge.R $(OUTPUT_DIR)/recommendations.csv $(OUTPUT_DIR)/followers-listeners.csv
	R --vanilla --args "" < "merge.R"

# Zip
$(EXPORT_DIR)/platformpower.zip: zip.py $(EXPORT_DIR)/panel.csv \
$(EXPORT_DIR)/promotions.csv $(EXPORT_DIR)/placements-selected-only.csv $(EXPORT_DIR)/playlist-categories.csv $(EXPORT_DIR)/playlists.csv $(EXPORT_DIR)/top_artists_placements.csv
	python3 zip.py

# Top artist placement (for diff-in-diff)
$(OUTPUT_DIR)/top_artists.csv $(OUTPUT_DIR)/top_artists_placements.csv: aggregate_setup.R \
		$(OUTPUT_DIR)/artist-labels.csv $(TEMP_DIR)/fans_interpolated.csv
	R --vanilla < top_artist_placements.R
	
#upload: $(OUTPUT_DIR)/platformpower.zip
#	aws s3 cp ../output/platformpower.zip s3://uvt-platformpower/derived/2019_01_28/platformpower.zip --region eu-central-1

$(OUTPUT_DIR)/placements-selected-only.csv: $(OUTPUT_DIR)/track-labels.csv $(OUTPUT_DIR)/placements.csv $(OUTPUT_DIR)/panel.csv $(OUTPUT_DIR)/top_artists_placements.csv selected_placements.R
	R --vanilla < selected_placements.R
