# Generate descriptive stats for paper

# start with an empty workspace
  rm(list=ls())

# define path to store generated tables/figures
  out_path = '../output/figures_and_tables/'
  dir.create(out_path, recursive=T)
  
# load required packages
  library(data.table)
  library(ggplot2)
  library(ggthemes)
  library(stringr)
  library(fixest)
  
  source('use_tablefill.R')
  source('proc_aux.R')
  theme_set(theme_bw())
  
# load data 
  nrows = -1L

  pls <- fread('../../analysis/temp/playlists.csv', nrows = nrows)
  setorderv(pls, 'followers', order = -1L, na.last=T)

  categories <- fread('../../analysis/temp/playlist-categories.csv')

  panel<-fread('../../analysis/output/paneldata.csv', nrows=nrows)
  
  # Labels for ownership structure
  pls[, print_owner_class:=owner_class]
  
  pls[, thisis:=grepl('^this is', name, ignore.case=T)&grepl('spotify',owner_class,ignore.case=T)]
  
  pls[owner_class=='Spotify' & thisis==F, print_owner_class := paste0('Spotify - ', recommendation_type)]
  pls[owner_class=='Spotify' & thisis==F & grepl('artist', recommendation_type,ignore.case=T), print_owner_class := paste0('Spotify - Semi-personalized recommendations')]
  pls[owner_class=='Spotify' & thisis==F & grepl('fully|semi', recommendation_type,ignore.case=T), print_owner_class := paste0('Spotify - Semi-personalized recommendations')]
  pls[owner_class=='Spotify' & thisis==T, print_owner_class := paste0('Spotify --- \"This is\"-playlists')]
  
  pls[grepl('semi', print_owner_class,ignore.case=T), print_owner_class := paste0('Spotify --- Semi-personalized')]
  pls[grepl('not pers', print_owner_class,ignore.case=T), print_owner_class := paste0('Spotify --- Non-personalized')]
  pls[owner_class=='other', print_owner_class := 'Other']
  
  ordered_curators = pls[, list(followers=sum(followers, na.rm=T)),by=c('print_owner_class')][, list(curator=print_owner_class, share=followers/sum(followers))]
  setorderv(ordered_curators, 'share', order=-1L)
  pls[, print_owner_class:=factor(print_owner_class, levels=ordered_curators$curator)]
  
  setkey(panel, id)
  setkey(pls, id)
  panel[pls, updated_owner_class:=i.owner_class]
  panel[pls, updated_print_owner_class:=print_owner_class]
  
  panel[pls, listeners_to_followers_ratio:=listeners_to_followers_ratio]
  
### DATA DESCRIPTION
  
#sink('../output/reporting.txt')

cat('DATA PREPARATION\n=========================\n\n\n\n')

cat(paste0('Number of playlists in cross-sectional playlist data: ', nrow(pls)), fill=T)
cat(paste0('Number of playlists in the final panel data: ', uniqueN(panel$id)), fill=T)
cat(paste0('Number of playlists accounting for 50% follower share: ', nrow(pls[follower_percentile<=.5])), fill=T)
cat(paste0('Share of playlists with fewer than 1 follower: ', nrow(pls[followers<=1|is.na(followers)])/nrow(pls)), fill=T)

# Correlation between listeners and followers
with(panel, cor(followers, listeners,use='pairwise'))

round(mean(panel[, list(playlist_duration_h=mean(playlist_duration_h,na.rm=T)),by=c('id')]$playlist_duration_h,na.rm=T),1)
round(median(panel[, list(playlist_duration_h=mean(playlist_duration_h,na.rm=T)),by=c('id')]$playlist_duration_h,na.rm=T),1)

#############################
# DISTRIBUTION OF FOLLOWERS #
#############################

setorderv(pls, 'followers', -1L, na.last=T)
pls[, N_percentile:=(1:.N)/nrow(pls)]
pls[, followers_without_na:=ifelse(is.na(followers),0,followers)]
pls[, follower_percentile:=cumsum(as.numeric(followers_without_na))/sum(followers_without_na)]


tmp = data.table(quants = c(.0109,.05, .1, .25, .5, .75, .95, .99, .995, 1))

tot_followers = sum(pls$followers, na.rm=T)

tmp[, cumplaylists := sapply(quants, function(x) nrow(pls[follower_percentile<=x])/nrow(pls))]
tmp[, N := sapply(quants, function(x) nrow(pls[follower_percentile<=x]))]
setnames(tmp, c('Follower share (cum.)', 'Top Quantile', 'Number of playlists (cum.)'))

export_matrix <- as.matrix(tmp)
saveTable(paste0(out_path, 'distribution.txt'), "<tab:distribution>", export_matrix, append=FALSE)

