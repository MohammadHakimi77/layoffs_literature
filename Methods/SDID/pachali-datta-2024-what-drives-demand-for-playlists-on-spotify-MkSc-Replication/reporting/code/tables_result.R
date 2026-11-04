# Produce results tables

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

res_df = matrix(ncol=8,nrow=6)
# fill log log
x=loglogmodels$`Playlist-month fixed effects`
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


x=syndid_summary[grepl('99999_200',filename)&grepl('logfollowers[.]', filename)&type=='promo']
res_df[1,3:4] <- as.numeric(with(x, c(gsub('[*]','', ATT), P)))
res_df[2,2] <- as.numeric(with(x, c(SE)))
res_df[3,2] <-c(NA)
res_df[4,2] <- c(NA)
res_df[5,1] <- c(x$MSPE)
res_df[6,2] <- as.numeric(with(x, samplesize))


x=syndid_summary[grepl('99999_200',filename)&grepl('logfollowers[.]', filename)&type=='ml']
res_df[1,7:8] <- as.numeric(with(x, c(gsub('[*]','', ATT), P)))
res_df[2,4] <- as.numeric(with(x, c(SE)))
res_df[3,4] <-c(NA)
res_df[4,4] <- c(NA)
res_df[5,2] <- c(x$MSPE)
res_df[6,4] <- as.numeric(with(x, samplesize))



#res_df[is.na(res_df)] = 

export_matrix <- as.matrix(res_df)

saveTable(paste0(out_path, 'results.txt'), "<tab:model_results>", export_matrix, append=FALSE)
# run tablefill
system(paste0('tablefill -i ../output/figures_and_tables/results.txt -o ../output/figures_and_tables/results.tex template_results.tex --pvals .05 .01 .001 --stars "^{*}" "^{**}" "^{***}"'))



# Log-log model results
models=loglogmodels$`Playlist-month fixed effects`

etable(models, digits='r5',fixef_sizes = T, adjustbox = 1)


