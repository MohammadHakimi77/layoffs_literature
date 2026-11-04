# Generate category overview of playlist promotions
library(ggplot2)
library(data.table)

source('proc_aux.R')
source('use_tablefill.R')

promo_raw <- fread('../../analysis/temp/promotions.csv')
playlists <- fread('../../analysis/temp/playlists.csv')
panel <- fread("../../analysis/output/paneldata.csv", select = c('id','date'))

setkey(promo_raw, playlist_id)
setkey(playlists, playlist_id)
promo_raw[playlists, id:=i.id]

promo_raw[!sectionName=='featured'&!sectionName=='toplists'&date!=as.Date('2019-12-08')&date<=as.Date('2020-03-26')&id%in%unique(panel$id), sel:=T]
uniqueN(promo_raw[sel==T]$id)

# how many playlists are being ADDED (i.e., first not before 1 nov)
promo_raw[sel==T, censored:=any(date<as.Date('2019-11-01')),by=c('id')]

# add indicators for when playlists were first and last promoted
promo_raw[, ':='(first=date==min(date),
                 last=date==max(date)),by=c('id')]

# Create time chart per section
tmp4=promo_raw[sel==T, list(playlists=uniqueN(playlist_id),
                      changes=sum(first)+sum(last)),by=c('sectionName','date')]
tmp4[changes==0, changes:=NA]
tmp4[, observed:=1]

uniqueN(promo_raw[sel==T]$sectionName)
unique(promo_raw[sel==T]$sectionName)
uniqueN(promo_raw[sel==T&countryCode!='glob']$countryCode)

# how many playlists were featured in our sample?
uniqueN(promo_raw[sel==T]$playlist_id)

# censored obs
uniqueN(promo_raw[sel&censored]$playlist_id)

# non-censored obs
uniqueN(promo_raw[sel&!censored]$playlist_id)


tmp=promo_raw[date<=as.Date('2020-04-01'), list(obs=.N, new=uniqueN(id[censored==F])),by=c('date')]
setorder(tmp,date)
plot(tmp$date, tmp$new,type='l')

tmp4[, section_formatted := sectionName]

tmp4[grepl('blackhi', section_formatted), section_formatted:= 'Black History Month']
tmp4[grepl('edm', section_formatted), section_formatted:= 'EDM/Dance']
tmp4[grepl('hip', section_formatted), section_formatted:= 'Hip hop']
tmp4[grepl('indie', section_formatted), section_formatted:= 'Indie/Alternative']
tmp4[grepl('kpop', section_formatted), section_formatted:= 'K-pop']
tmp4[grepl('popculture', section_formatted), section_formatted:= 'Pop culture']
tmp4[grepl('rnb', section_formatted), section_formatted:= 'R&B']
tmp4[, section_formatted:=gsub('wellness_', '', section_formatted, ignore.case=T)]
tmp4[, section_formatted:=stringr::str_to_title(gsub('_', ' ', section_formatted))]

secs = tmp4[, list(date=min(date)),by=c('section_formatted')]
setorder(secs, section_formatted)

tmp4[, section_formatted:=factor(section_formatted, levels=rev(secs$section_formatted))]


ggplot(tmp4[date>=as.Date('2019-11-01')&date<=as.Date('2020-04-01')],
       aes(x=date, y= section_formatted)) + 
  geom_tile(aes(fill=as.factor(ifelse(observed>0,'observed','not observed')),alpha=.2)) +
  geom_tile(aes(fill = ifelse(changes>0, 'added', 'nochange')),
           size = 0.5) +
  scale_fill_manual(values=c('observed'='grey', 
                             'added'='black'))+
  scale_x_date(date_labels = "%b %Y", breaks = "1 months") + 
  labs(#title = "Updates to the Search Page",
       x = "Date", y = "Category on Spotify's Search Page") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust = .5),
        axis.text.y = element_text(size=9)) +
  theme(legend.position = "none", plot.margin = margin(l=.2,t=.2,r = .8, unit='cm'))

ggsave('../output/figures_and_tables/browsesection_changes.pdf', 
       width = 20, height = 15, units = "cm")
ggsave('../output/figures_and_tables/browsesection_changes.png', 
       width = 20, height = 15, units = "cm")


# Table w/ characteristics of promoted playlists
sample <- fread('../../analysis/output/paneldata.csv') #, select= c('id','date'))

playlists[, in_sample:=id%in%sample$id]
playlists[, ever_promoted:=playlist_id%in%unique(promo_raw$playlist_id)]
setorderv(playlists, 'followers',na.last=T)
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
                                   followers=mean(followers,na.rm=T),
                                   share_spotify = 100*(length(which(grepl('spotify', owner_class,ignore=T)))/.N),
                                   mlshare = mean(ml_curr,na.rm=T)*100,
                                   ntracks=mean(ntracks),
                                   updateprob=mean(update,na.rm=T),
                                   tracklength_min=mean(tracklength_sec/60,na.rm=T)),by=c('ever_promoted')]


tmp[ever_promoted==T, type:='Featured playlists']
tmp[ever_promoted==F, type:='Non-featured playlists']

sum(tmp$N)
tmp2=dcast(melt(tmp, id.vars=c('ever_promoted', 'type')), variable ~ type)
tmp2
tmp2[variable=='N']$variable = 'Number of playlists'
tmp2[variable=='followers']$variable = 'Avg. followers'
tmp2[variable=='share_spotify']$variable = 'Share of playlists curated by Spotify (in $\\%$)'
tmp2[variable=='mlshare']$variable = 'Avg. share of major label content (in $\\%$)'
tmp2[variable=='ntracks']$variable = 'Avg. number of tracks'
tmp2[variable=='updateprob']$variable = 'Avg. updating probability'
tmp2[variable=='tracklength_min']$variable = 'Avg. track length (in minutes)'
tmp2

export_matrix <- as.matrix(tmp2)
out_path='../output/figures_and_tables/'
saveTable(paste0(out_path, 'promoplaylist.txt'), "<tab:promoplaylist>", export_matrix, append=FALSE)

# run tablefill
system(paste0('tablefill -i ../output/figures_and_tables/promoplaylist.txt -o ../output/figures_and_tables/promoplaylist.tex template_promoplaylist.tex'))

