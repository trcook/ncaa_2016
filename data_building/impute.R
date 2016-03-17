# this file imputes as needed. schedule for after building script in config.

require(Amelia)


idvars1<-unique(c(grep(names(validation_data),pattern='Team2.*',value = T),"Team1score","Team2score",'win','Numot','Team2','Team1win'))
idvars2<-unique(c(grep(names(validation_data),pattern='Team1.*',value = T),"Team1score","Team2score",'win','Numot','Team1'))
impvars1<-setdiff(names(tourneydata),idvars1)
impvars2<-setdiff(names(tourneydata),idvars2)

	# unique(c(gsub(x=idvars1,pattern='2',replacement = '1'),'Team2',"Team1score","Team2score",'win','Numot','Team1'))

tourney_imputed1<-amelia(
	x=tourneydata,
	m=1,
	idvars=idvars1,
	splinetime=3,
	ts="Season",
	cs="Team1",
	incheck=TRUE
)

tourney1<- tourney_imputed1$imputations$imp1

tourney_imputed2<-amelia(
	x=tourneydata,
	m=1,
	idvars=idvars2,
	splinetime=3,
	ts="Season",
	cs="Team2",
	incheck=TRUE
)

# tourney_imputed<-do.call(amelia,amelia_prep2)
tourney2<-tourney_imputed2$imputations$imp1
tourney2[,impvars1]<-tourney1[,impvars1]
test_train_validate_split(dat = tourney2)
