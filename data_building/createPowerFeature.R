#Create power scores using partial least squares

library(caret)
library(reshape)

#setwd("/Volumes/TINY CRYPT/papers/Personal/NCAA/2016 Kaggle Data/march-machine-learning-mania-2016-v1")

#Define paths and file names
#kaggle.submission.file <- "SampleSubmission.csv"
#season.file <- "RegularSeasonDetailedResults.csv"
#tourney.file <- "TourneyCompactResults.csv"
#seasons <- "2005-2016"

#Define training period for features
#first.training.season <- 2005
#last.training.season <- 2016

makeConformedFeature <- function(df, code=1, features){ #this function fixes variables to conform to new data structure
  for(i in 1:length(features)){
    df$Wnewfeature <- ifelse(df$code==code, df[, paste("W",features[i], sep="")], df[,paste("L",features[i], sep="")])  
    df$Lnewfeature <- ifelse(df$code==code, df[, paste("L",features[i], sep="")], df[,paste("W",features[i], sep="")]) 
    df <- rename(df, c(Wnewfeature = paste("Team1", features[i], sep=""), Lnewfeature = paste("Team2", features[i], sep="")))
    
    df[, paste("L",features[i], sep="")] <- df[, paste("W",features[i], sep="")] <- NULL #Remove the old features once created
  }
  return(df)
}


makeDifferentialFeatures <- function(df, features){ #this function fixes variables to conform to new data structure
  for(i in 1:length(features)){
    df$newfeature <- df[, paste("Team1",features[i], sep="")] - df[, paste("Team2",features[i], sep="")]
    df <- rename(df, c(newfeature = paste("D", features[i], sep="")))
  }
  return(df)
}


createPowerScores <- function(season.file, first.season=first.training.season, last.season=last.training.season){
  
  ### MOSTLY BOILERPLATE HERE
  df <- read.csv(season.file)
  #get the correct seasons
  df <- df[ which(df$Season >= first.season & df$Season <= last.season), ]
  #the data structure has no variance because it is focused on the outcome, so re-order columns according to team number rather than game outcome
  df$Team1 <- apply(df[, c("Wteam", "Lteam")], 1, function(x) x[which.min(x)] ) #define team 1 
  df$Team2 <- apply(df[, c("Wteam", "Lteam")], 1, function(x) x[which.max(x)] ) #define team 2
  df$code <- apply(df[, c("Wteam", "Lteam")], 1, function(x) which.min(x) )
  df$Wteam <- df$Lteam <- NULL #remove these columns
  
  #create conformed features that will be important for the power score determination
  features <- gsub("W", "", names(df[, grepl("^W", names(df))]) ) #this is just all features
  features <- features[!grepl("loc|fgm", features)] #remove two problematic features
  df <- makeConformedFeature(df, code=1, features=features) #make features appropriate for new structure

  df <- makeDifferentialFeatures(df, features=features) #make differential features for estimation
  
  df$powerScore <- NA
  
  for(i in 1:length(unique(df$Season))){
    mod <- plsr(Dscore~., data=df[ df$Season %in% unique(df$Season)[i], grep("^D", names(df))],  ncomp=1)
    df$powerScore[df$Season %in% unique(df$Season)[i]] <- predict(mod)
  }
  
  #finalize the feature    
  team.powscores <- aggregate(powerScore~Team1+Season, median, data=df)#Probability of losing 
  names(team.powscores)[1] <- "Team"
  
  return(team.powscores)
}

##############

#

team.powscores<-createPowerScores(season.file,first.season = options('first.training.season')[[1]],last.season = options('last.validation.season')[[1]])

#if saving to load as feature:
#team.powscores <- createPowerScores(season.file, first.season = 1995, last.season = 2016)
#saveRDS(team.powscores, "~/Google Drive/NCAA Team Stuff/NCAA/2016_competition/data_2016_specific/other_data/powerScore.rds")