# run tablefill
system(paste0('tablefill -i ../output/figures_and_tables/distribution.txt -o ../output/figures_and_tables/distribution.tex template_distribution.tex'))


#################################################
# OWNERSHIP TYPES AND AVERAGE MAJOR LABEL SHARE #
#################################################

tmp = panel[, list(mlshare=mean(ml_curr,na.rm=T)),by=c('id')]
setkey(tmp, id)
setkey(pls, id)
pls[tmp, mlshare:=i.mlshare]
setorderv(pls, 'followers', na.last=T, order=-1L)
pls[, topk:=1:.N<=150000]

tmp = lapply(c('selection','all'), function(switch) {
  if (switch=='all') pls[, indic:=T]
  if (switch=='topk') pls[topk==T, indic:=T]
  if (switch=='selection') pls[, indic:=id%in%panel$id]
  tot = sum(pls[indic==T]$followers,na.rm=T)
  tmp = pls[indic==T, list(`Follower share` = sum(followers, na.rm=T)/tot,
                           `N` = .N,
                           `Mean followers` = mean(followers, na.rm=T)
  ),by=c('print_owner_class')]
  tmp
})

tmp = merge(tmp[[1]], tmp[[2]], by = c('print_owner_class'), all.x=T, sort = F)
setorder(tmp, print_owner_class)


colnames(tmp) <- gsub('[.]x|[.]y', '', colnames(tmp))
colnames(tmp) <- gsub('print_owner_class', 'Playlist curator', colnames(tmp))

headers = c(" " = 1, "All playlists" = 3, "Selected playlists" = 3)
tmp = tmp[match(tmp$`Playlist curator`, ordered_curators$curator)]

export_matrix <- as.matrix(tmp)
stopifnot(sum(tmp[, 3])==34483)
saveTable(paste0(out_path, 'curatorswide.txt'), "<tab:curatorswide>", export_matrix, append=FALSE)
system(paste0('tablefill -i ../output/figures_and_tables/curatorswide.txt -o ../output/figures_and_tables/curatorswide.tex template_curatorswide.tex'))

############################
# ML SHARES BY CURATORS #
############################

  tmp = panel[!is.na(updated_print_owner_class), list(mlshare=mean(ml_curr,na.rm=T)),by=c('updated_print_owner_class')]
  tmp[, updated_print_owner_class:=factor(updated_print_owner_class, levels=rev(levels(updated_print_owner_class)))]
  
  levels(tmp$updated_print_owner_class) <- gsub('[-][-][-]','-',levels(tmp$updated_print_owner_class))
  
  
  
  p<-ggplot(data=tmp, aes(x=updated_print_owner_class, y=mlshare, fill  = updated_print_owner_class)) +
    geom_bar(stat="identity", fill = 'grey50') + coord_flip() + labs(y='Share of major label content', x = '', fill  = 'Category')+ theme_bw() + scale_fill_grey() + theme(legend.position = "none") 
  
  p 
  # save as pdf
  ggsave(paste0(out_path, "figure_mlshares.pdf"),width = 20, height = 10, units = "cm")
  
  
  
