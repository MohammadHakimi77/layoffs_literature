library(data.table)
library(cluster)

dir.create('../temp')


playlists <- fread(file = "../externals/all-playlists.csv", encoding = 'UTF-8', sep='\t', quote = "", na.strings=c('NA', 'None'),
            select = c('id', 'name','followers', 'genre'))

playlists <- unique(playlists, key=c('playlist_id'))

playlists[followers<0, followers:=0]

# select top X
setorderv(playlists, 'followers', order=-1L, na.last=T)
playlists[, followerrank:=1:.N]

# generate mood/activity tags

# mood and activity keywords
moods = c('mood', 'fuzzy', 'feel', 'rage', 'anger', 'angry', 'annoying', 'aggressive', 'interest', 'interesting', 'optimism', 'optimistic', 'ecstasy', 'joy', 'serenity', 'love', 'trust', 'acceptance', 'accepting', 'submission', 'terror', 'fear', 'awe', 'amaze', 'amazing', 'surprise', 'surprising', 'distraction', 'distracting', 'grief', 'sadness', 'sad', 'pensiveness', 'pensive', 'remorse', 'loathing', 'disgust', 'boredom', 'boring', 'bored', 'chill', 'active', 'cheerful', 'reflective', 'gloomy', 'humorous', 'humor', 'melancholy', 'romantic', 'mysterious', 'ominous', 'calm', 'lighthearted', 'hope', 'hopeful', 'fearful', 'tense', 'lonely', 'alone', 'happy', 'good', 'bad', 'suave', 'vibe', 'breakup', 'depressed', 'depression', 'emo', 'bored', 'heart[ ]broken', 'heart[-]broken')
activities = c('sing', 'drive', 'dance', 'work', 'study', 'concentrate', 'read', 'workout', 'gym', 'party', 'sport', 'relax', 'cook', 'unwind', 'driving', 'roadtrip', 'vacation', 'flying', 'fly', 'travel', 'road', 'trip', 'training', 'train', 'eat', 'kitchen', 'run', 'dream', 'activity', 'active', 'ride', 'dancing', 'listen', 'discover', 'wake[ ]up', 'wakeup', 'shower', 'ride', 'riding', 'start', 'drink', 'jogging', 'jog', 'bbq', 'gaming', 'game', 'office', 'cycling', 'camping', 'fishing', 'hunting', 'fish', 'hunt', 'karaoke', 'poker', 'playing', 'cards')


# ---------------------------- #
#       MOODS & ACTIVITIES     #
# ---------------------------- #

playlists_name = tolower(playlists$name)

# Moods
  mood_exp = paste0(paste0('(', moods, ')'), collapse='|')

  # starting with
  starts_with = grep(paste0('^(', mood_exp, ')([ ]|[!]|[.][/]|$)'), playlists_name)
  # ending with
  ends_with = grep(paste0('([ ]|[!]|[.]|[/])(', mood_exp, ')$'), playlists_name)
  # inbetween
  contains = grep(paste0('([ ]|[!]|[.]|[/])(', mood_exp, ')([ ]|[!]|[.]|[/])'), playlists_name)
  
  moodlists = playlists[union(union(starts_with, ends_with), contains)][, c('id', 'followerrank', 'followers', 'name')][, tag:='mood']

# Activities
  activity_exp = paste0(paste0('(', activities, ')'), collapse='|')
  
  # starting with
  starts_with = grep(paste0('^(', activity_exp, ')([ ]|[!]|[.][/]|$)'), playlists_name)
  # ending with
  ends_with = grep(paste0('([ ]|[!]|[.]|[/])(', activity_exp, ')$'), playlists_name)
  # inbetween
  contains = grep(paste0('([ ]|[!]|[.]|[/])(', activity_exp, ')([ ]|[!]|[.]|[/])'), playlists_name)
  
  activitylists = playlists[union(union(starts_with, ends_with), contains)][, c('id', 'followerrank', 'followers', 'name')][, tag:='activity']

  # remove albums
  activitylists <- activitylists[!grepl('album', name, ignore.case=T)]
  moodlists <- moodlists[!grepl('album', name, ignore.case=T)]
  
# separate out playlist genres/tags
split_tags = playlists[, list(tag=strsplit(genre, ',')[[1]]), by =c('id', 'followerrank','followers')]

# augment with mood and activity tags from playlist names
split_tags <- rbind(split_tags, activitylists[, colnames(split_tags),with=F],moodlists[, colnames(split_tags),with=F])

# keep unique ones
split_tags <- unique(split_tags, by=c('id', 'tag'))
split_tags[, tagid := .GRP,by=c('tag')]
split_tags[, tagrank:=1:.N,by=c('id')]
split_tags[, tagimportance:=(max(tagrank)-tagrank), by = 'id']
split_tags = split_tags[!is.na(tag)]

# Distribution of tag words
tags_summary=split_tags[, list(N=.N),by=c('tagid','tag')]
setorderv(tags_summary, 'N', order=-1L)
tags_summary[, cumN:=cumsum(N)]
tags_summary[, percentile:=cumN/sum(N)]

split_tags[, tag:=NULL]
setcolorder(split_tags, c('id','followers','followerrank'))

fwrite(split_tags, '../output/tags-playlists.csv')
fwrite(tags_summary, '../output/tags-playlists-meta.csv')


sink('../output/tags-playlists.txt')
cat('===================\n')
cat('DATASET DESCRIPTION\n')
cat('===================\n')
cat('\n')
cat('This data set lists, for each playlist in the data, up to',fill=T)
cat('six tag words and associated meta data. The data has been extracted', fill = T)
cat('from a cross-sectional data set of 1.2 million playlists, see', fill = T)
cat('playlists.csv/txt for the data and description.', fill = T)
cat('\n\n')
cat('Variable operationalization\n')
cat('===========================\n')
cat('id                          Chartmetric playlist ID', fill=T)
cat('followers                   Followers of playlist, at time of data retrieval', fill = T)
cat('followerrank                Rank of followers (rank 1 = most followers)', fill = T)
cat('tagid                       ID of tag word; look up character string in tags-playlists-meta.csv', fill = T)
cat('tagrank                     Order in which tag word appeared in original data (1 = listed first, etc.)', fill = T)
cat('tagimportance               Reverse of tagrank', fill = T)
sink()

sink('../output/tags-playlists-meta.txt')
cat('===================\n')
cat('DATASET DESCRIPTION\n')
cat('===================\n')
cat('\n')
cat('Meta data associated with the tag words described in', fill= T)
cat('tags-playlists.csv/txt.', fill=T)
cat('\n\n')
cat('Variable operationalization\n')
cat('===========================\n')
cat('tagid                       ID of tag word; look up character string in tags-playlists.csv', fill = T)
cat('tag                         Tag word (character string)', fill=T)
cat('N                           Number of times tag word occured in data (i.e., number of playlists it is associated with)', fill = T)
cat('cumN                        Cumulative sum of N to compute percentiles', fill = T)
cat('percentile                  Percentile of N (e.g., can be used to select the top X% of keywords)', fill = T)
sink()

