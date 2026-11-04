# Document all data sets for analysis
# + remove unnecessary columns
library(data.table)
library(rmarkdown)

dir.create('../export/')
unlink('../export/*')

playlists <- fread('../output/playlists.csv')
promotions <- fread('../externals/promotions.csv')
panel <- fread('../output/panel.csv')
playlist_categories <- fread('../output/playlist-categories.csv')
topartists <- fread('../output/top_artists.csv')
topartists_placements <- fread('../output/top_artists_placements.csv')
placements_selected <- fread('../output/placements-selected-only.csv')

# Meta data for playlist data
meta_playlists <- list(filename = 'playlists.csv',
                       description = 'Cross-sectional data set, containing meta data on all 1.2m playlists retrieved via the Chartmetric API (endpoint: playlist-playlist list) in April 2020.',
                       drop = c('owner_id','user_id', 'owner_name'),
                       variables = list('retrieval_unix' = 'Unix timestamp of data retrieval via the Chartmetric API',
                                        'position' = 'Rank (in descending order of no. of followers, at data retrieval)',
                                        'id' = 'Chartmetric playlist ID',
                                        'location' = 'Locale of playlist (only available for playlists made by Spotify',
                                        'playlist_id' = 'Spotify playlist ID (can be used to match to playlist IDs from Spotify)',
                                        'name' = 'Name of the playlist',
                                        'followers' = 'Number of followers of playlist at data retrieval',
                                        'owner_id' = 'Chartmetric ID of owner of the playlist',
                                        'owner_name' = 'Name of the owner of the playlist',
                                        'user_id' = 'Spotify user ID of playlist owner',
                                        
                                        #'from_spotify' = 'Indicator variable, True if playlist is owned by Spotify, False otherwise',
                                        'genre' = 'Genre of playlist, as supplied via the API from Chartmetric (collection of comma-separated tag words)',
                                        'monthly_listeners' = 'Monthly listeners on the playlist (1 April 2020)',
                                        'listeners_to_followers_ratio' = 'Number of listeners divided by number of followers (1 April 2020)',
                                        
                                        'contenttype' = 'Type of content: If +75% is new (younger than 18 months) -->  frontline, if 25%-75% new --> mixed, if less than 25% new ---> catalogue',
                                        'active_ratio' = 'curation intensity of playlist, 1 if all songs within 28 days have been changed; 0 if no change.',
                                        
                                        'owner_class' = 'Playlist owner, classified as Spotify, one of the major labels, independent labels, artists, professional curators (for exact operationalization, see paper)',
                                        
                                        'playlist_type_mood' = 'Indicator variable, whether a mood keyword (e.g., sad, happy) occurs in the name of the playlist (1), or not (0)',
                                        'playlist_type_activity' = 'Indicator variable, whether an activity keyword (e.g., workout, chill) occurs in the name of the playlist (1), or not (0)',

                                        'recommendation_type' = 'Categorical variable, indicating whether playlist is personalized, and if so, at which level.')
                       )
                        
