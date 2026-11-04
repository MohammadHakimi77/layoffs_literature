# Generate statistics about personalized playlists
library(data.table)

pls <- fread('../../analysis/temp/playlists.csv')

# Mix of personalized playlists
table(pls[recommendation_type=='Fully-personalized recommendations']$name)
pls[recommendation_type=='Fully-personalized recommendations', reclist_type:=as.character(NA)]
pls[recommendation_type=='Fully-personalized recommendations' & grepl('daily', name,ignore.case=T), reclist_type:='Daily mix']
pls[recommendation_type=='Fully-personalized recommendations' & grepl('couvertes|dein mix|descubrimiento|discover', name, ignore.case=T), reclist_type:='Discover weekly']
pls[recommendation_type=='Fully-personalized recommendations' & grepl('2015|2016|2017|2018|2019',name) , reclist_type:='Your Top Songs of 20xx']
pls[recommendation_type=='Fully-personalized recommendations' & is.na(reclist_type), reclist_type:=name]

void<-table(pls[recommendation_type=='Fully-personalized recommendations']$reclist_type)

round(void[order(void,decreasing=T)]/sum(void),2)

nrow(pls[grepl('fully', recommendation_type,ignore.case=T)])
# 1634 personalized playlists.

nrow(pls[grepl('fully|semi|artist', recommendation_type,ignore.case=T)])


