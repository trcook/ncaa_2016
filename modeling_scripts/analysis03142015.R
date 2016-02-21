#Notes: need to add historical rpi and SOS to train, test, and validation
# Set up for 2015


################################################

library(caret)
library(DAMisc)
library(splines)
library(caretEnsemble)
library(foreign)
library(sna)
library(network)

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

#Split again
avdat <- aggregate(cbind(scorediff, fgm, fga, fgm3, fga3, ftm, fta, or, dr, ast, to, stl, blk, pf)~team+season, mean, data=itrain.dur)
fseason <- as.factor(avdat$season)
avdat <- split(avdat, fseason)
library(psych)
#Do factor analysis to get the power scores
pow <- lapply(avdat, function(x) fa(x[,!grepl("team|season", names(x))], nfactors=2, fm="gls"))
pow <- lapply(pow, function(x) x$scores[,c(1,2)])
avdat <- unsplit(avdat, fseason)
avdat$pow1 <- unsplit(lapply(pow, function(x) x[,1]), fseason)
avdat$pow2 <- unsplit(lapply(pow, function(x) x[,2]), fseason)
team.powscores1 <- data.frame(team.powscores1 = avdat$pow1, team=avdat$team, season=avdat$season)
team.powscores2 <- data.frame(team.powscores2 = avdat$pow2, team=avdat$team, season=avdat$season)

#Calculate RPI
#(0.25)*(WP) + (0.50)*(OWP) + (0.25)*(OOWP) - team, opponent, opponent's opponents
itrain.dur$winper <- itrain.dur$scorediff>0
espn <- aggregate(winper~team+season, mean, data=itrain.dur)
espnlastq <- aggregate(winper~team+season, mean, data=itrain.dur[itrain.dur$daynum>100, ]); names(espnlastq)[3] <- "winperlastq"


# Calculate Bonacich centrality scores by team and season
#sp.itrain.dur <- itrain.dur[which(itrain.dur$winper==T), c("season", "team", "oppteam")]
#fseason <- as.factor(sp.itrain.dur$season)
#sp.itrain.dur$team <- as.character(sp.itrain.dur$team)
#sp.itrain.dur$oppteam <- as.character(sp.itrain.dur$oppteam)
#sp.itrain.dur <- split(sp.itrain.dur, fseason)
#el <- lapply(sp.itrain.dur, function(x) network(unique(x[,c("team", "oppteam")]), directed=T, matrix.type="edgelist"))
#bp <- lapply(el, function(x) bonpow(x, exponent=2.25))
#vnames <- lapply(bp, function(x) names(x))
#seasons <- list()
#for(i in 1:length(bp)){
#  seasons[[i]] <- rep(names(bp)[i], length(bp[[i]]) )
#}
#bp <- data.frame(team=unlist(vnames), bp = unlist(bp), season=unlist(seasons))

#Load and re-code the validation data
ivalidate <- read.csv("C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\i_validate.csv")
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

ivalidate <- merge(ivalidate, team.powscores1, by=c("team", "season"))
ivalidate <- merge(ivalidate, team.powscores2, by=c("team", "season"))
names(ivalidate)[27] <- "powscore1"
names(ivalidate)[28] <- "powscore2"
ivalidate <- merge(ivalidate, team.powscores1, by.x=c("oppteam", "season"), by.y=c("team", "season"))
ivalidate <- merge(ivalidate, team.powscores2, by.x=c("oppteam", "season"), by.y=c("team", "season"))
names(ivalidate)[29] <- "opp.powscore1"
names(ivalidate)[30] <- "opp.powscore2"

ordinals <- read.csv("C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\massey_ordinals.csv")
ordinals <- aggregate(orank~team+season, median, data=ordinals)
ivalidate <- merge(ivalidate, ordinals, by=c("team", "season"))
ivalidate <- merge(ivalidate, ordinals, by.x=c("oppteam", "season"), by.y=c("team", "season"))

#Get win percentages
ivalidate <- merge(ivalidate, espn,  by.x=c("team", "season"), by.y=c("team", "season"))
ivalidate <- merge(ivalidate, espn,  by.x=c("oppteam", "season"), by.y=c("team", "season"))


#Get win percentage of last quarter of season
ivalidate <- merge(ivalidate, espnlastq,  by.x=c("team", "season"), by.y=c("team", "season"))
ivalidate <- merge(ivalidate, espnlastq,  by.x=c("oppteam", "season"), by.y=c("team", "season"))

#Bonacich
#ivalidate <- merge(ivalidate, bp,  by.x=c("team", "season"), by.y=c("team", "season"))
#ivalidate <- merge(ivalidate, bp,  by.x=c("oppteam", "season"), by.y=c("team", "season"))

########################## END RECODING 

#simplmod <- lmer(scorediff~team.survscores+opp.survscores+powscore1+powscore2+opp.powscore1+opp.powscore2+(1|team)+(1|oppteam), data#=ivalidate)
#simplmod <- lm(scorediff~team.survscores+opp.survscores+powscore1+powscore2+opp.powscore1+opp.powscore2, data=ivalidate)

######################### START TRAINING

my_control <- trainControl(
  method='repeatedcv',
  repeats=5,
  savePredictions=TRUE,
  classProbs=TRUE,
  summaryFunction=twoClassSummary
)

