library(data.table)
library(stringr)
library(stringdist)
devtools::install_github("hannesdatta/musicMetadata")
library(musicMetadata)


dir.create('../output')

playlists <- fread(file = "../externals/all-playlists.csv", encoding = 'UTF-8', sep='\t', quote = "", na.strings=c('NA', 'None'),
             colClasses = c(code2 = 'factor', owner_name='factor'), drop = 'last_updated')
setorder(playlists, position)
playlists <- unique(playlists, key=c('playlist_id'))

playlists[followers<0, followers:=0]

playlists[is.na(code2), code2:='global']

setnames(playlists, 'code2', 'location')
setnames(playlists, 'catalog', 'contenttype')

cols <- grep('^fdiff', colnames(playlists),value=T)
for (col in cols) playlists[, (col):=NULL]

playlists[, owner_class:=as.factor('other')]
playlists[editorial==T|grepl('^thesoundsofspotify$|^spotify[_]flashback$', owner_id), owner_class:='Spotify']
playlists[owner_name%like%'^Spotify' & user_id%like% '^spotify[a-z]|^spotify[_]', owner_class := 'Spotify']

playlists[,editorial:=NULL]
playlists[grepl('^filtr', owner_name, ignore.case=T)|grepl('filtr', user_id, ignore.case=T), owner_class:='Major label (Sony)']
playlists[grepl('^digster', owner_name, ignore.case=T)|grepl('digster', user_id, ignore.case=T), owner_class:='Major label (Universal)']
playlists[grepl('^topsify', owner_name, ignore.case=T)|grepl('topsify', user_id, ignore.case=T), owner_class:='Major label (Warner)']

# Identify major labels by owner names
owners = playlists[,list(.N),by=c('owner_name')]
lbls <- classify_labels(owners$owner_name, concatenated =T)
owners=owners[, label_classification := lbls]
mlowners = owners[label_classification!=''&N>1]
setorder(mlowners, N)

mlowners[grepl('sony',label_classification, ignore.case=T), owner_label:= 'Major label (Sony)']
mlowners[grepl('universal',label_classification, ignore.case=T), owner_label:= 'Major label (Universal)']
mlowners[grepl('warner',label_classification, ignore.case=T), owner_label:= 'Major label (Warner)']

setkey(mlowners, owner_name)
setkey(playlists, owner_name)

playlists[mlowners, owner_class:=i.owner_label]

##############################################################################
# Identify remaining playlists: artists vs labels vs. prof curators vs users #
##############################################################################

owners = playlists[, list(N_playlists = .N, 
                          total_followers = floor(sum(followers, na.rm=T)), 
                          mean_followers = floor(mean(followers, na.rm=T)),
                          max_followers = floor(max(followers, na.rm=T)),
                          min_followers = floor(min(followers, na.rm=T)),
                          example_links=paste0('spotify:playlist:', playlist_id[1])), by = c('user_id', 'owner_name', 'owner_class')]

setorderv(owners, c('max_followers'), order=-1L, na.last=T)

head(owners,50)

# Load list of composite label names and exrtact unique label names
labels <- fread('../output/labels.csv', encoding = 'UTF-8')
labels=labels[, list(album_label = c(album_label, strsplit(album_label, '[/]|[ ],')[[1]])),by = c('N_tracks', 'label')]
labels[, album_label:=str_trim(album_label)]
labels <- labels[!album_label=='']

# Load list of artist names
cm_artists <- fread(file = "../output/artists.csv", encoding = 'UTF-8')

# Keep only artists with more than _cutoff_ tracks
cutoff=10
cm2=cm_artists[N_tracks>cutoff]

#####################################################
#####################################################
#### CLASSIFICATION OF PLAYLIST OWNERSHIP TYPES #####
#####################################################
#####################################################

######################################################
#### POTENTIAL MATCHES BASED ON OFFICIAL ACCOUNTS ####
######################################################


text_clean <- function(x) {
  x=tolower(gsub('official$', '', x))
  x=gsub('[.]com$','',x)
  x=gsub("[^A-Za-z0-9]","",x)
  #x=gsub('[_]$|[ ]|[-]|[_]|[.]|[,]|[#]', '', x)
  x
}

potential_ids = playlists[!grepl('spotify|major', owner_class, ignore.case=T), 
                          list(N=.N), by = c('owner_name', 'user_id')]


potential_ids[, cleaned_user_id:=text_clean(user_id)]
potential_ids[, cleaned_ownername:=text_clean(owner_name)]

