#write a few functions to create training data, get a feature, run a simple model.

library(caret)
library(reshape)
library(parallel)
setwd("/Volumes/TINY CRYPT/papers/Personal/NCAA/2016 Kaggle Data/march-machine-learning-mania-2016-v1")

#Define paths and file names
kaggle.submission.file <- "SampleSubmission.csv"
season.file <- "RegularSeasonDetailedResults.csv"
tourney.file <- "TourneyCompactResults.csv"
seasons <- "2005-2016"

#Define training period for features
first.training.season <- 2005
last.training.season <- 2011

#Get the season outcomes data and recode so that it has a more useable structure
getTourneyData <- function(tourney.file, first.season=first.training.season, last.season=last.training.season){
  df <- read.csv(tourney.file)
  #get the correct seasons
  df <- df[ which(df$Season >= first.season & df$Season <= last.season), ]
  
  #the data structure has no variance because it is focused on the outcome, so re-order columns according to team number rather than game outcome
  df$Team1 <- apply(df[, c("Wteam", "Lteam")], 1, function(x) x[which.min(x)] ) #define team 1 
  df$Team2 <- apply(df[, c("Wteam", "Lteam")], 1, function(x) x[which.max(x)] ) #define team 2
  df$code <- apply(df[, c("Wteam", "Lteam")], 1, function(x) which.min(x) )
  df$Team1score <- ifelse(df$code==1, df$Wscore, df$Lscore) 
  df$Team2score <- ifelse(df$code==1, df$Lscore, df$Wscore)
  df$win <- as.factor(ifelse(df$Team1score>df$Team2score, "win", "lose"))
  df <- df[, c("Season", "Daynum", "Team1", "Team2", "Team1score", "Team2score", "win", "Numot")]
  return(df)
}

tourneydata <- getTourneyData(tourney.file)

#get feature and merge it into the desired tourney training/testing file for analysis
getFeature <- function(feature.path, tourneydata, featurename=featurename){
  #all features can be assumed to have the Kaggle Team ID's and Seasons
  feature <- read.csv(feature.path)
  featurename.regex <- paste("^", featurename, sep="")
  #Merge and assign feature names by team matchup
  df <- merge(tourneydata, feature, by.x=c("Team1", "Season"), by.y=c("Team", "Season"))
  names(df)[grepl(featurename.regex, names(df))] <- paste("Team1", featurename, sep="")
  df <- merge(df, feature, by.x=c("Team2", "Season"), by.y=c("Team", "Season"))
  names(df)[grepl(featurename.regex, names(df))] <- paste("Team2", featurename, sep="")
  return(df)
}

## Basic Example using getFeature
trdata <- getFeature(feature.path="TourneySeeds_feature.csv", tourneydata, featurename="Seed")

#Create a very simple model with the seed feature
cvCtrl <- trainControl(
  method = "repeatedcv",
  repeats = 3,
  classProbs = TRUE,
  savePredictions = T,
  summaryFunction = twoClassSummary) #mnLogLoss
trmod <- train(win~Team1Seed+Team2Seed, method="rf", data=trdata, trControl=cvCtrl)



