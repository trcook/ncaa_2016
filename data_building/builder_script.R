library(reshape)
#Define training period for features
first.training.season <- 2005
last.training.season <- 2011

#Get the season outcomes data and recode so that it has a more useable structure
getTourneyData <- function(tourney.file, first.season=options("first.training.season"), last.season=options("last.training.season")){
  # tourney.file <- read.csv(tourney.file)
  #get the correct seasons
  tourney.file <- tourney.file[ which(tourney.file$Season >= first.season & tourney.file$Season <= last.season), ]
  
  #the data structure has no variance because it is focused on the outcome, so re-order columns according to team number rather than game outcome
  tourney.file$Team1 <- apply(tourney.file[, c("Wteam", "Lteam")], 1, function(x) x[which.min(x)] ) #define team 1 
  tourney.file$Team2 <- apply(tourney.file[, c("Wteam", "Lteam")], 1, function(x) x[which.max(x)] ) #define team 2
  tourney.file$code <- apply(tourney.file[, c("Wteam", "Lteam")], 1, function(x) which.min(x) )
  tourney.file$Team1score <- ifelse(tourney.file$code==1, tourney.file$Wscore, tourney.file$Lscore) 
  tourney.file$Team2score <- ifelse(tourney.file$code==1, tourney.file$Lscore, tourney.file$Wscore)
  tourney.file$win <- as.factor(ifelse(tourney.file$Team1score>tourney.file$Team2score, "win", "lose"))
  tourney.file <- tourney.file[, c("Season", "Daynum", "Team1", "Team2", "Team1score", "Team2score", "win", "Numot")]
  return(tourney.file)
}

tourneydata <- getTourneyData(tourney.file)

#get feature and merge it into the desired tourney training/testing file for analysis
getFeature <- function(feature_df, tourneydata, featurename=featurename){
  #all features can be assumed to have the Kaggle Team ID's and Seasons
  feature<-feature_df
  featurename.regex <- paste("^", featurename, sep="")
  #Merge and assign feature names by team matchup
  
  df <- merge(tourneydata, feature, by.x=c("Team1", "Season"), by.y=c("Team", "Season"))
  names(df)[grepl(featurename.regex, names(df))] <- paste("Team1", featurename, sep="")
  df <- merge(df, feature, by.x=c("Team2", "Season"), by.y=c("Team", "Season"))
  names(df)[grepl(featurename.regex, names(df))] <- paste("Team2", featurename, sep="")
  return(df)
}



getFeature_list<-function(x){
# get features as appropriate
for(i in seq_along(x)){
	feat_name=names(x)[[i]]
	feat_df = eval(as.name(feat_name))
	assign("tourneydata",getFeature(feature_df = feat_df,tourneydata = tourneydata,featurename = feat_name),envir = .GlobalEnv)
	}
}
