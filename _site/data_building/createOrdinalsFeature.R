#Create smoothed ranks - this should improve rankings by smoothing out noisy outcomes

library(caret)
library(reshape)

getScaledRank <- function(x){
  x$orank <- scale(x$orank)
  return(x)
}

#this function is a bit weird, as the arguments don't really matter at this moment
createOrdinalsFeature <- function(season.file, first.season, last.season, path="~/Google Drive/NCAA Team Stuff/NCAA/2016_competition/data_2016_specific/other_data/"){
  #updated Ordinals data goes from 2003-2016
  ordinals <- read.csv(paste(path, "massey_ordinals_2003-2015.csv", sep=""))
  ord.updated <- read.csv(paste(path, "MasseyOrdinals2016ThruDay121Updated.csv", sep="")) #this is the latest ordinals file
  ordinals <- rbind(ordinals, ord.updated)
  
  #split to scale the individual ranking systems so they all work together 
  spdat <- split(ordinals, factor(ordinals$sys_name))
  scaled.oranks <- lapply(spdat, function(x) getScaledRank(x))
  ordinals <- do.call("rbind", scaled.oranks)
  
  mod.of.ordinals <- lmer(orank~(1|sys_name)+(1|season)+(1|team), weights=rating_day_num, data=ordinals)
  
  ordinals$orank <- predict(mod.of.ordinals)
  
  #get median of prediction from model
  agg.orank <- aggregate(orank~team+season, median, data=ordinals)
  names(agg.orank) <- c("Team", "Season", "orank")

  return(agg.orank)
}

orank <- createOrdinalsFeature(season.file, first.season = options('first.training.season')[[1]],last.season = options('last.validation.season')[[1]])

#orank <- createOrdinalsFeature(first.season = 1995, last.season = 2016)
#saveRDS(orank, "~/Google Drive/NCAA Team Stuff/NCAA/2016_competition/data_2016_specific/other_data/orank.rds")
