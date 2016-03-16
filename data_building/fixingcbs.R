require(data.table)
require(RecordLinkage)
require(plyr)
m<-fread(ncaa_wd("2016_competition/data_2016_specific/other_data/CBS_revised.csv"))
setnames(m,'school','name')
mnames<-unique(m$name)

sp<-read.csv(ncaa_wd("2016_competition/data_2016_specific/other_data/team_spellings.csv"))


match_key<-data.table(ldply(mnames,function(i){
	match_names<-adist(x=i,y=sp$name_spelling,ignore.case=T)
	min_nam<-min(match_names)
	match_row<-which(match_names==min(match_names))[1]
	match_name<-sp$name_spelling[match_row]
	match_code<-sp$team_id[match_row]
	return(data.frame(name=i,sp_name=match_name,dist=min_nam,team_id=match_code))
	}))
setkey(match_key,name)
setkey(m,name)
m[match_key,team:=team_id]


require(Amelia)
amelia(tourneydata,m=5,idvars = 'Team1')


idvars1<-c(grep(names(tourneydata),pattern='Team2.*',value = T),"Team1score","Team2score",'win','Numot','Team1')
idvars2<-c(unique(gsub(x=idvars1,pattern='2',replacement = '1')),'Team2')

amelia_prep1<-list(
	x=tourneydata,
	m=1,
	idvars=idvars1,
	splinetime=3,
	ts="Season",
	cs="Team1",
	incheck=FALSE
)

tourney_imputed<-do.call(amelia,amelia_prep1)
tourney1<- tourney_imputed$imputations$imp1

amelia_prep2<-list(
	x=tourney1,
	m=1,
	idvars=idvars2,
	splinetime=3,
	ts="Season",
	cs="Team1",
	incheck=FALSE
)

tourney_imputed<-do.call(amelia,amelia_prep2)
tourney2<-tourney_imputed$imputations$imp1