meta_panel <- list(filename = 'panel.csv',
                   description = 'Daily panel data set of 39,600 playlists selected based on procedure documented in paper; data spans 2019/10/29 until 2020-04-05.',
                   drop = NULL,
                   variables = list("id" = "Chartmetric playlist ID",
                                    "playlist_id" = "Spotify playlist ID",
                                    "date"="Date (YYYY-MM-DD)",
                                    "cat_id" = "Category ID, created based on unique values of column `category`",
                                    "category" = "Category, as per dynamic categorization in paper",
                                    "followers" = "Number of daily playlist followers",
                                    "listeners" = "Number of daily playlist listeners",
                                    "followers_interpolated" = "Indicator variable, if daily playlist followers were interpolated (for procedure, see paper)",
                                    "listeners_interpolated" = "Indicator variable, if daily playlist listeners were interpolated (for procedure, see paper)",
                                    "playlist_name" = "Name of playlist",
                                    "playlist_followers_static" = "Number of playlist followers, as per cross-sectional data collection in `playlists.csv`",
                                    "playlist_follower_rank" = "Rank in descending order, based on `playlist_followers_static`",
                                    "ml_curr" = "Share of major-label content available on playlist",
                                    "sony_curr" = "Share of Sony-owned content available on playlist",
                                    "universal_curr" = "Share of Universal-owned content available on playlist", 
                                    "warner_curr" = "Share of Warner-owned content available on playlist",
                                    "ntracks" = "Number of tracks available on a playlist",
                                    "nadded" = "Number of tracks newly added to a playlist",
                                    "nremoved" = "Number of tracks removed from a playlist",
                                    "ntracksotherpl" = "Average number of playlists that tracks available on focal playlist are listed on; popularity metric for tracks currently available on the focal playlist",
                                    
                                    "trackage" = "Average time since release of tracks available on a list (in days)",
                                    "tracklength_sec" = "Average track length of tracks available on a list, in seconds",
                                    "ac_danceability" = "Average acoustic attribute of tracks available on a list: danceability",
                                    "ac_energy" = "Average acoustic attribute of tracks available on a list: energy",
                                    "ac_speechiness" = "Average acoustic attribute of tracks available on a list: speechiness",
                                    "ac_acousticness" = "Average acoustic attribute of tracks available on a list: acousticness",
                                    "ac_instrumentalness" = "Average acoustic attribute of tracks available on a list: instrumentalness",
                                    "ac_liveness" = "Average acoustic attribute of tracks available on a list: liveness",
                                    "ac_valence" = "Average acoustic attribute of tracks available on a list: valence",
                                    "ac_tempo" = "Average acoustic attribute of tracks available on a list: tempo (in BPM)",
                                    "ac_loudness" = "Average acoustic attribute of tracks available on a list: loudness",
                                    
                                    "wnplaylists_ml_curr" = "Weighted average (see paper) of major-label content available on a playlist",
                                    "wnplaylists_sony_curr" = "Weighted average (see paper) of Sony-owned content available on a playlist",
                                    "wnplaylists_universal_curr" = "Weighted average (see paper) of Universal-owned content available on a playlist",
                                    "wnplaylists_warner_curr" = "Weighted average (see paper) of Warner-owned content available on a playlist",
                                    "wnplaylists_trackage" = "Weighted average (see paper) of time since release of tracks available on a list (in days)",
                                    "wnplaylists_tracklength_sec" = "Weighted average (see paper) of track length of tracks available on a list, in seconds",
                                    "wnplaylists_ac_danceability" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: danceability",
                                    "wnplaylists_ac_energy" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: energy",
                                    "wnplaylists_ac_speechiness" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: speechiness",
                                    "wnplaylists_ac_acousticness" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: acousticness",
                                    "wnplaylists_ac_instrumentalness" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: instrumentalness",
                                    "wnplaylists_ac_liveness" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: liveness",
                                    "wnplaylists_ac_valence" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: valence",
                                    "wnplaylists_ac_tempo" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: tempo (in BPM)",
                                    "wnplaylists_ac_loudness" = "Weighted average (see paper) of acoustic attribute of tracks available on a list: loudness",
                                    
                                    "recartist_ntracks" = "Number of tracks available on artist-focused (\"This is...\") playlists",
                                    "recartist_nplaylists" = "Number of artist-focused (\"This is...\") playlists tracked",
                                    "recartist_nadded" = "Number of tracks added to artist-focused (\"This is...\") playlists",
                                    "recfully_ntracks" = "Number of tracks available on fully personalized playlists (e.g., Discover Weekly)",
                                    "recfully_nplaylists" = "Number of fully personalized playlists tracked (e.g., Discover Weekly)",
                                    "recfully_nadded" = "Number of tracks added to fully personalized playlists (e.g., Discover Weekly)",
                                    "recsemi_ntracks" = "Number of tracks available on semi-personalized playlists (e.g., Songs to Sing in a Shower)",
                                    "recsemi_nplaylists" = "Number of semi-personalized playlists tracked (e.g., Songs to Sing in a Shower)",
                                    "recsemi_nadded" = "Number of tracks added to semi-personalized playlists (e.g., Songs to Sing in a Shower)",
                                    
                                    "recartist_ntracks_cat" = "Number of tracks available on artist-focused (\"This is...\") playlists in the same category as focal playlist",
                                    "recartist_nplaylists_cat" = "Number of artist-focused (\"This is...\") playlists tracked in the same category as focal playlist",
                                    "recartist_nadded_cat" = "Number of tracks added to artist-focused (\"This is...\") playlists in the same category as focal playlist",
                                    "recfully_ntracks_cat" = "Number of tracks available on fully personalized playlists (e.g., Discover Weekly) in the same category as focal playlist",
                                    "recfully_nplaylists_cat" = "Number of fully personalized playlists tracked (e.g., Discover Weekly) in the same category as focal playlist",
                                    "recfully_nadded_cat" = "Number of tracks added to fully personalized playlists (e.g., Discover Weekly) in the same category as focal playlist",
                                    "recsemi_ntracks_cat" = "Number of tracks available on semi-personalized playlists (e.g., Songs to Sing in a Shower) in the same category as focal playlist",
                                    "recsemi_nplaylists_cat" = "Number of semi-personalized playlists tracked (e.g., Songs to Sing in a Shower) in the same category as focal playlist",
                                    "recsemi_nadded_cat" = "Number of tracks added to semi-personalized playlists (e.g., Songs to Sing in a Shower) in the same category as focal playlist")
                   
                                    )


