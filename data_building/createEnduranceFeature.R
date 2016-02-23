library(caret)
library(reshape)
library(parallel)
library(DAMisc)
library(splines)
#setwd("/Volumes/TINY CRYPT/papers/Personal/NCAA/2016 Kaggle Data/march-machine-learning-mania-2016-v1")

#Define paths and file names
#kaggle.submission.file <- "SampleSubmission.csv"
#season.file <- "RegularSeasonDetailedResults.csv"
#tourney.file <- "TourneyCompactResults.csv"
#seasons <- "2005-2016"

#Define training period for features
#first.training.season <- 2005
#last.training.season <- 2016

#Get the game number for each game
daynum.funk <- function(x){
  x <- x[order(x$Daynum), ]
  x$gamenum <- order(x$Daynum) #get the number of games played so far in the season
  if(dim(x)[1]<3){x <- NULL}
  return(x)
}


createEnduranceScores <- function(season.file, first.season=first.training.season, last.season=last.training.season){
  df <- read.csv(season.file)
  #get the correct seasons
  df <- df[ which(df$Season >= first.season & df$Season <= last.season), ]
  #the data structure has no variance because it is focused on the outcome, so re-order columns according to team number rather than game outcome
  df$Team1 <- apply(df[, c("Wteam", "Lteam")], 1, function(x) x[which.min(x)] ) #define team 1 
  df$Team2 <- apply(df[, c("Wteam", "Lteam")], 1, function(x) x[which.max(x)] ) #define team 2
  df$code <- apply(df[, c("Wteam", "Lteam")], 1, function(x) which.min(x) )
  df$Team1score <- ifelse(df$code==1, df$Wscore, df$Lscore) 
  df$Team2score <- ifelse(df$code==1, df$Lscore, df$Wscore)
  df$Team1ast <- ifelse(df$code==1, df$Wast, df$Last) 
  df$Team1to <- ifelse(df$code==1, df$Wto, df$Lto) 
  df$Team1stl <- ifelse(df$code==1, df$Wstl, df$Lstl) 
  df$lose <- ifelse(df$Team1score<df$Team2score, 1, 0)
  df <- df[, c("Season", "Daynum", "Team1", "Team2", "Team1score", "Team2score", "Team1ast", "Team1to", "Team1stl", "lose", "Numot")]
  
  fseason <- as.factor(paste(df$Team1, df$Season))
  sp.itrain.dur <- split(df, fseason)
  #create game number variable
  sp.itrain.dur <- lapply(sp.itrain.dur, daynum.funk)
  sp.itrain.dur <- sp.itrain.dur[!sapply(sp.itrain.dur, is.null)]
  
  #calculate survival estimates for each team - likelihood of surviving a game
  sp.itrain.dur <- lapply(sp.itrain.dur, function(x) btscs(x, event="lose", tvar="gamenum", csunit="Team1", pad.ts = F) )
  itrain.dur <- do.call("rbind", sp.itrain.dur)
  
  time.dep <- glmer(lose~bs(spell, df=3)+(1|Team1)+(1|Team1ast)+(1|Team1to)+(1|Team1stl), data=itrain.dur, family=binomial(link="probit"), na.action=na.exclude)
  itrain.dur$team.survscores <- predict(time.dep, type="response")
  team.survscores <- aggregate(team.survscores~Team1+Season, median, data=itrain.dur)#Probability of losing 
  names(team.survscores)[1] <- "Team"
  
  return(team.survscores)
}

##############

#df <- getSeasonData(season.file)