head(potential_ids)
# the column names cleaned_user_id and cleaned_ownername can now be used for matching

#########################
# Match to artist names #
#########################

cm2[, artist_name_cleaned := text_clean(artist_name)]
cm2<-cm2[!is.na(artist_name_cleaned)|artist_name_cleaned=='']

# On the basis of user IDs
for (k in c('cleaned_user_id','cleaned_ownername')) {
  setkeyv(potential_ids, k)
  setkey(cm2, artist_name_cleaned)
  potential_ids[cm2, artist_name:=i.artist_name]
}
potential_ids[!is.na(artist_name)]

# On the basis of owner names
setkey(potential_ids, cleaned_ownername)
setkey(cm2, artist_name_cleaned)
potential_ids[cm2, artist_name:=ifelse(is.na(artist_name), i.artist_name, artist_name)]

#########################
# Match to music labels #
#########################

labels[, cleaned_album_label:=text_clean(album_label)]
labels <- labels[!is.na(cleaned_album_label)|album_label=='']

for (k in c('cleaned_user_id','cleaned_ownername')) {
  setkeyv(potential_ids, k)
  setkey(labels, cleaned_album_label)
  potential_ids[labels[N_tracks>10], label_name:=i.album_label]
}
potential_ids[!is.na(label_name)]


################
# Show matches #
################

# for labels, which are never classified as an artist
potential_ids[!is.na(label_name)&is.na(artist_name)]

# for artists who are also classified as labels
potential_ids[!is.na(label_name)&!is.na(artist_name)]

# Declare artists who are also classified as labels as ARTISTS
potential_ids[!is.na(artist_name), label_name:=NA]

# Show remaining unclassified labels/artists; use this list to screen for more potential artists/labels
#View(potential_ids[is.na(artist_name)&is.na(label_name)])


#############
# Fix match #
#############

# artists
playlists[user_id%in%potential_ids[!is.na(artist_name)&is.na(label_name)]$user_id, owner_class:='Artists']

# indie labels
playlists[user_id%in%potential_ids[is.na(artist_name)&!is.na(label_name)]$user_id, owner_class:='Independent labels']

# professional curators
prof_curators = owners[total_followers>50000&user_id%in%potential_ids$user_id]

playlists[user_id%in% prof_curators$user_id&owner_class=='other', owner_class := 'Professional curators']


# users
selected_users = owners[total_followers<1000&user_id%in%potential_ids$user_id]

playlists[user_id%in% selected_users$user_id&owner_class=='other', owner_class := 'Users']

#potential_ids[distance>3|grepl('[.]com$', user_id)|grepl('billboard|records$|entertainment', owner_name,ignore.case=T), artist_name:=NA]
#playlists[owner_class=='other'&grepl('records$', user_id), owner_class:='independentlabels']
#playlists[owner_class=='other'&grepl('records$|recrds$|recordings$', user_id, ignore.case=T), owner_class:='independentlabels']


# Overview of followers by owner class
print(playlists[, list(N=.N, total_followers=sum(followers, na.rm=T), avg_followers=mean(followers,na.rm=T)),by=c('owner_class')])

#############################
# ACTIVITY & MOOD PLAYLISTS #
#############################

moods <- c('mood', 'fuzzy', 'feel', 'rage', 'anger', 'annoyance', 'angry', 'annoying', 'aggresive', 'vigilance', 'anticipitation', 'anticipating', 'interest', 'interesting', 'optimism', 'optimistic', 'ecstasy', 'joy', 'serenity', 'love', 'admiration', 'trust', 'acceptance', 'accepting', 'submission', 'terror', 'fear', 'apprehension', 'awe', 'amazement', 'amaze', 'amazing', 'surprise', 'surprising', 'distraction', 'distracting', 'disapproval', 'disaproving', 'disaprove', 'grief', 'sadness', 'sad', 'pensiveness', 'pensive', 'remorse', 'loathing', 'loath', 'disgust', 'boredom', 'boring', 'bored', 'contempt', 'chill', 'active', 'cheerful', 'reflective', 'gloomy', 'humorous', 'humor', 'melancholy', 'idyllic', 'romantic', 'mysterious', 'ominous', 'calm', 'lighthearted', 'hope', 'hopeful', 'fearful', 'tense', 'lonely', 'alone', 'happy', 'good', 'bad', 'suave', 'vibe', 'breakup', 'depressed', 'depression', 'emo', 'bored', 'heart broken')
activities <- c('sing', 'drive', 'dance', 'work', 'study', 'concentrate', 'read', 'workout', 'gym', 'party', 'sport', 'relax', 'cook', 'unwind', 'driving', 'roadtrip', 'vacation', 'flying', 'fly', 'sleep', 'travel', 'road', 'trip', 'training', 'train', 'eat', 'kitchen', 'run', 'dream', 'activity', 'active', 'ride', 'dancing', 'listen', 'discover', 'wake', 'up', 'wakeup', 'shower', 'riding', 'start', 'drink', 'jogging', 'jog', 'bbq', 'gaming', 'game', 'office', 'cycling', 'camping', 'fishing', 'hunting', 'fish', 'hunt', 'karaoke', 'poker', 'playing', 'cards')