# Meta data for promotions data
meta_promotions <- list(filename = 'promotions.csv',
                       description = 'Playlist promotions, as observed via everynoise.com and described in paper; by country, section, and day between 2019/10/29 and 2021/03/10.',
                       drop = NULL,
                       variables = list('date' = 'Date (YYYY-MM-DD)',
                                        'sectionName' = 'section in Spotify\'s search section on the browse page',
                                        'countryCode' = '2-letter country code',
                                        'continent' = '2-letter continent code',
                                        'playlist_id' = 'Spotify playlist ID (can be used to match to playlist IDs from Spotify)',
                                        'position' = 'Average observed position in the section, averaged from raw data that captured playlist positions per section/country/continent/day in three-hour intervals'))

# Meta data for categories
meta_topartists <- list(filename = 'top_artists.csv',
                        description = 'List of "superstar" artists, identified by procedure described in paper (in particular with regard to periods on which the US Billboard and Spotify Top 10 charts were observed.',
                        drop = c('sony3','warner3','universal3','sonysh','warnersh','universalsh','sonybyshare','warnerbyshare','universalbyshare','ml3','mlbyshare', 'billboard_old'),
                        variables = list('artist' = 'Artist name (lower caps)',
                                         'artist_name' = 'Artist name (title capitalization)',
                                         'top_id' = 'Artist ID (internal, can only be used to identify unique artists in this dataset)',
                                         'cm_artist' = 'Chartmetric artist IDs; one artist/top_id can link to multiple Chartmetric IDs',
                                         'billboard' = 'Indicator variable, set to TRUE if artist was ever listed on US Billboard Charts',
                                         'spotify_top10' = 'Indicator variable, set to TRUE if ever listed on Spotify Top 10',
                                         'sony' = 'Label membership: Sony (multiple labels can be linked, e.g., if artist has released on multiple labels in the past)',
                                         'warner' = 'Label membership: Warner (multiple labels can be linked, e.g., if artist has released on multiple labels in the past)',
                                         'universal' = 'Label membership: Universal (multiple labels can be linked, e.g., if artist has released on multiple labels in the past)')
                        )
                        