### create output tables
unlink('../output/figures_and_tables/main_regression_log_log.tex')
etable(models,digits = "r5",tex=T,fixef_sizes=TRUE,
       depvar=F,
       dict = c(any_promo="Featured on Search Page",
                has_superstar = "Addition of Major Label Superstars",
                "log_ml_share_log1" = "Share of major label tracks (in %)",
                "log(playlist_duration_h+1)"="Play duration (in h)",
                "log(1 + rec_intensity_cat)"="Recommendation intensity",
                "log(followers+1)"="followers",
                'log(wnplaylists_trackage_year+1)' = 'Track age (in years)',
                'wnplaylists_ac_danceability' = 'Danceability',
                'wnplaylists_ac_energy' = 'Energy',
                'wnplaylists_ac_speechiness' = 'Speechiness',
                'wnplaylists_ac_acousticness' = 'Acousticness',
                'wnplaylists_ac_instrumentalness' = 'Instrumentalness',
                'wnplaylists_ac_liveness' = 'Liveness',
                'wnplaylists_ac_valence' = 'Valence',
                'wnplaylists_ac_tempo' = 'Tempo',
                'wnplaylists_ac_loudness' = 'Loudness',
                'any_promo_comp1' = 'Competit. (1) featured on Search Page',
                'any_promo_comp2' = 'Competit. (2) featured on Search Page',
                'any_promo_comp3' = 'Competit. (3) featured on Search Page',
                'any_promo_comp4' = 'Competit. (4) featured on Search Page',
                'any_promo_comp5' = 'Competit. (5) featured on Search Page',
                'any_promo_comp6' = 'Competit. (6) featured on Search Page',
                'any_promo_comp7' = 'Competit. (7) featured on Search Page',
                'any_promo_comp8' = 'Competit. (8) featured on Search Page',
                'any_promo_comp9' = 'Competit. (9) featured on Search Page',
                'any_promo_comp10' = 'Competit. (10) featured on Search Page',
                'any_promo_comp11' = 'Competit. (11) featured on Search Page',
                'any_promo_comp12' = 'Competit. (12) featured on Search Page',
                'any_promo_comp13' = 'Competit. (13) featured on Search Page',
                'any_promo_comp14' = 'Competit. (14) featured on Search Page',
                'any_promo_comp15' = 'Competit. (15) featured on Search Page',
                'has_superstar_comp1' = 'Competit. (1) superstar',
                'has_superstar_comp2' = 'Competit. (2) superstar',
                'has_superstar_comp3' = 'Competit. (3) superstar',
                'has_superstar_comp4' = 'Competit. (4) superstar',
                'has_superstar_comp5' = 'Competit. (5) superstar',
                'has_superstar_comp6' = 'Competit. (6) superstar',
                'has_superstar_comp7' = 'Competit. (7) superstar',
                'has_superstar_comp8' = 'Competit. (8) superstar',
                'has_superstar_comp9' = 'Competit. (9) superstar',
                'has_superstar_comp10' = 'Competit. (10) superstar',
                'has_superstar_comp11' = 'Competit. (11) superstar',
                'has_superstar_comp12' = 'Competit. (12) superstar',
                'has_superstar_comp13' = 'Competit. (13) superstar',
                'has_superstar_comp14' = 'Competit. (14) superstar',
                'has_superstar_comp15' = 'Competit. (15) superstar',
                'id_month' = 'Playlist-month',
                'date' = 'Day'),
       style.tex = style.tex(tpt = TRUE, notes.tpt.intro = "\\footnotesize",
                             tablefoot=F),
       notes = c("Two-way fixed effects model as specified in Equation 1, two-way clustered standard errors are in parentheses.",
                 "\\textsuperscript{***}$p<0.001$, 
                 \\textsuperscript{**}$p<0.01$, 
                 \\textsuperscript{*}$p<0.05$."),
       adjustbox = .43,
       label = 'tab:2wfe',
       signif.code = c("***"=0.001, "**"=0.01, "*"=0.05),
       se.below=F,
       title = 'Complete estimation results of the two-way fixed effects model.',
       file="../output/figures_and_tables/main_regression_log_log.tex")



# Log-log model results EXCLUDING FIRST TIME TREATED

### create output tables
unlink('../output/figures_and_tables/model_comparison.tex')
etable(list("Main" = loglogmodels$`Playlist-month fixed effects`,
            "Only first-time treatment" = loglogmodels$`First-time treatment only`),digits = "r5",tex=T,fixef_sizes=TRUE,
       depvar=F, headers = c('Main','Only first-time treatment'),
       dict = c(any_promo="Featured on Search Page",
                has_superstar = "Addition of Major Label Superstars",
                "log_ml_share_log1" = "Share of major label tracks (in %)",
                "log(playlist_duration_h+1)"="Play duration (in h)",
                "log(1 + rec_intensity_cat)"="Recommendation intensity",
                "log(followers+1)"="followers",
                'log(wnplaylists_trackage_year+1)' = 'Track age (in years)',
                'wnplaylists_ac_danceability' = 'Danceability',
                'wnplaylists_ac_energy' = 'Energy',
                'wnplaylists_ac_speechiness' = 'Speechiness',
                'wnplaylists_ac_acousticness' = 'Acousticness',
                'wnplaylists_ac_instrumentalness' = 'Instrumentalness',
                'wnplaylists_ac_liveness' = 'Liveness',
                'wnplaylists_ac_valence' = 'Valence',
                'wnplaylists_ac_tempo' = 'Tempo',
                'wnplaylists_ac_loudness' = 'Loudness',
                'any_promo_comp1' = 'Competit. (1) featured on Search Page',
                'any_promo_comp2' = 'Competit. (2) featured on Search Page',
                'any_promo_comp3' = 'Competit. (3) featured on Search Page',
                'any_promo_comp4' = 'Competit. (4) featured on Search Page',
                'any_promo_comp5' = 'Competit. (5) featured on Search Page',
                'any_promo_comp6' = 'Competit. (6) featured on Search Page',
                'any_promo_comp7' = 'Competit. (7) featured on Search Page',
                'any_promo_comp8' = 'Competit. (8) featured on Search Page',
                'any_promo_comp9' = 'Competit. (9) featured on Search Page',
                'any_promo_comp10' = 'Competit. (10) featured on Search Page',
                'any_promo_comp11' = 'Competit. (11) featured on Search Page',
                'any_promo_comp12' = 'Competit. (12) featured on Search Page',
                'any_promo_comp13' = 'Competit. (13) featured on Search Page',
                'any_promo_comp14' = 'Competit. (14) featured on Search Page',
                'any_promo_comp15' = 'Competit. (15) featured on Search Page',
                'has_superstar_comp1' = 'Competit. (1) superstar',
                'has_superstar_comp2' = 'Competit. (2) superstar',
                'has_superstar_comp3' = 'Competit. (3) superstar',
                'has_superstar_comp4' = 'Competit. (4) superstar',
                'has_superstar_comp5' = 'Competit. (5) superstar',
                'has_superstar_comp6' = 'Competit. (6) superstar',
                'has_superstar_comp7' = 'Competit. (7) superstar',
                'has_superstar_comp8' = 'Competit. (8) superstar',
                'has_superstar_comp9' = 'Competit. (9) superstar',
                'has_superstar_comp10' = 'Competit. (10) superstar',
                'has_superstar_comp11' = 'Competit. (11) superstar',
                'has_superstar_comp12' = 'Competit. (12) superstar',
                'has_superstar_comp13' = 'Competit. (13) superstar',
                'has_superstar_comp14' = 'Competit. (14) superstar',
                'has_superstar_comp15' = 'Competit. (15) superstar',
                'id_month' = 'Playlist-month',
                'date' = 'Day'),
       style.tex = style.tex(tpt = TRUE, notes.tpt.intro = "\\footnotesize",
                             tablefoot=F),
       notes = c("The first column is the main model specification. The second column removes playlists before their second treatment date as in the SDID data selection (to avoid overlapping treatment windows). Two-way fixed effects model as specified in Equation 1, two-way clustered standard errors are in parentheses.",
                 "\\textsuperscript{***}$p<0.001$, 
                 \\textsuperscript{**}$p<0.01$, 
                 \\textsuperscript{*}$p<0.05$."),
       adjustbox = .7,
       label = 'tab:2wfecompare',
       signif.code = c("***"=0.001, "**"=0.01, "*"=0.05),
       se.below=F,
       title = '2W-FE estimates including only first-time playlist treatment events.',
       file='../output/figures_and_tables/model_comparison.tex')


# report on ML effect in main model
print(round(loglogmodels$`Playlist-month fixed effects`$coeftable[which(rownames(loglogmodels$`Playlist-month fixed effects`$coeftable)=='log_ml_share_log1'),],4))
