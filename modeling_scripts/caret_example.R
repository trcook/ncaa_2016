library(caret)
library(DAMisc)
library(splines)
library(caretEnsemble)

#Get the data:
itrain <- read.csv("C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\i_train.csv")

############ BEGIN RECODING

#Calculate Score differential
itrain$wscorediff <- itrain$wscore-itrain$lscore
itrain$lscorediff <- itrain$lscore-itrain$wscore

#Stack data so that it is un-classified again - creates symmetries later but we will ignor those
l.itrain <- itrain[, grepl("^l", names(itrain))] #Get losing team 
w.itrain <- itrain[, grepl("^w", names(itrain))] #Get winning team
names(l.itrain) <- substr(names(l.itrain), start=2, stop=10) #Remove the l's from the names
names(w.itrain) <- substr(names(w.itrain), start=2, stop=10) #Remove the l's from the names
l.itrain$lose <- 1
w.itrain$lose <- 0
w.itrain$loc <- NULL

#Get the non-duplicated columns vis-a-vis winning/losing
n.itrain <- itrain[, !grepl("^w|^l", names(itrain)) ]
n.itrain$wloc <- itrain$wloc

#RE-Create the data - now stacked
itrain.dur <- rbind(w.itrain, l.itrain)
itrain.dur$oppteam <- c(itrain$lteam, itrain$wteam) #add in the opposing team for strength of sched scores
itrain.dur <- cbind(itrain.dur, n.itrain)

#Create one feature based on season performance

#Factor season
fseason <- as.factor(itrain.dur$season)
sp.itrain.dur <- split(itrain.dur, fseason)

#calculate survival estimates for each team - likelihood of surviving a game
sp.itrain.dur <- lapply(sp.itrain.dur, function(x) btscs(x, "lose", "daynum", "team") )
itrain.dur <- do.call("rbind", sp.itrain.dur)

time.dep <- glm(lose~bs(spell, df=5)+as.factor(season), data=itrain.dur, na.action=na.exclude)
itrain.dur$team.survscores <- predict(time.dep)
team.survscores <- aggregate(team.survscores~team+season, mean, data=itrain.dur); itrain.dur$team.survscores <-NULL #Probability of losing 
itrain.dur <- merge(itrain.dur, team.survscores, by=c("team", "season"))
names(team.survscores)[3] <- "opp.survscores"
itrain.dur <- merge(itrain.dur, team.survscores, by.x=c("oppteam", "season"), by.y=c("team", "season"))


#need outcome to be factor
itrain.dur$win <- factor(itrain.dur$lose, labels=c("win", "lose"))
########################## END RECODING 


####################################### START DATA RECODING

#Load and re-code the validation data
ivalidate <- read.csv("C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\g_test.csv") # This is the tournament outcomes 2011-2014
#Get score differential
ivalidate$wscorediff <- ivalidate$wscore-ivalidate$lscore
ivalidate$lscorediff <- ivalidate$lscore-ivalidate$wscore

#Stack data so that it is team-game
l.ivalidate <- ivalidate[, grepl("^l", names(ivalidate))] #Get losing team 
w.ivalidate <- ivalidate[, grepl("^w", names(ivalidate))] #Get winning team
names(l.ivalidate) <- substr(names(l.ivalidate), start=2, stop=10) #Remove the l's from the names
names(w.ivalidate) <- substr(names(w.ivalidate), start=2, stop=10) #Remove the l's from the names
l.ivalidate$lose <- 1
w.ivalidate$lose <- 0
w.ivalidate$loc <- NULL

#Get the non-duplicated columns vis-a-vis winning/losing
n.ivalidate <- ivalidate[, !grepl("^w|^l", names(ivalidate)) ]
n.ivalidate$wloc <- ivalidate$wloc

#RE-Create the data - now stacked
oppteam <- c(ivalidate$lteam, ivalidate$wteam) #add in the opposing team for strength of sched scores
ivalidate <- rbind(w.ivalidate, l.ivalidate)
ivalidate <- cbind(ivalidate, n.ivalidate)
ivalidate$oppteam <- oppteam

#Survival scores
names(team.survscores)[3] <- "team.survscores"
ivalidate <- merge(ivalidate, team.survscores, by=c("team", "season"))
names(team.survscores)[3] <- "opp.survscores"
ivalidate <- merge(ivalidate, team.survscores, by.x=c("oppteam", "season"), by.y=c("team", "season"))

#need outcome to be factor
ivalidate$win <- factor(ivalidate$lose, labels=c("win", "lose"))

############### END DATA RECODING

################ START TRAINING

my_control <- trainControl(
  method='boot',
  number=5,
  savePredictions=TRUE,
  classProbs=TRUE,
  index=createResample(ivalidate$win, 5),
  summaryFunction=twoClassSummary
)

models <- caretList(
  win~., data=ivalidate[,grepl("win|team.survscores|opp.survscores", names(ivalidate))],
  trControl=my_control,
  methodList=c('bayesglm', 'dnn')#'knn', , 'qrnn'
)

#This will stack the models into an ensemble using a greedy stepwise algorithm
stack <- caretStack(models, method='glm')



#Make the predictions
preds <- predict(stack, type="prob", newdata = ivalidate[,grepl("win|team.survscores|opp.survscores", names(ivalidate))])[,2]
df <- data.frame(preds, realscore=ivalidate$scorediff, season=ivalidate$season)
qplot(preds, realscore, data=df, xlab="Prediction", ylab="Real Margin") + geom_smooth(method="loess")

############### END VALIDATION 

############## START CREATE PREDICTIONS FOR EVERY MATCH-UP FOR STAGE 1

df <- read.csv("C:\\Users\\wombat\\Downloads\\sample_submission.csv")
df$matchups <- gsub("^[0-9]{4}_", "", df$id)
df$oppteam <- gsub("^[0-9]{4}_", "", df$matchups)
df$team <- gsub("_[0-9]{4}", "", df$matchups)
df$season <- gsub("_[0-9]{4}_[0-9]{4}", "", df$id)

#Survival scores
names(team.survscores)[3] <- "team.survscores"
df <- merge(df, team.survscores, by=c("team", "season"))
names(team.survscores)[3] <- "opp.survscores"
df <- merge(df, team.survscores, by.x=c("oppteam", "season"), by.y=c("team", "season"))

preds <- predict(stack, type="prob", newdata = df[,grepl("team.survscores|opp.survscores", names(df))])[,1]

finaldf <- data.frame(id=df$id, pred=preds)
write.csv(finaldf, "C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\030112015_1.csv", row.names=F)