# Meta data for categories
meta_topartistsplacement <- list(filename = 'top_artists_placements.csv',
                        description = 'Availability of "superstar" artists (see top_artists.csv) on any of the tracked playlists by Chartmetric in the study\'s observation period.',
                        drop = NULL, 
                        variables = list('id' = 'Chartmetric playlist ID',
                                         'track_id' = 'Chartmetric track ID',
                                         'cm_artist' = 'Chartmetric artist ID',
                                         'added_at' = 'Date on which track was added',
                                         'removed_at' = 'Date on which track was removed, NA if not removed during observation period',
                                         'spell' = 'Counter variable, counting the "spell" on which a track was added (e.g., a track can be added and removed multiple times from the same playlist)',
                                         'days_on_list' = 'Number of days track was observed on lst; when removed at is NA, "final day" is end of observation period on 1 April 2020.',
                                         'spotify_duration_ms' = 'Track duration in milliseconds',
                                         'spotify_popularity' = 'Track popularity proxy by Spotify',
                                         'album_label' = 'Name of releasing label of associated album',
                                         'release_dates' = 'Release date of track',
                                         'danceability' = 'Spotify acoustic attribute of track: danceability',
                                         'energy' = 'Spotify acoustic attribute of track: energy',
                                         'speechiness' = 'Spotify acoustic attribute of track: speechiness',
                                         'acousticness' = 'Spotify acoustic attribute of track: acousticness',
                                         'instrumentalness' = 'Spotify acoustic attribute of track: instrumentalness',
                                         'liveness' = 'Spotify acoustic attribute of track: liveness',
                                         'tempo' = 'Spotify acoustic attribute of track: tempo',
                                         'loudness' = 'Spotify acoustic attribute of track: loudness')
)

meta_placementsselected <- list(filename = 'placements-selected-only.csv',
                                 description = 'Availability of any track on any of the selected playlists for the main analysis during the study\'s observation period.',
                                 drop = NULL,
                                 variables = list('id' = 'Chartmetric playlist ID',
                                                  'name' = 'Playlist name',
                                                  'track_id' = 'Chartmetric track ID',
                                                  'cm_artist' = 'Chartmetric artist ID',
                                                  'added_at' = 'Date on which track was added',
                                                  'removed_at' = 'Date on which track was removed, NA if not removed during observation period',
                                                  
                                                  'artist_names' = 'Name of the artist(s)',
                                                  'album_label' = 'Label associated with the album/track release',
                                                  'release_dates' = 'Release date of track/album',
                                                  
                                                  'sony' = 'Indicator variable, TRUE if release is classified to be related to Sony',
                                                  'universal' = 'Indicator variable, TRUE if release is classified to be related to Universal',
                                                  'warner' = 'Indicator variable, TRUE if release is classified to be related to Warner',
                                                  
                                                  'spotify_duration_ms' = 'Track duration in milliseconds',
                                                  'spotify_popularity' = 'Track popularity proxy by Spotify',
                                                  
                                                  'danceability' = 'Spotify acoustic attribute of track: danceability',
                                                  'energy' = 'Spotify acoustic attribute of track: energy',
                                                  'speechiness' = 'Spotify acoustic attribute of track: speechiness',
                                                  'acousticness' = 'Spotify acoustic attribute of track: acousticness',
                                                  'instrumentalness' = 'Spotify acoustic attribute of track: instrumentalness',
                                                  'liveness' = 'Spotify acoustic attribute of track: liveness',
                                                  'tempo' = 'Spotify acoustic attribute of track: tempo',
                                                  'loudness' = 'Spotify acoustic attribute of track: loudness',
                                                  'key' = 'Spotify acoustic attribute of track: key',
                                                  'mode' = 'Spotify acoustic attribute of track: mode')
)

