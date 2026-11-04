# Generate stats on covariate balance in synthetic DiD models

library(data.table)
library(fixest)

load('../../analysis/output/covariate_balance.RData')
source('proc_aux.R')
source('use_tablefill.R')

res=rbindlist(lapply(1:2, function(y) {
  cb=covariate_balance[[y]]
  res=rbindlist(lapply(cb, function(x) data.table(summary(x)$coeftable)))
  res[, dv:=names(cb)]
  if (y==1) res[, model:='promo']
  if (y==2) res[, model:='ml']
  
  return(res)
}))

res[grepl('nadded [+] nremoved',dv), dv:='update']

res[, pretty_dv:=repl_names(dv)]

res <- res[!(model=='promo'&grepl('promo',dv))]
res <- res[!(model=='ml'&grepl('superstar',dv))]
setnames(res, 'Estimate','est')
setnames(res, 'Std. Error','se')
setnames(res, 't value','t')
setnames(res, 'Pr(>|t|)','p')

res2=melt(res, id.var=c('dv','pretty_dv','model'))
res2[, variable:=factor(variable, levels=c('est','p','se','t'))]

res2[, model:=factor(model, levels=c('promo','ml'))]

res2<-rbind(res2, data.frame('N','N','promo', 'est', covariate_balance[[1]][[1]]$nobs),use.names=F)
res2<-rbind(res2, data.frame('N','N','ml', 'est', covariate_balance[[2]][[1]]$nobs),use.names=F)

tmp = dcast(res2[grepl('est|p|se', variable)], pretty_dv~model+variable)
tmp[,order:=as.numeric(NA)]
tmp[grepl('superstar',pretty_dv,ignore.case=T), order:=1]
tmp[grepl('featured',pretty_dv,ignore.case=T), order:=2]
tmp[grepl('updated',pretty_dv,ignore.case=T), order:=3]
tmp[grepl('track age',pretty_dv,ignore.case=T), order:=4]
tmp[is.na(order), order:=100+rank(pretty_dv)]
tmp[pretty_dv=='N', order:=999]
setorder(tmp, order,na.last=T)
tmp[, order:=NULL]


export_matrix <- as.matrix(tmp)
export_matrix[is.na(export_matrix)]<-'.'
out_path='../output/figures_and_tables/'
saveTable(paste0(out_path, 'covariatebalance.txt'), "<tab:covbalance>", export_matrix, append=FALSE)
# run tablefill
system(paste0('tablefill -i ../output/figures_and_tables/covariatebalance.txt -o ../output/figures_and_tables/covariatebalance.tex template_covariatebalance.tex --pvals .05 .01 .001 --stars "^{*}" "^{**}" "^{***}"'))

