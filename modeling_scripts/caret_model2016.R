#----caret 2016--------------------------------------------------------------
#
#      The purpose of this script is to create a caret ensamble model that is
#      embedded in the pipeline framework. It will expect datasets for training
#      (training_data), and validation(validation_data)
#
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

require(caret)
require(caretEnsemble)
#require(doSNOW)
require(parallel)
require(knitr)

#index <- which(training_data$Season %in% 2003:2010) #set the training index explicitly

## ----set training control-----------------------------------------------------
tc<-trainControl(method = 'cv',number = 2,classProbs=TRUE,  summaryFunction = multiClassSummary, savePredictions=TRUE) 

## ----set tunelist configuration---------------------------------------------------
#' Here is where you add new models and params for model training
tl=list(
  rf=caretModelSpec(method = 'RRF'),
  bagFDA=caretModelSpec(method='fda', metric="logLoss"),
  #tuneGrid=expand.grid(degree=c(1,2,3),nprune=c(1,2,3)))#,
  adabag=caretModelSpec(method='AdaBag', metric="logLoss"), 
  ada=caretModelSpec(method='ada', metric="logLoss"),
  lda=caretModelSpec(method='lda', metric="logLoss"),
  nb=caretModelSpec(method='nb', metric="logLoss"),
  gbm=caretModelSpec(method='gbm', metric="logLoss"),
  evtree=caretModelSpec(method='evtree', metric="logLoss")
)

## ---- run ensamble model ------ 

train_features=c("Season", "Daynum", "Team1Seed", "Team2Seed", "Team1team.survscores", 
                 "Team2team.survscores", "Team1RPI", "Team2RPI", "Team1SOS", "Team2SOS", "Team1CBSNCSOS","Team2CBSNCSOS",
                 "Team1orank", "Team2orank", "Team1pagerank", "Team2pagerank", "Team1CBSNCRank", "Team2CBSNCRank",
                 "Team1powerScore", "Team2powerScore")


model_list <- caretList(
  y=training_data$win,x=training_data[,train_features,with=F],
  tuneList=tl,
  trControl = tc
)

#model<-caretEnsemble(model_list)
model <- caretStack(model_list, method="glm", trControl=trainControl(classProbs=TRUE,  summaryFunction = multiClassSummary, savePredictions=TRUE),  metric="logLoss")


#print out the scores 
showMeScores <- function(model, validation_data){
  predicted <- predict(model, type="raw", newdata=validation_data)
  observed <- validation_data$win
  dat <- data.frame(obs=observed, pred=predicted, lose=predict(model, type="prob", newdata=validation_data)[,1], win=predict(model, type="prob", newdata=validation_data)[,2])
  return(mnLogLoss(dat, lev = c("lose", "win")) )
  #return(multiClassSummary(dat, lev = c("lose", "win"), model=model))
}