# Meta data for categories
meta_categories <- list(filename = 'playlist-categories.csv',
                        description = 'Weekly playlist categorization for 147,751 playlists between 2019/09/30 and 2020/04/05, as per procedure described in paper.',
                        drop = NULL,
                        variables = list('id' = 'Chartmetric playlist ID',
                                         'begin_init' = 'Beginning date for week',
                                         'end_init' = 'Ending date for week',
                                         'category' = 'Category, as identified via procedure described in paper; categories can contain a combination of multiple keywords that are separated by commas',
                                         'changed' = 'Indicator variable, set to 1 if category change from one week to another was observed',
                                         'playlist_followers' = '(Static) number of playlist followers',
                                         'name' = 'Playlist name',
                                         'cat_id' = 'Numeric category value, corresponding to "category"')
)



# playlist data
meta <- copy(meta_playlists)
dt <- copy(playlists)
setcolorder(dt, names(meta$variables))
for (.var in meta$drop) dt[, (.var):=NULL]
fwrite(dt, '../export/playlists.csv')
rmarkdown::render(input = 'document.Rmd',output_dir = '../export/', output_format = 'pdf_document', output_file = 'playlists.pdf')


# promotions
meta <- meta_promotions
dt <- promotions
setcolorder(dt, names(meta$variables))
for (.var in meta$drop) dt[, (.var):=NULL]
fwrite(dt, '../export/promotions.csv')
rmarkdown::render(input = 'document.Rmd',output_dir = '../export/', output_format = 'pdf_document', output_file = 'promotions.pdf')

# playlist categories
meta <- meta_categories
dt <- playlist_categories
setcolorder(dt, names(meta$variables))
for (.var in meta$drop) dt[, (.var):=NULL]
fwrite(dt, '../export/playlist-categories.csv')
rmarkdown::render(input = 'document.Rmd',output_dir = '../export/', output_format = 'pdf_document', output_file = 'playlist-categories.pdf')

# top artists
meta <- meta_topartists
dt <- topartists
for (.var in meta$drop) dt[, (.var):=NULL]
setcolorder(dt, names(meta$variables))
fwrite(dt, '../export/top_artists.csv')
rmarkdown::render(input = 'document.Rmd',output_dir = '../export/', output_format = 'pdf_document', output_file = 'top_artists.pdf')


# top artists placements
meta <- meta_topartistsplacement
dt <- topartists_placements
for (.var in meta$drop) dt[, (.var):=NULL]
setcolorder(dt, names(meta$variables))
fwrite(dt, '../export/top_artists_placements.csv')
rmarkdown::render(input = 'document.Rmd',output_dir = '../export/', output_format = 'pdf_document', output_file = 'top_artists_placements.pdf')

# all track placements for selected playlists
meta <- meta_placementsselected
dt <- placements_selected
for (.var in meta$drop) dt[, (.var):=NULL]
setcolorder(dt, names(meta$variables))
fwrite(dt, '../export/placements-selected-only.csv')
rmarkdown::render(input = 'document.Rmd',output_dir = '../export/', output_format = 'pdf_document', output_file = 'placements-selected-only.pdf')

# panel
.excl = grep('ntracksotherpl[0-9]|ntracksotherpl[_]|ml_top[0-9]|top[0-9]{2}share$|^wfollowers[_]|fans[-]|ntracks.*curr$|^relcum|relfocal',colnames(panel),value=T)
for (.var in .excl) panel[, (.var):=NULL]
setcolorder(panel, c('id','playlist_id','date','cat_id','category','followers','listeners','followers_interpolated','listeners_interpolated'))
colnames(panel)
fwrite(panel, '../export/panel.csv')

# all track placements for selected playlists
meta <- meta_panel
dt <- panel
setcolorder(dt, names(meta$variables))
fwrite(dt, '../export/panel.csv')
rmarkdown::render(input = 'document.Rmd',output_dir = '../export/', output_format = 'pdf_document', output_file = 'panel.pdf')

