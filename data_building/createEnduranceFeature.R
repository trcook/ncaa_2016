library(caret)
library(reshape)
library(parallel)
library(DAMisc)
library(splines)
library(lme4)
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
  
  #Get consecutive game number for spell variable
  x <- x[order(x$Daynum), ]
  x$gamenum <- order(x$Daynum) #get the number of games played so far in the season
  
  if(!is.null(x)){
  #Get number of days since last game
  if(dim(x)[1] >= 3){
  n <- length(x$Daynum)
  x$days.since.last.game <- x$Daynum - c(NA, x$Daynum[1:(n-1)])
    }
  }
  if(dim(x)[1] < 3){
    x$days.since.last.game <- NA
  }
  
  #Remove teams that play less than 3 games
  if(dim(x)[1] >= 3){ 
    x <- btscs(x, event="lose", tvar="gamenum", csunit="Team1", pad.ts = F)
  }
  if(dim(x)[1] < 3){
    x$orig_order <- NA
    x$spell <- 0
  }
  return(x)
}


createEnduranceScores <- function(season.file, first.season=first.training.season, last.season=last.training.season){
	df<-season.file
  # df <- read.csv(season.file)
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

  #calculate survival estimates for each team - likelihood of surviving a game
  itrain.dur <- do.call("rbind", sp.itrain.dur)
  itrain.dur$days.since.last.game[is.na(itrain.dur$days.since.last.game)] <- mean(itrain.dur$days.since.last.game, na.rm=T)
  
  time.dep <- glmer(lose~bs(spell, df=3)+(1|Team1)+(1|days.since.last.game)+(1|Team1ast)+(1|Team1to)+(1|Team1stl), data=itrain.dur, family=binomial(link="probit"), na.action=na.exclude)
  itrain.dur$team.survscores <- predict(time.dep, type="response")
  team.survscores <- aggregate(team.survscores~Team1+Season, median, data=itrain.dur)#Probability of losing 
  names(team.survscores)[1] <- "Team"
  
  return(team.survscores)
}

##############

#

#df <- createEnduranceScores(season.file)


team.survscores<-createEnduranceScores(season.file,first.season = options('first.training.season')[[1]],last.season = options('last.validation.season')[[1]])
