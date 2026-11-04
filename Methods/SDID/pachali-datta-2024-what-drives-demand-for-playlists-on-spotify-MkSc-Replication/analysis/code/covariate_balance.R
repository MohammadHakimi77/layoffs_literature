# Assess covariate balance in synthetic DiD models
library(data.table)
library(fixest)

load('../output/synthdid_results_matched_99999_200_ml_logfollowers.RData')
load('../output/synthdid_results_matched_99999_200_promo_logfollowers.RData')
panel <- fread('../output/paneldata.csv')

datasets = list(synthdid_promo, synthdid_ml)

covariate_balance = lapply(datasets, function(dt) {
  
  # just use those used for estimation
  periods=rbindlist(lapply(dt$samplesize, function(x) x$ids))
  periods[, treated:=as.numeric(date>=period&treated_unit==1)]
  periods[, treated2:=as.numeric(date>period&treated_unit==1)]
  periods[, time_to_treat:=as.numeric(as.Date(date)-as.Date(period))]
  
  setkey(periods, id,date)
  setkey(panel, id, date)
  
  testpanel=merge(periods, panel, all.x=T,all.y=F, by=c('id','date'))
  unique(testpanel$period)
  uniqueN(testpanel[treated==1]$id)
  
  testpanel[, id_group:=.GRP,by=c('id','period')]
  testpanel[, date_group:=.GRP,by=c('date','period')]
  
  uniqueN(testpanel[treated==1]$id)
  
  m<-feols(c(I((nadded+nremoved)/ntracks), trackage_year, any_promo, has_superstar,wnplaylists_ac_danceability, wnplaylists_ac_energy, wnplaylists_ac_speechiness, wnplaylists_ac_acousticness, wnplaylists_ac_instrumentalness,
             wnplaylists_ac_liveness,wnplaylists_ac_valence,wnplaylists_ac_tempo,wnplaylists_ac_loudness) ~ treated|id+date, data=testpanel[abs(time_to_treat)>=1&treated_unit==1], vcov="twoway") #[treated_unit==1])
  
  return(m)
})

save(covariate_balance, file = '../output/covariate_balance.RData')
