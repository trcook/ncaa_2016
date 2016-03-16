library(reshape)
#Define training period for features

#Get the season outcomes data and recode so that it has a more useable structure
getTourneyData <- function(tourney.file, first.season=options("first.training.season"), last.season=options("last.training.season")){
  # tourney.file <- read.csv(tourney.file)
  #get the correct seasons
  #tourney.file <- tourney.file[ which(tourney.file$Season >= first.season & tourney.file$Season <= last.season), ] # -- moved this functionality to later functions
  #the data structure has no variance because it is focused on the outcome, so re-order columns according to team number rather than game outcome
  tourney.file$Team1 <- apply(tourney.file[, c("Wteam", "Lteam")], 1, function(x) x[which.min(x)] ) #define team 1 
  tourney.file$Team2 <- apply(tourney.file[, c("Wteam", "Lteam")], 1, function(x) x[which.max(x)] ) #define team 2
  tourney.file$code <- apply(tourney.file[, c("Wteam", "Lteam")], 1, function(x) which.min(x) )
  tourney.file$Team1score <- ifelse(tourney.file$code==1, tourney.file$Wscore, tourney.file$Lscore) 
  tourney.file$Team2score <- ifelse(tourney.file$code==1, tourney.file$Lscore, tourney.file$Wscore)
  tourney.file$win <- as.factor(ifelse(tourney.file$Team1score>tourney.file$Team2score, "win", "lose"))
  # I find it difficult to work with factors like this in modeling situations.
  tourney.file$Team1win <-ifelse(tourney.file$Team1score>tourney.file$Team2score, 1, 0)

  
  tourney.file <- tourney.file[, c("Season", "Daynum", "Team1", "Team2", "Team1score", "Team2score", "win","Team1win", "Numot")]
  # now, update with teams for the current tournament
	seeds<-data.table(read.csv(ncaa_wd('2016_competition/data_2016_specific/kaggle_dataset/TourneySeeds.csv')))
	teams2016<-seeds[Season==2016,Team]
	matchups2016<-(cbind(2016,t(combn(teams,2))))
	
	# this makes sure matchups 2016 is equal length to tourneyfile and same names
	num_empty_cols2016<-length(names(tourney.file))-3
	matchups2016<-data.frame(cbind(matchups2016,matrix(nrow=length(matchups2016[,1]),ncol=num_empty_cols2016)))
	names(matchups2016)<-c("Season","Team1","Team2",setdiff(names(tourney.file),c("Season","Team1","Team2")))
	
	# now we rbind
	tourney.file<-rbind(tourney.file,matchups2016)
	
	
	return(tourney.file)
}

#get feature and merge it into the desired tourney training/testing file for analysis
getFeature <- function(feature_df, tourneydata, featurename=featurename){
  #all features can be assumed to have the Kaggle Team ID's and Seasons
  feature<-feature_df
  featurename.regex <- paste("^", featurename, sep="")
  #Merge and assign feature names by team matchup
  
  df <- merge(tourneydata, feature, by.x=c("Team1", "Season"), by.y=c("Team", "Season"),all.x=TRUE)
  names(df)[grepl(featurename.regex, names(df))] <- paste("Team1", featurename, sep="")
  df <- merge(df, feature, by.x=c("Team2", "Season"), by.y=c("Team", "Season"),all.x=TRUE)
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

test_train_validate_split<-function(
	dat=tourneydata,split_=.3, 
	first.season=options("first.training.season")[[1]], 
	last.season=options("last.training.season")[[1]],
	last.validation.season=options("last.validation.season")[[1]],
	first.validation.season=options("first.validation.season")[[1]]
	){
	dat<-data.table::data.table(dat)
	vdat<-dat[Season<=last.validation.season&Season>=first.validation.season,]
	tdat<-dat[Season<=last.season&Season>=first.season,]
	if(is.null(options('training_split')[[1]])==F){
		split_=as.numeric(options('training_split')[[1]])
	}
	if(split_<=0){
	assign("training_data",tdat,envir = .GlobalEnv)
	assign("test_data",NULL,envir=.GlobalEnv)
	}else{
	
	obs<-sample(tdat[,c(1:.N)],ceiling(split_*tdat[,.N]))
	assign("training_data",tdat[-obs,],envir = .GlobalEnv)
	assign("test_data",tdat[obs,],envir=.GlobalEnv)
	}
	assign('validation_data',vdat,envir=.GlobalEnv)
	return()
}

# now, run the actual functions:

tourneydata <- getTourneyData(tourney.file)

getFeature_list(options("features_to_add")[[1]])

# This should be the last step since it will produce a split that incorporates all the requisite features. 
test_train_validate_split()
