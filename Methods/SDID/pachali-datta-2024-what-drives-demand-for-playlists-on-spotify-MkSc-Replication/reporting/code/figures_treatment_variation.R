# Generate treatment variation plots
library(data.table)
library(ggplot2)

treatment_promo <- fread('../../analysis/temp/treated_promo.csv')[treated==T]
treatment_ml <- fread('../../analysis/temp/treated_ml.csv')[treated==T]
full_panel <- fread('../../analysis/output/paneldata.csv')

setkey(treatment_promo, id)
setkey(full_panel, id)

full_panel[treatment_promo, treatment_event_promo:=i.first_observed_promo_date]

tmp = treatment_ml[treated==T&(universal|warner|sony>0)]
setkey(tmp, id)
full_panel[tmp, treatment_event_ml:=i.treatment_date]
             
# Treatment variation plot for promotions
date_breaks = seq(from = as.Date('2019-11-01'), to=as.Date('2020-03-15'), by = c('1 month'))

tmp=full_panel[!is.na(treatment_event_promo)] 
setorder(tmp, treatment_event_promo, id, date)
tmp[, id:=factor(id, levels=rev(unique(tmp$id)))]
tmp[, is_promoted:=date>=treatment_event_promo]
length(unique(tmp$treatment_event_promo))

tmp[qualifying_stretch_length<28, is_promoted:=NA]

fill_values <- as.factor(ifelse(is.na(tmp$is_promoted), 'Unobserved', 
                                ifelse(tmp$is_promoted, 'After Featuring', 'Before Featuring')))
fill_values <- factor(fill_values, levels=rev(c('Before Featuring','After Featuring','Unobserved')))
print('plot1')
pl1<- ggplot(tmp, aes(x = date, y = id)) +
  geom_tile(aes(fill = fill_values), height = 0.9) + ylab('Playlist') + xlab('Time') +
  scale_x_date(date_labels = "%b %Y", breaks = date_breaks) + 
  scale_fill_manual(values = c('After Featuring' = 'black', 'Before Featuring' = 'grey60', 'Unobserved' = 'grey80')) +
  guides(fill=guide_legend(title="", reverse=T)) + theme_bw() +# scale_fill_grey()+
  theme(axis.text.y = element_blank(),
        panel.grid.minor.y=element_blank(),
        axis.ticks.y=element_blank(),
        panel.grid.major.y=element_blank(),
        legend.position='bottom')+
  theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust = 0.5))



ggsave(paste0('../output/figures_and_tables/', 'treatmentvar_promo.pdf'),
       width = 20, height = 10, units = "cm", plot = pl1)
ggsave(paste0('../output/figures_and_tables/', 'treatmentvar_promo.png'),
       width = 20, height = 10, units = "cm", plot = pl1)

# Treatment variation plot for ML content
tmp=full_panel[!is.na(treatment_event_ml)]
setorder(tmp, treatment_event_ml, id, date)
tmp[, id:=factor(id, levels=rev(unique(tmp$id)))]
tmp[, is_ml:=date>=treatment_event_ml]

length(unique(tmp$treatment_event_ml))

# stats
uniqueN(tmp$id)
tmpx=tmp[, list(.N),by=c('id','treatment_event_ml')][, list(ntreated=.N),by=c('id')]
table(tmpx$ntreated)
uniqueN(tmp$treatment_event_ml)

tmp[qualifying_stretch_length<28, is_ml:=NA]

fill_values <- as.factor(ifelse(is.na(tmp$is_ml), 'Unobserved', 
                                ifelse(tmp$is_ml, 'After Addition of Major Label Superstars', 'Before Addition of Major Label Superstars')))
fill_values <- factor(fill_values, levels=rev(c('Before Addition of Major Label Superstars','After Addition of Major Label Superstars','Unobserved')))

print('plot2')
pl2<- ggplot(tmp, aes(x = date, y = id)) +
  geom_tile(aes(fill = fill_values), height = 0.9) + ylab('Playlist') + xlab('Time') +
  scale_x_date(date_labels = "%b %Y", breaks = date_breaks) + 
  scale_fill_manual(values = c('After Addition of Major Label Superstars' = 'black', 'Before Addition of Major Label Superstars' = 'grey60', 'Unobserved' = 'grey80')) +
  guides(fill=guide_legend(title="", reverse=T)) + theme_bw() +# scale_fill_grey()+
  theme(axis.text.y = element_blank(),
        panel.grid.minor.y=element_blank(),
        axis.ticks.y=element_blank(),
        panel.grid.major.y=element_blank(),
        legend.position='bottom')+
  theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust = 0.5))


ggsave(paste0('../output/figures_and_tables/', 'treatmentvar_ml.pdf'),
       width = 20, height = 10, units = "cm", plot = pl2)
ggsave(paste0('../output/figures_and_tables/', 'treatmentvar_ml.png'),
       width = 20, height = 10, units = "cm", plot = pl2)

