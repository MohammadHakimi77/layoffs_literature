# Generate robustness check tables

rm(list=ls())
gc()

library(data.table)
library(fixest)

source('use_tablefill.R')
source('proc_aux.R')

out_path = '../output/figures_and_tables/'
dir.create(out_path, recursive=T)

# Load results
load('../../analysis/output/syndid_results.RData')
load('../../analysis/output/loglogmodels.RData')


# ROBUSTNESS: WITHOUT SEASONAL CATEGORIES
# ==========================================

res_df = matrix(ncol=8,nrow=6)

# Main results
# ========

# 2WFE
x=loglogmodels$`Playlist-month fixed effects`
res_df[1, 1:2] <- summary(x)$coeftable[which(grepl('any_promo$', rownames(summary(x)$coeftable))),c('Estimate', 'Pr(>|t|)')]
res_df[2, 1] <- c(summary(x)$coeftable[which(grepl('any_promo$', rownames(summary(x)$coeftable))),c('Std. Error')])
res_df[3, 1] <- c(r2(x,type='r2'))
res_df[4, 1] <- c(r2(x,type='ar2'))
res_df[5, 1] <- c(NA)
res_df[6, 1] <- c(nobs(x))

# SDID
x=syndid_summary[grepl('99999_200',filename)&grepl('logfollowers[.]',filename)&type=='promo']
res_df[1,3:4] <- as.numeric(with(x, c(gsub('[*]','', ATT), P)))
res_df[2,2] <- as.numeric(with(x, c(SE)))
res_df[3,2] <-c(NA)
res_df[4,2] <- c(NA)
res_df[5,1] <- c(x$MSPE)
res_df[6,2] <- as.numeric(with(x, samplesize))

# After removal of seasonal events
# ================================
# 2WFE
x=loglogmodels$`Playlist-month fixed effects - excl. other seasonal`
res_df[1, 5:6] <- summary(x)$coeftable[which(grepl('any_promo$', rownames(summary(x)$coeftable))),c('Estimate', 'Pr(>|t|)')]
res_df[2, 3] <- c(summary(x)$coeftable[which(grepl('any_promo$', rownames(summary(x)$coeftable))),c('Std. Error')])
res_df[3, 3] <- c(r2(x,type='r2'))
res_df[4, 3] <- c(r2(x,type='ar2'))
res_df[5, 3] <- c(NA)
res_df[6, 3] <- c(nobs(x))

# SDID
x=syndid_summary[grepl('99999_200_promoremoveotherseasonal_logfollowers',filename)]
res_df[1,7:8] <- as.numeric(with(x, c(gsub('[*]','', ATT), P)))
res_df[2,4] <- as.numeric(with(x, c(SE)))
res_df[3,4] <-c(NA)
res_df[4,4] <- c(NA)
res_df[5,2] <- c(x$MSPE)
res_df[6,4] <- as.numeric(with(x, samplesize))



#res_df[is.na(res_df)] = 

export_matrix <- as.matrix(res_df)

saveTable(paste0(out_path, 'results_robust_seasonal.txt'), "<tab:model_robust_seasonal>", export_matrix, append=FALSE)
# run tablefill

#
system(paste0('tablefill -i ../output/figures_and_tables/results_robust_seasonal.txt -o ../output/figures_and_tables/results_robust_seasonal.tex template_results_robust_seasonal.tex --pvals .05 .01 .001 --stars "^{*}" "^{**}" "^{***}"'))


#############
### IHS #####
#############

res_df = matrix(ncol=8,nrow=6)

# 2WFE
x=loglogmodels$`Playlist-month fixed effects (ihs)`
res_df[1, 1:2] <- summary(x)$coeftable[which(grepl('any_promo$', rownames(summary(x)$coeftable))),c('Estimate', 'Pr(>|t|)')]
res_df[2, 1] <- c(summary(x)$coeftable[which(grepl('any_promo$', rownames(summary(x)$coeftable))),c('Std. Error')])
res_df[3, 1] <- c(r2(x,type='r2'))
res_df[4, 1] <- c(r2(x,type='ar2'))
res_df[5, 1] <- c(NA)
res_df[6, 1] <- c(nobs(x))

res_df[1, 5:6] <- summary(x)$coeftable[which(grepl('has_superstar$', rownames(summary(x)$coeftable))),c('Estimate', 'Pr(>|t|)')]
res_df[2, 3] <- c(summary(x)$coeftable[which(grepl('has_superstar$', rownames(summary(x)$coeftable))),c('Std. Error')])
res_df[3, 3] <- c(r2(x,type='r2'))
res_df[4, 3] <- c(r2(x,type='ar2'))
res_df[5, 3] <- c(NA)
res_df[6, 3] <- c(nobs(x))

x=syndid_summary[grepl('99999_200',filename)&grepl('ihs',filename)&type=='promo']
res_df[1,3:4] <- as.numeric(with(x, c(gsub('[*]','', ATT), P)))
res_df[2,2] <- as.numeric(with(x, c(SE)))
res_df[3,2] <-c(NA)
res_df[4,2] <- c(NA)
res_df[5,1] <- c(x$MSPE)
res_df[6,2] <- as.numeric(with(x, samplesize))


x=syndid_summary[grepl('99999_200',filename)&grepl('ihs',filename)&type=='ml']
res_df[1,7:8] <- as.numeric(with(x, c(gsub('[*]','', ATT), P)))
res_df[2,4] <- as.numeric(with(x, c(SE)))
res_df[3,4] <-c(NA)
res_df[4,4] <- c(NA)
res_df[5,2] <- c(x$MSPE)
res_df[6,4] <- as.numeric(with(x, samplesize))


export_matrix <- as.matrix(res_df)

saveTable(paste0(out_path, 'results_robust_ihs.txt'), "<tab:model_robust_ihs>", export_matrix, append=FALSE)
# run tablefill
system(paste0('tablefill -i ../output/figures_and_tables/results_robust_ihs.txt -o ../output/figures_and_tables/results_robust_ihs.tex template_robust_ihs.tex --pvals .05 .01 .001 --stars "^{*}" "^{**}" "^{***}"'))


