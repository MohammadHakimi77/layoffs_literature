
rm(list=ls()) 
library(rstudioapi)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("Fun_FDID.R")

data = read.csv("GDP.csv", sep=",", header = TRUE)

t=dim(data)[1]
no_control=dim(data)[2]-1
control_ID=1:no_control
t1=44           # t1 is the pretreatment sample size
y=data[,1]
y1=data[1:t1,1]
y2=data[(t1+1):t,1]

x=data[,2:dim(data)[2]]

FDID<-FDID_fun(no_control,control_ID,x,y1,y2,t1,t)
FDID$select
FDID$num_c
FDID$select[1:FDID$num_c]
FDID$ATT_FDID
FDID$ATT_FDID_per
FDID$R2_FDID

yhat=c(FDID$y1_hat_FDID,FDID$y2_hat_FDID)
time=1:t

pdf("HK_GDP_FDID.pdf")
plot(time,y,type='l',lty=1,xlim=c(0,t),xlab="Time (in quarters)",ylab="HK GDP growth rate") # plot actual
lines(time,yhat,col='blue',lty=2) # plot FDID
abline(v=t1) 

legend(min(time),1*max(y),legend=c("Actual","Forward DID"), col=c("black","blue"),
       lty=c(1,2), ncol=1)

dev.off()

png("HK_GDP_FDID.png")
plot(time,y,type='l',lty=1,xlim=c(0,t),xlab="Time (in quarters)",ylab="HK GDP growth rate") # plot actual
lines(time,yhat,col='blue',lty=2) # plot FDID
abline(v=t1) 

legend(min(time),1*max(y),legend=c("Actual","Forward DID"), col=c("black","blue"),
       lty=c(1,2), ncol=1)

dev.off()




setEPS()
postscript("HK_GDP_FDID.eps")
plot(time,y,type='l',lty=1,xlim=c(0,t),xlab="Time (in quarters)",ylab="HK GDP growth rate") # plot actual
lines(time,yhat,col='blue',lty=2) # plot FDID
abline(v=t1)  

legend(min(time),1*max(y),legend=c("Actual","Forward DID"), col=c("black","blue"),
       lty=c(1,2), ncol=1)

dev.off()