playlists[, playlist_type_mood := 0]
playlists[grepl(paste0(paste0(moods,'$'),collapse='|'), name, ignore.case=T), playlist_type_mood:=1]
playlists[grepl(paste0(paste0(moods,'[ ]'),collapse='|'), name, ignore.case=T), playlist_type_mood:=1]

playlists[, playlist_type_activity := 0]
playlists[grepl(paste0(paste0(activities,'$'),collapse='|'), name, ignore.case=T), playlist_type_activity:=1]
playlists[grepl(paste0(paste0(activities,'[ ]'),collapse='|'), name, ignore.case=T), playlist_type_activity:=1]



################################################################
# Classify playlists to serve Spotify recommendations          #
################################################################

personalized_playlists <- c('Discover Weekly' = '^discover[ ]weekly$',
                            'Release Radar' = '^release[ ]radar$',
                            'Repeat Rewind' = '^repeat[ ]rewind$',
                            'On Repeat' = '^On[ ]Repeat$',
                            'Tastebreakers' = '^Tastebreakers$',
                            'The Ones That Got Away' = 'the[ ]ones[ ]that[ ]got[ ]away',
                            'Your Summer Rewind' = '^your[ ]summer[ ]rewind$',
                            'Your Daily Drive' = '^your[ ]daily[ ]drive$',
                            'Your Top Songs By Year' = '^your[ ]top[ ]songs[ ]20[0-9][0-9]$',
                            'Your Time Capsule' = '^your[ ]time[ ]capsule$',
                            'Your Daily Mix' = 'daily[ ]mix[ ][1-9]',
                            'Dein Mix der Woche' = '^Dein[ ]Mix[ ]der[ ]Woche$',
                            'Your Jams' = '^Your[ ]20[0-9][0-9][ ]Jams$',
                            'Descubrimiento semanal' = '^Descubrimiento[ ]semanal$',
                            'Decouvertes de la semaine' = 'couvertes[ ]de[ ]la[ ]semaine$',
                            'Family Mix' = '^Family[ ]Mix$') 


#Non-personalized
one_query = paste0(personalized_playlists, collapse='|')
playlists[, recommendation_type := 'Not personalized by Spotify']

#Fully-personalized recommendations
playlists[grepl(one_query, name, ignore.case=T) & owner_name == 'Spotify', recommendation_type:= 'Fully-personalized recommendations']
playlists[recommendation_type == 'Fully-personalized recommendations' & personalized == T] # why personalized==T?

#Semi-personalized recommendations
playlists[!recommendation_type == 'Fully-personalized recommendations' & owner_name == 'Spotify' & personalized == T, recommendation_type:= 'Semi-personalized recommendations']

#Artists-specific recommendations (take out: ^This[ ]is[ ] playlists)
playlists[owner_name == 'Spotify' & grepl('[ ]Radio$', name, ignore.case=T), recommendation_type := 'Artist-specific recommmendations']

#Distribution of recommendations
playlists[, list(.N),by=c('recommendation_type')]

####################################################
# SELECTION FOR SUBSEQUENT DATA PREPARATION STAGES #
####################################################

setorderv(playlists, c('followers'), order = c(-1L), na.last=T)

playlists[, follower_percentile:=cumsum(as.numeric(ifelse(is.na(followers),0,followers)))/sum(followers,na.rm=T)]

tmp2=playlists[, list(top100 = sum(followers[1:100])/sum(followers,na.rm=T),
                      top1000 = sum(followers[1:1000])/sum(followers, na.rm=T),
                      N=.N,
                      N80p = length(which(follower_percentile<=.8)),
                      N90p = length(which(follower_percentile<=.9)),
                      N95p = length(which(follower_percentile<=.95))
)]


playlists[, personalized:=NULL] # remove confusing personalization indicator; have our own classification now
fwrite(playlists, '../output/playlists.csv')