models <- caretList(
  win~., data=ivalidate[,grepl("win|survscores|powscore|orank|winper", names(ivalidate))],
  trControl=my_control,
  methodList=c('bagFDA', 'nnet', 'ada', 'bayesglm', 'svmPoly', 'rf', 'knn', 'svmLinear', 'gbm')#'knn', , 'qrnn', 'svmPoly', 'AdaBag'
)



#This will stack the models into an ensemble using a greedy stepwise algorithm
stack <- caretStack(models, method='glm')
greedy <- caretEnsemble(models, iter=1000L)
####################################### END TRAINING 

####################################### START DATA RECODING

#Load and re-code the validation data
ivalidate <- read.csv("C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\g_test.csv")
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

ivalidate <- merge(ivalidate, team.powscores1, by=c("team", "season"))
ivalidate <- merge(ivalidate, team.powscores2, by=c("team", "season"))
names(ivalidate)[27] <- "powscore1"
names(ivalidate)[28] <- "powscore2"
ivalidate <- merge(ivalidate, team.powscores1, by.x=c("oppteam", "season"), by.y=c("team", "season"))
ivalidate <- merge(ivalidate, team.powscores2, by.x=c("oppteam", "season"), by.y=c("team", "season"))
names(ivalidate)[29] <- "opp.powscore1"
names(ivalidate)[30] <- "opp.powscore2"

#Get rankings
ivalidate <- merge(ivalidate, ordinals, by=c("team", "season"))
ivalidate <- merge(ivalidate, ordinals, by.x=c("oppteam", "season"), by.y=c("team", "season"))

#Get win percentages
ivalidate <- merge(ivalidate, espn,  by.x=c("team", "season"), by.y=c("team", "season"))
ivalidate <- merge(ivalidate, espn,  by.x=c("oppteam", "season"), by.y=c("team", "season"))


#Get win percentage of last quarter of season
ivalidate <- merge(ivalidate, espnlastq,  by.x=c("team", "season"), by.y=c("team", "season"))
ivalidate <- merge(ivalidate, espnlastq,  by.x=c("oppteam", "season"), by.y=c("team", "season"))

#Bonacich
#ivalidate <- merge(ivalidate, bp,  by.x=c("team", "season"), by.y=c("team", "season"))
#ivalidate <- merge(ivalidate, bp,  by.x=c("oppteam", "season"), by.y=c("team", "season"))


############### END DATA RECODING

################ START VALIDATION

#Make the predictions
preds <- predict(stack, type="prob", newdata = ivalidate[ ,grepl("win|survscores|powscore|orank|winper", names(ivalidate))])[,1]
df <- data.frame(preds=preds[which(ivalidate$daynum>135)], realscore=ivalidate$scorediff[which(ivalidate$daynum>135)], season=ivalidate$season[which(ivalidate$daynum>135)])
qplot(preds, realscore, data=df, xlab="Prediction", ylab="Real Margin") + geom_smooth(method="loess")
df$win <- 1*(df$realscore>0)
df$pwin <- 1*(df$preds>=.5)
logloss <- sum((df$win*log(df$preds) + (1-df$win)*log(1-df$preds))  * (1/nrow(df)) ); logloss
accuracy <- sum(df$win==df$pwin)/nrow(df) #Make 67% accuracy

#Log loss

CappedBinomialDeviance <- function(a, p) {
  if (length(a) !=  length(p)) stop("Actual and Predicted need to be equal lengths!")
  p_capped <- pmin(0.99, p)
  p_capped <- pmax(0.01, p_capped)
  -sum(a * log(p_capped) + (1 - a) * log(1 - p_capped)) / length(a)
}
CappedBinomialDeviance(df$win, df$preds)
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

#power scores
df <- merge(df, team.powscores1, by=c("team", "season"))
df <- merge(df, team.powscores2, by=c("team", "season"))
names(df)[9] <- "powscore1"
names(df)[10] <- "powscore2"
df <- merge(df, team.powscores1, by.x=c("oppteam", "season"), by.y=c("team", "season"))
df <- merge(df, team.powscores2, by.x=c("oppteam", "season"), by.y=c("team", "season"))
names(df)[11] <- "opp.powscore1"
names(df)[12] <- "opp.powscore2"

df <- merge(df, ordinals, by=c("team", "season"))
df <- merge(df, ordinals, by.x=c("oppteam", "season"), by.y=c("team", "season"))


#Get win percentages
df <- merge(df, espn,  by.x=c("team", "season"), by.y=c("team", "season"))
df <- merge(df, espn,  by.x=c("oppteam", "season"), by.y=c("team", "season"))


#Get win percentage of last quarter of season
df <- merge(df, espnlastq,  by.x=c("team", "season"), by.y=c("team", "season"))
df <- merge(df, espnlastq,  by.x=c("oppteam", "season"), by.y=c("team", "season"))

#Bonacich
#df <- merge(df, bp,  by.x=c("team", "season"), by.y=c("team", "season"))
#df <- merge(df, bp,  by.x=c("oppteam", "season"), by.y=c("team", "season"))


preds <- predict(stack, type="prob", newdata = df[,grepl("win|survscores|powscore|orank|winper", names(df))])[,1]

finaldf <- data.frame(id=df$id, pred=preds)
write.csv(finaldf, "C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\030112015_8.csv", row.names=F)
