library(data.table)
library(stringr)
library(stringdist)
 
playlists <- fread('../../gen/data-preparation/temp/playlists.csv', encoding = 'UTF-8')
 
owners = playlists[, list(N_playlists = .N, total_followers = floor(sum(followers, na.rm=T)), 
                          mean_followers = floor(mean(followers, na.rm=T)),
                    example_links=paste0('spotify:playlist:', playlist_id[1])), by = c('user_id', 'owner_name', 'owner_class')]
 
setorderv(owners, c('total_followers'), order=-1L, na.last=T)

head(owners,50)

# Load list of composite label names and exrtact unique label names
labels <- fread('../../gen/data-preparation/temp/labels.csv', encoding = 'UTF-8')
labels=labels[, list(album_label = c(album_label, strsplit(album_label, '[/]|[ ],')[[1]])),by = c('N_tracks', 'label')]
labels[, album_label:=str_trim(album_label)]
labels <- labels[!album_label=='']

# Load list of artist names
cm_artists <- fread(file = "../../gen/data-preparation/temp/artists.csv", encoding = 'UTF-8')
# Keep only artists with more than _cutoff_ tracks
cutoff=10
cm2=cm_artists[N_tracks>cutoff][, cleaned := tolower(gsub('[ ]', '', artist_name))]
cm2[, artist_name_cleaned:=tolower(artist_name)]

#####################################################
#####################################################
#### CLASSIFICATION OF PLAYLIST OWNERSHIP TYPES #####
#####################################################
#####################################################

######################################################
#### POTENTIAL MATCHES BASED ON OFFICIAL ACCOUNTS ####
######################################################

# Retrieve list of playlists' owner names and corresponding Spotify user IDs;
# this is a table of playlists NOT curated by Spotify or any of the three major labels.
# We are interested in expanding the classification of these playlists.
potential_ids = playlists[!grepl('spotify|major', owner_class, ignore.case=T)&grepl('official$', user_id), list(N=.N), by = c('owner_name', 'user_id')]

# Clean the user IDs from tag words so that we can later on match on this column
potential_ids[, cleaned_user_id:=gsub('official$', '', user_id)]
potential_ids[, cleaned_user_id:=gsub('[_]$', '', cleaned_user_id)]
potential_ids[, cleaned_ownername:=tolower(gsub('official$', '', owner_name))]
head(potential_ids)
# the column names cleaned_user_id and cleaned_ownername can now be used for matching

#########################
# Match to artist names #
#########################

# On the basis of user IDs
setkey(potential_ids, cleaned_user_id)
setkey(cm2, cleaned)
potential_ids[cm2, artist_name:=i.artist_name]

# On the basis of owner names
setkey(potential_ids, cleaned_ownername)
setkey(cm2, artist_name_cleaned)
potential_ids[cm2, artist_name:=ifelse(is.na(artist_name), i.artist_name, artist_name)]


#########################
# Match to music labels #
#########################

labels[, cleaned:=tolower(album_label)]

# On the basis of user IDs
setkey(potential_ids, cleaned_user_id)
setkey(labels, cleaned)
potential_ids[labels[N_tracks>10], label_name:=i.album_label]

# On the basis of owner names
setkey(potential_ids, cleaned_ownername)
setkey(labels, cleaned)
potential_ids[labels[N_tracks>10], label_name:=ifelse(is.na(label_name), i.album_label, label_name)]

################
# Show matches #
################

# for artists
potential_ids[!is.na(label_name)&is.na(artist_name)]

# for artists who are (incorrectly?) also classified as labels
potential_ids[!is.na(label_name)&!is.na(artist_name)]

# Declare artists who are also classified as labels as ARTISTS
potential_ids[!is.na(artist_name), label_name:=NA]

# Show remaining unclassified labels/artists; use this list to screen for more potential artists/labels
potential_ids[is.na(artist_name)&is.na(label_name)]

#############
# Fix match #
#############

# artists
playlists[user_id%in%potential_ids[!is.na(artist_name)&is.na(label_name)]$user_id] # view
playlists[user_id%in%potential_ids[!is.na(artist_name)&is.na(label_name)]$user_id, owner_class:='artists']

