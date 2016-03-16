# this file imputes as needed. schedule for after building script in config.

require(Amelia)


idvars1<-c(grep(names(validation_data),pattern='Team2.*',value = T),"Team1score","Team2score",'win','Numot','Team1')
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

test_train_validate_split(dat = tourney2)