############################
# 4. POPULARITY & ML SHARE #
############################

  # in buckets
  panel[, cutml:=cut(ml_curr,breaks=10)]
  
  # in quantiles
  panel[, cutml:=ceiling(ecdf(ml_curr)(ml_curr)*10)/10]
  
  table(panel$cutml)
  
  tmp3=panel[, lapply(.SD, mean, na.rm=T), by = c('id','cutml'),
             .SDcols=c('ntracksotherpl','followers')]
  tmp3 = tmp3[!is.na(cutml), lapply(.SD, mean,na.rm=T),by=c('cutml')]
  setorder(tmp3, cutml)
  
  pl1 <- ggplot(data=tmp3[!is.na(cutml)], aes(cutml, ntracksotherpl)) +  geom_bar(position = "dodge", stat="identity") +
    labs(y='Content popularity', x = 'Major label share') + theme_bw() + scale_fill_grey() + theme(legend.position = "none")
  
  
  pl2 <- ggplot(data=tmp3[!is.na(cutml)], aes(cutml, followers)) +  geom_bar(position = "dodge", stat="identity") +
    labs(y='Followers', x = 'Major label share') + theme_bw() + scale_fill_grey() + theme(legend.position = "none")

  # save as pdf
  pl2
  ggsave(paste0(out_path, "figure_followers_mlshare.pdf"), width = 10, height = 10, units = "cm")
  
  
  # TOP CATEGORIES
  tmpcatx = categories[id%in%unique(panel$id), list(uniqueN(cat_id)),by=c('id')]
  nrow(tmpcatx[V1==1])/nrow(tmpcatx)
  
  tmpcat = categories[id%in%unique(panel$id)]
  
  tmpcat[, last_obs:=max(begin_init,na.rm=T),by=c('id')]
  
  #plcat = tmpcat[begin_init==last_obs, list(category=unlist(strsplit(category,',', fixed=T)[[1]])),by=c('id')]
  plcat = tmpcat[begin_init==last_obs, list(category=category),by=c('id')]
  setkey(pls, id)
  setkey(plcat, id)
  plcat[pls, followers:=i.followers]
  #plcat[, ntags:=.N,by=c('id')]
  setkey(pls, id)
  setkey(plcat, id)
  plcat[pls, name:=i.name]
  
  setorderv(plcat, c('category','followers'), order=c(1L,-1L))
  tmp=plcat[, list(N=.N,followers=sum(followers,na.rm=T)/1E6, 
                   #N_selected=sum(id%in%selids), sel_followers=sum(followers[id%in%selids],na.rm=T)/1E6,
                   example=paste0(name[1:3],collapse=', ')),by=c('category')]
  setorderv(tmp, c('followers'), order=-1L)
  tmp[, category:=gsub(',', '+', category)]
  
  setnames(tmp, 'category', 'Category name')
  setnames(tmp, 'followers', 'Followers (in m.)')
  setnames(tmp, 'example', 'Top 3 playlists')
  
  tmp$`Top 3 playlists` <- gsub('[#]', '', tmp$`Top 3 playlists`)
  
  export_matrix <- as.matrix(tmp)[1:20,]
  saveTable(paste0(out_path, 'categories.txt'), "<tab:categories>", export_matrix, append=FALSE)
  system(paste0('tablefill -i ../output/figures_and_tables/categories.txt -o ../output/figures_and_tables/categories.tex template_categories.tex'))
  
  
  
# Updating frequency (stat in the paper)
  
  panel[, updated:=nadded>0|nremoved>0]
  setorder(panel, id, date)
  panel[, updated_cum := cumsum(updated), by = c('id')]
  tmp = panel[, list(days = .N), by = c('id', 'updated_cum')]
  tmp[, selected:=T]
  tmp[, selected:=ifelse(updated_cum==0|updated_cum==max(updated_cum), F, T), by = c('id')]
  
  tmp <- tmp[selected==T]
  
  averages = tmp[, list(mean=mean(days), median=median(days),
                        sd=sd(days), N= .N), by = c('id')]
  mean(averages$median)
  
  nrow(averages[median<=7])/nrow(averages)
  
  
############################################
#### 2. DESCRIPTIVE STATS ON PANEL DATA ####
############################################

nointerpolations_panel <- panel[metadata_stretch_length>=100&qualifying_stretch_length>=28]

### define recommendation intensity
rec_definition = c('recfully') # which recommendations are to be considered: one of c('recfully','recsemi','recartist')
nointerpolations_panel[, rec_intensity_cat:=0]

for (.v in rec_definition) nointerpolations_panel[, rec_intensity_cat:=rec_intensity_cat+(get(paste0(.v,'_nadded_cat'))/get(paste0(.v, '_nplaylists_cat')))]
nointerpolations_panel[, rec_intensity_cat:=rec_intensity_cat/length(rec_definition)]
nointerpolations_panel[is.na(rec_intensity_cat), rec_intensity_cat:=0]

vars=c("followers", "any_promo", "has_superstar",  "ml_curr", "rec_intensity_cat", "playlist_duration_h", "wnplaylists_trackage_year", "wnplaylists_ac_danceability", "wnplaylists_ac_energy", "wnplaylists_ac_speechiness", "wnplaylists_ac_acousticness", "wnplaylists_ac_instrumentalness", "wnplaylists_ac_liveness", "wnplaylists_ac_valence", "wnplaylists_ac_tempo", "wnplaylists_ac_loudness")

N <- function(x, ...) length(x[which(!is.na(x))])

tmp=t(rbindlist(lapply(list(mean, sd, min,max), function(fun) {
  nointerpolations_panel[, lapply(.SD, fun, na.rm=T), .SDcols=vars]
})))

tmp = data.table(variable=rownames(tmp), tmp)
setnames(tmp, c('variable', 'mean', 'SD', 'Min','Max'))

tmp$variable <- repl_names(tmp$variable)

tmp[,2:5] = round(tmp[,2:5],2)

export_matrix <- as.matrix(tmp)[,1:5]

saveTable(paste0(out_path, 'summarystats.txt'), "<tab:summarystats>", export_matrix, append=FALSE)
system(paste0('tablefill -i ../output/figures_and_tables/summarystats.txt -o ../output/figures_and_tables/summarystats.tex template_summarystats.tex'))

dir.create('../temp')
sink('../temp/descriptives.txt')
cat('done')
sink()