# indie labels
playlists[user_id%in%potential_ids[is.na(artist_name)&!is.na(label_name)]$user_id] # view
playlists[user_id%in%potential_ids[is.na(artist_name)&!is.na(label_name)]$user_id, owner_class:='independentlabels']

# other official accounts
playlists[user_id%in%potential_ids[is.na(artist_name)&is.na(label_name)]$user_id, owner_class:='official-other']


######################################################
#### POTENTIAL MATCHES BASED ON OFFICIAL ACCOUNTS ####
######################################################

playlists[,list(.N),by=c('owner_class')]

potential_ids = playlists[owner_class=='other', list(N=.N), by = c('owner_name', 'user_id')]

potential_ids = potential_ids[!nchar(user_id)==25]
potential_ids = potential_ids[grepl('a902190', user_id)|!(grepl('^[0-9]*$', user_id)&nchar(user_id)%in%9:11)]
potential_ids = potential_ids[grepl('a902190', user_id)|!(grepl('19[0-9]{2}$', user_id))]
potential_ids = potential_ids[grepl('a902190', user_id)|!(grepl('[0-9]{2,3}$', user_id))]

#potential_ids[grepl('[0-9]{2}$', user_id)]


#########################
# Match to artist names #
#########################

# Full text artist names
setkey(potential_ids, owner_name)
setkey(cm2, artist_name)
potential_ids[cm2, artist_name:=i.artist_name]

potential_ids[!is.na(artist_name), distance:=stringdist(gsub('[ ]', '', tolower(owner_name)), gsub('|^iam|^its|band$|[-]|[.]|[_]|music$','', tolower(user_id)))]
#View(potential_ids[!is.na(artist_name)])

potential_ids[distance>3|grepl('[.]com$', user_id)|grepl('billboard|records$|entertainment', owner_name,ignore.case=T), artist_name:=NA]

###################
# Match to labels #
###################

potential_ids[, lower_case:=tolower(owner_name)]
setkey(potential_ids, lower_case)
setkey(labels, cleaned)

potential_ids[labels[N_tracks>10], label_name:=i.album_label]
potential_ids[grepl('music$', user_id, ignore.case=T)&!is.na(artist_name)&!is.na(label_name), artist_name:=NA]
potential_ids[!is.na(artist_name)&is.na(label_name), label_name:=NA]

#############
# Fix match #
#############

playlists[user_id%in%potential_ids[!is.na(artist_name)&is.na(label_name)]$user_id, owner_class:='artists']
playlists[user_id%in%potential_ids[is.na(artist_name)&!is.na(label_name)]$user_id, owner_class:='independentlabels']
playlists[owner_class=='other'&grepl('records$', user_id), owner_class:='independentlabels']

playlists[owner_class=='other'&grepl('^[0-9]*$', user_id)&nchar(user_id)%in%9:11, owner_class:='users']


playlists[owner_class=='official-other', owner_class:='other']

playlists[owner_class=='other'&grepl('records$|recrds$|recordings$', user_id, ignore.case=T), owner_class:='independentlabels']


playlists[, list(N=.N, followers=sum(followers, na.rm=T)),by=c('owner_class')]


#################################################
# Investigate classified/unclassified playlists #
#################################################

# other playlists
playlists[owner_class=='other']

tmp=playlists[owner_class=='other', list(flwr=sum(followers,na.rm=T)),by =c('owner_name', 'user_id')]
setorderv(tmp, 'flwr', order=-1L)
# top other curators
head(tmp,20)

# playlists classified as indies - are these actually indies?
tmp=playlists[owner_class=='independentlabels', list(flwr=sum(followers,na.rm=T)),by =c('owner_name', 'user_id')]
setorderv(tmp, 'flwr', order=-1L)

# Overview of followers by owner class
playlists[, list(N=.N, followers=sum(followers, na.rm=T)),by=c('owner_class')]


#################################
# Refine "other" classification #
#################################

