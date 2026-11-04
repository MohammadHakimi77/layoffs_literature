# Overview with content on playlists

library(data.table)
source('use_tablefill.R')
source('proc_aux.R')

out_path = '../output/figures_and_tables/'
dir.create(out_path, recursive=T)

place_filtered <- fread('../../analysis/temp/placements-selected-only.csv')

top_artists <- fread('../../analysis/temp/top_artists_placements.csv')
top_artists_meta <- fread('../../analysis/temp/top_artists.csv')

incl_artists <- fread('../../analysis/temp/treated_ml.csv')[universal==T|sony==T|warner==T]

unique(incl_artists$artist_name)

setkey(top_artists, cm_artist)
setkey(top_artists_meta, cm_artist)
top_artists[top_artists_meta, ':=' (sony=i.sony,warner=i.warner,universal=i.universal)]

playlists <- fread('../../analysis/temp/playlists.csv')

place_filtered[, censored_added_at:=ifelse(added_at<='2019-11-01', as.Date('2019-11-01'), as.Date(added_at))]
place_filtered[, censored_removed_at:=ifelse(is.na(removed_at), as.Date('2020-04-01'), as.Date(removed_at))]
place_filtered[, censored_added_at:=as.Date(censored_added_at)]
place_filtered[, censored_removed_at:=as.Date(censored_removed_at)]

#place_filtered[, time_on_list:=as.numeric(difftime(censored_removed_at,added_at, units='days'))]
place_filtered[, time_on_list:=as.numeric(difftime(censored_removed_at,censored_added_at, units='days'))]

setkey(place_filtered,id)
setkey(playlists, id)

place_filtered[playlists, followers:=i.followers]
place_filtered[playlists, owner_class:=i.owner_class]

place_filtered[, num_added_at:=as.numeric(added_at)]
place_filtered[, num_release_dates:=as.numeric(release_dates)]
place_filtered[, age:=num_added_at-num_release_dates]

place_filtered[, isnotremoved:=is.na(removed_at)|removed_at>as.Date('2020-04-01')]
place_filtered[, isspotify:=grepl('spotify', owner_class,ignore.case =T)]
place_filtered[, isml:=grepl('major', owner_class,ignore.case =T)]



placements_by_track_id=place_filtered[, list(not_removed=isnotremoved[1],
                                             time_on_list=mean(time_on_list,na.rm=T),
                                             is_spotify=isspotify[1],
                                             is_ml=isml[1],
                                             age=mean(age,na.rm=T),
                                             spotpop = mean(spotify_popularity,na.rm=T),
                                             sony=sony[1],
                                             warner=warner[1],
                                             universal=universal[1],
                                             followers=mean(followers,na.rm=T)), by=c('id','track_id')]

setkey(placements_by_track_id, track_id, id)
placements_by_track = placements_by_track_id[, list(Nplaylists=.N,
                                                    nnotremoved=sum(not_removed),
                                                    nspotify=sum(is_spotify),
                                                    nml=sum(is_ml),
                                                    ndays=mean(time_on_list,na.rm=T),
                                                    age = mean(age,na.rm=T)/365,
                                                    spotpop = mean(spotpop,na.rm=T),
                                                    meanfollowers=mean(followers,na.rm=T),
                                                    sony=sony[1],
                                                    warner=warner[1],
                                                    universal=universal[1]),by=c('track_id')]

placements_by_track[, sharespot:=nspotify/Nplaylists]
placements_by_track[, shareml:=nml/Nplaylists]
placements_by_track[, reach:=meanfollowers*Nplaylists]
placements_by_track[is.na(spotpop), spotpop:=0]
placements_by_track[, spotpop2:=ifelse(spotpop==0, NA,spotpop)]
placements_by_track[, retention:=nnotremoved/Nplaylists]

top_artist_trackids = unique(top_artists[sony+warner+universal>0]$track_id)

placements_by_track[, superstar:=track_id%in%top_artist_trackids]
placements_by_track[, superstarperc:=100*superstar]

