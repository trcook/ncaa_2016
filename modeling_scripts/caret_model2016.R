#----caret 2016--------------------------------------------------------------
#
#      The purpose of this script is to create a caret ensamble model that is
#      embedded in the pipeline framework. It will expect datasets for training
#      (training_data), and validation(validation_data)
#
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

require(caret)
require(caretEnsemble)
require(caret)
require(caretEnsemble)
#require(h2o)
require(doSNOW)
require(parallel)
require(knitr)

## ----set training control-----------------------------------------------------
tc<-trainControl(method = 'cv',number = 2)

## ----set tunelist configuration---------------------------------------------------

tl=list(
	rf=caretModelSpec(method = 'RRF'),
		bagFDA=caretModelSpec(method='fda'),
													# tuneGrid=expand.grid(degree=c(1,2,3),nprune=c(1,2,3))),
		adabag=caretModelSpec(method='AdaBag')
		
#    ,dnn=caretModelSpec(method='dnn',
#     tuneGrid=expand.grid(layer1=c(3),layer2=c(5),layer3=c(2),
#       hidden_dropout=c(.1,.2,.3),visible_dropout=c(.1,.2,.3)))
#    ,glmboost=caretModelSpec(
#     method='glmboost',tuneGrid=expand.grid(prune=T,mstop=c(100,200,300)) )
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
#,methodList=c('cubist')
  )

# train(form=formula(Team1win~.,data=training_data), data=training_data[,train_features,with=F],method='rf')
