#----caret 2016--------------------------------------------------------------
#
#      The purpose of this script is to create a caret ensamble model that is
#      embedded in the pipeline framework. It will expect datasets for training
#      (training_data), and validation(validation_data)
#
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

require(caret)
require(caretEnsemble)
require(doSNOW)
require(parallel)
require(knitr)

## ----set training control-----------------------------------------------------
tc<-trainControl(method = 'cv',number = 2,classProbs=TRUE)

## ----set tunelist configuration---------------------------------------------------
#' Here is where you add new models and params for model training
tl=list(
	rf=caretModelSpec(method = 'RRF'),
	bagFDA=caretModelSpec(method='fda',
											tuneGrid=expand.grid(degree=c(1,2,3),nprune=c(11,20,30))),
		 adabag=caretModelSpec(method='AdaBag')
)

## ---- run ensamble model ------

train_features=c("Season", "Team1Seed", "Team2Seed", "Team1team.survscores", 
"Team2team.survscores", "Team1RPI", "Team2RPI", "Team1SOS", "Team2SOS", 
"Team1orank", "Team2orank", "Team1pagerank", "Team2pagerank", 
"Team1powerScore", "Team2powerScore")


model_list <- caretList(
	y=training_data$win,x=training_data[,train_features,with=F],
  tuneList=tl,
  trControl = tc
  )

model<-caretEnsemble(model_list)