void=rbindlist(lapply(c('Sony','Universal', 'Warner', 'Independent'), function(x) {
  if (x!='Independent') {
    placements_by_track[, filter:=get(tolower(x))==1]
  } else {
    placements_by_track[, filter:=sony==0&warner==0&universal==0]
  }
  
  res=rbindlist(lapply(c('all','superstar'), function(s) {
    placements_by_track[,filter2:=NULL]
    if (s=='all') placements_by_track[filter==T, filter2:=T]
    if (s=='superstar') placements_by_track[filter==T&superstar==T, filter2:=T]
    
    placements_by_track[filter2==T, N:=.N]
    res2= placements_by_track[filter2==T, lapply(.SD,mean,na.rm=T), .SDcols=c('N','Nplaylists','superstarperc', 'meanfollowers','reach','ndays', 'retention','sharespot','shareml','age', 'spotpop2')][, ':=' (label=x, type=s)]
    return(res2)
  }))
  res
}))

setcolorder(void, c('label'))
void

void = void[, c('label','type','N', 'Nplaylists', 'ndays'),with=F]

void_melted = melt(void, id.vars=c('label','type'))
                   
void2 = dcast(void_melted, label~type+variable)

void2=void2 = void2[match(c('Sony','Warner','Universal','Independent'), label)]

export_matrix <- as.matrix(void2)

saveTable(paste0(out_path, 'content.txt'), "<tab:content>", export_matrix, append=FALSE)
# run tablefill
system(paste0('tablefill -i ../output/figures_and_tables/content.txt -o ../output/figures_and_tables/content.tex template_content.tex'))


# Characteristics of ML vs. not ML playlists

pl_ids= unique(placements_by_track_id[track_id%in%top_artist_trackids]$id)

sample <- fread('../../analysis/output/paneldata.csv') #, select= c('id','date'))

playlists[, in_sample:=id%in%sample$id]
playlists[, with_superstar:=id%in%pl_ids]

sample[, updateratio:=nadded/ntracks]
sample[, update:=nadded>0]

samplestats= sample[, lapply(.SD, mean,na.rm=T), by = c('id'), .SDcols=c('ntracks',
                                                                         'nadded', 
                                                                         'updateratio',
                                                                         'update',
                                                                         'ntracksotherpl', 
                                                                         'ml_curr', 
                                                                         'trackage_days','tracklength_sec',
                                                                         grep('ac[_]', colnames(sample),value=T))]
pldata <- merge(playlists, samplestats, by = c('id'), all.x=T)

tmp = pldata[in_sample==T, list(N=.N, 
                                #Nspotify = length(which(grepl('spotify', owner_class,ignore=T))),
                                followers=mean(followers,na.rm=T),
                                share_spotify = 100*(length(which(grepl('spotify', owner_class,ignore=T)))/.N),
                                mlshare = mean(ml_curr,na.rm=T)*100,
                                ntracks=mean(ntracks),
                                #updateratio=mean(updateratio,na.rm=T)*100,
                                updateprob=mean(update,na.rm=T),
                                #trackage_years=mean(trackage_days,na.rm=T)/365,
                                tracklength_min=mean(tracklength_sec/60,na.rm=T)),by=c('with_superstar')]


tmp[with_superstar==T, type:='With major-label superstar']
tmp[with_superstar==F, type:='Without major-label superstar']
tmp[,type:=factor(type, levels=c('Without major-label superstar', 'With major-label superstar'))]

sum(tmp$N)
tmp2=dcast(melt(tmp, id.vars=c('with_superstar', 'type')), variable ~ type)
tmp2
tmp2[variable=='N']$variable = 'Number of playlists'
tmp2[variable=='followers']$variable = 'Avg. followers'
tmp2[variable=='share_spotify']$variable = 'Share of playlists curated by Spotify (in $\\%$)'
tmp2[variable=='mlshare']$variable = 'Avg. share of major label content (in $\\%$)'
tmp2[variable=='ntracks']$variable = 'Avg. number of tracks'
tmp2[variable=='updateprob']$variable = 'Avg. updating probability'
tmp2[variable=='trackage_years']$variable = 'Avg. time since release of tracks (in years)'
tmp2[variable=='tracklength_min']$variable = 'Avg. track length (in minutes)'
#tmp2[variable=='listeners_to_followers_ratio']$variable = 'Avg. Listener-to-Follower Ratio'
tmp2

export_matrix <- as.matrix(tmp2)
out_path='../output/figures_and_tables/'
saveTable(paste0(out_path, 'superstarplaylist.txt'), "<tab:superstarplaylist>", export_matrix, append=FALSE)
# run tablefill
system(paste0('tablefill -i ../output/figures_and_tables/superstarplaylist.txt -o ../output/figures_and_tables/superstarplaylist.tex template_superstarplaylist.tex'))


