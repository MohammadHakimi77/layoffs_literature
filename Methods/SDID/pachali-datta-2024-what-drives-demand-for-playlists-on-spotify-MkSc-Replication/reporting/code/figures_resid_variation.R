# Generate plots showing residual variation
# (models have already been estimated before and are loaded in via the RData object next)

library(data.table)
library(ggplot2)

load('../../analysis/output/loglogmodels.RData')

df2 = saved_resid[, list(resid_promo_agg=mean(resid_promo,na.rm=TRUE),resid_ml_agg=mean(resid_ml,na.rm=TRUE), promo_mean = mean(any_promo,na.rm=TRUE), ml_mean = mean(has_superstar,na.rm=TRUE)),by=c('date')]

summary(df2$resid_promo_agg)
summary(df2$resid_ml_agg)
summary(df2$promo_mean)
summary(df2$ml_mean)

# plot mean residuals of the number of sections featured on the Search Page across playlists per date
p<-ggplot(data=df2) + geom_line(aes(x=date, y=resid_promo_agg/promo_mean ,color = "Featured on Search Page"), linewidth=1) + 
  geom_line(aes(x=date, y=resid_ml_agg/ml_mean,color = "Superstar added to playlist"), size=1) + 
  labs(y='Residuals', x = 'Date') + scale_x_date(date_labels = "%b %Y") #+ ylim(-0.008,0.008)

pa= p + theme_bw() + scale_fill_grey() + scale_colour_manual(values = c("black", "grey")) + theme(legend.position = "none") +
  theme(legend.title = element_blank(),legend.text=element_text(),
        legend.justification = c(0, 1),
        legend.position = c(.6, 1), legend.background = element_rect(fill = "transparent", linetype = "dotted"),
        plot.margin = unit(c(0.2,.8,.2,.2), "cm"))

ggsave("../output/figures_and_tables/residuals_ml_featuring.pdf", plot=pa,
       width = 20, height = 10, units = "cm")


df_sds = saved_resid[, list(resid_promo_agg=sd(resid_promo,na.rm=TRUE),resid_ml_agg=sd(resid_ml,na.rm=TRUE),
                            mean_promo = mean(any_promo,na.rm=TRUE),
                            mean_ml = mean(has_superstar,na.rm=TRUE)),by=c('id')]

# number of playlists ever getting featured on the Search Page in our sample
uniqueN(saved_resid[any_promo!=0,id])

summary(df_sds$resid_promo_agg)
summary(df_sds$resid_ml_agg)

### coefficient of varition (playlist-month fixed effects)
summary(df_sds[mean_promo>0,resid_promo_agg]/mean(df_sds[mean_promo>0,mean_promo]))
summary(df_sds[mean_ml>0,resid_ml_agg]/mean(df_sds[mean_ml>0,mean_ml]))
quantile(df_sds[mean_ml>0,resid_ml_agg]/mean(df_sds[mean_ml>0,mean_ml]),probs = c(0.75, 0.8, 0.85, 0.9, 0.95, 0.99),na.rm=T)

# histograms
mean_promo_var = round(mean(df_sds$resid_promo_agg[df_sds$mean_promo>0]/abs(mean(df_sds$mean_promo[df_sds$mean_promo>0]))),2)

p<-ggplot(df_sds[mean_promo>0,], aes(x=resid_promo_agg/abs(mean(mean_promo)))) + 
  geom_histogram(bins = 60) + labs(y='Count', x = 'Residual featuring variation') + xlim(0,0.6) + ylim(0,350)+
  geom_vline(xintercept=mean_promo_var, size=1, color="red") +
  geom_text(aes(x=mean_promo_var+0.2, label=paste0("Mean\n",mean_promo_var), y=300)) +
  theme(legend.title = element_blank(),legend.text=element_text(),
        legend.justification = c(0, 1),
        legend.position = c(.6, 1), legend.background = element_rect(fill = "transparent", linetype = "dotted"),
        plot.margin = unit(c(0.2,.8,.2,.2), "cm")) + theme_bw()


ggsave("../output/figures_and_tables/residual_variation_featuring_hist.pdf", plot=p,
       width = 10, height = 8, units = "cm")

# histograms
mean_ml_var = round(mean(df_sds$resid_ml_agg[df_sds$mean_ml>0]/mean(df_sds$mean_ml[df_sds$mean_ml>0])),4)
pl2<-ggplot(df_sds[df_sds$mean_ml>0], aes(x=resid_ml_agg/mean(mean_ml))) + 
  geom_histogram(bins = 60) + labs(y='Count', x = 'Residual major label superstar variation') + xlim(0,0.08) + ylim(0,100) +
  geom_vline(xintercept=mean_ml_var, size=1, color="red") +
  geom_text(aes(x=mean_ml_var+0.02, label=paste0("Mean\n",mean_ml_var), y=2000)) +
  theme(legend.title = element_blank(),legend.text=element_text(),
        legend.justification = c(0, 1),
        legend.position = c(.6, 1), legend.background = element_rect(fill = "transparent", linetype = "dotted"),
        plot.margin = unit(c(0.2,.8,.2,.2), "cm")) + theme_bw()

ggsave("../output/figures_and_tables/residual_variation_mlshare_hist.pdf", plot=pl2,
       width = 10, height = 8, units = "cm")