# CLASSIFY CURATORS
playlists[, owner_class_raw := owner_class]

table(playlists$owner_class)

playlists[owner_class_raw=='other'&followers>=100, owner_class:='Professional curators']
#pls[owner_class=='users'&followers>100, owner_class_updt:='othercurators']
#playlists[grepl('major', owner_class_raw, ignore.case=T), owner_class := 'Major labels']

playlists[grepl('artists', owner_class_raw, ignore.case=T), owner_class := 'Artists']

playlists[owner_class_raw=='other'&(is.na(followers)|followers<100), owner_class:='Not classified']

playlists[owner_class_raw=='artists', owner_class := 'Artists']
playlists[owner_class_raw=='independentlabels', owner_class := 'Independent labels']
playlists[owner_class_raw=='users', owner_class := 'Users']


# Overview of followers by owner class
print(playlists[, list(N=.N, total_followers=sum(followers, na.rm=T), avg_followers=mean(followers,na.rm=T)),by=c('owner_class')])



###########################################
###########################################
#### CLASSIFICATION OF PLAYLIST TYPES #####
###########################################
###########################################

#check availablity:
#create variable:
playlists[, playlist_type_mood := 0]
playlists[grepl('mood|fuzzy|feel|rage|anger|annoyance|angry|annoying|aggresive|vigilance|anticipitation|anticipating|interest|interesting|optimism|optimistic|ecstasy|joy|serenity|love|admiration|trust|acceptance|accepting|submission|terror|fear|apprehension|awe|amazement|amaze|amazing|surprise|surprising|distraction|distracting|disapproval|disaproving|disaprove|grief|sadness|sad|pensiveness|pensive|remorse|loathing|loath|disgust|boredom|boring|bored|contempt|chill|active|cheerful|reflective|gloomy|humorous|humor|melancholy|idyllic|romantic|mysterious|ominous|calm|lighthearted|hope|hopeful|fearful|tense|lonely|alone|happy|good|bad|suave|vibe|breakup|depressed|depression|emo|bored|heart broken', name, ignore.case=T), playlist_type_mood:=1]

#TYPE: activity ---------------------------------------------------------------
playlists[, playlist_type_activity := 0]

#check availability 
playlists[grepl('sing|drive|dance|work|study|concentrate|read|workout|gym|party|sport|relax|cook|unwind|driving|roadtrip|vacation|flying|fly|sleep|travel|road|trip|training|train|eat|kitchen|run|dream|activity|active|ride|dancing|listen|discover|wake|up|wakeup|shower|riding|start|drink|jogging|jog|bbq|gaming|game|office|cycling|camping|fishing|hunting|fish|hunt|karaoke|poker|playing|cards',tolower(name))]

#create variable
playlists[grepl('sing|drive|dance|work|study|concentrate|read|workout|gym|party|sport|relax|cook|unwind|driving|roadtrip|vacation|flying|fly|sleep|travel|road|trip|training|train|eat|kitchen|run|dream|activity|active|ride|dancing|listen|discover|wake|up|wakeup|shower|riding|start|drink|jogging|jog|bbq|gaming|game|office|cycling|camping|fishing|hunting|fish|hunt|karaoke|poker|playing|cards', name, ignore.case = T), playlist_type_activity:=1]

playlists[, playlist_type_genre:=0]
playlists[playlist_type_activity==0&playlist_type_mood==0, playlist_type_genre:=1]


playlists[, list(.N),by=c('playlist_type_activity', 'playlist_type_mood', 'playlist_type_genre')]


# Export classifications
export = playlists[, c('playlist_id', 'owner_class', grep('[_]type', colnames(playlists),value=T)),with=F]

# update types
pls <- fread('../../gen/data-preparation/temp/playlists.csv')

setkey(export, playlist_id)
setkey(pls, playlist_id)

for (.var in setdiff(colnames(export), 'playlist_id')) {
  pls[export, paste0(.var):=get(paste0('i.', .var))]
}

dir.create('../../gen/data-preparation/output/')
fwrite(pls, '../../gen/data-preparation/output/playlists.csv')
