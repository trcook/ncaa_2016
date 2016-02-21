# this should already be loaded
ncaa_wd<-partial(file.path,options("path_to_NCAA"))

dat[,gameID:=.I]
setkey(dat,gameID)
dat[,team_order:=rbinom(n=.N,1,.5)]
games1_2<-dat[team_order==1,gameID]
games2_1<-dat[team_order==0,gameID]




wvars<-grep(names(dat),pattern='^w',ignore.case=T,value=T)
lvars<-grep(names(dat),pattern='^l',ignore.case=T,value=T)

tmp<-data.table(melt(dat,id='gameID'))

games1_2w<-data.table(games1_2,rep(t(wvars),length(games1_2)))
games1_2l<-data.table(games1_2,rep(t(lvars),length(games1_2)))
games2_1w<-data.table(games2_1,rep(t(wvars),length(games2_1)))
games2_1l<-data.table(games2_1,rep(t(lvars),length(games2_1)))

setkey(tmp,gameID,variable)
tmp[games1_2w,variable:=paste0(substring(variable,2,999),'_1')]
setkey(tmp,gameID,variable)
tmp[games1_2l,variable:=paste0(substring(variable,2,999),'_2')]
setkey(tmp,gameID,variable)
tmp[games2_1w,variable:=paste0(substring(variable,2,999),'_1')]
setkey(tmp,gameID,variable)
tmp[games2_1l,variable:=paste0(substring(variable,2,999),'_2')]



wvars<-grep(names(dat),pattern='^w',ignore.case=T,value=T)

names(dat[])


head(cast(melt(dat,id='game'),game~variable))