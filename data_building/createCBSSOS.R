#Create smoothed ranks - this should improve rankings by smoothing out noisy outcomes

library(caret)
library(reshape)

createcbsSOS <- function(first.season, last.season, path="~/Google Drive/NCAA Team Stuff/NCAA/2016_competition/data_2016_specific/other_data/"){
  #updated CBS data goes from 1995-2016
  cbs <- read.csv(paste(path, "cbsdata.csv", sep=""), colClasses = "character")

  #updatd key for CBS data merges all teams except one
  key1 <- read.csv(paste(path, "team_spellings.csv", sep=""), colClasses = "character")
  
  #merging the key and and the CBS to make sure the team id column is present
  cbs <- merge(cbs, key1, by.x="School", by.y="name_spelling") #one team gets dropped - texas-rio grande valley
  
  #Fix team ID's
  cbs <- rename(cbs, c(team_id = "Team"))
  
  #Eliminate the wanted seasons
  cbs$Season <- gsub("[0-9]{4}-", "", cbs$season)
  cbs$season <- NULL
  cbs$SOS <- as.numeric(cbs$SOS)
  
  cbs <- cbs[ which(cbs$Season >= first.season & cbs$Season <= last.season), ]

  cbs <- cbs[, c("Team", "Season", "SOS")]
}

SOS <- createcbsSOS(first.season = options('first.training.season')[[1]],last.season = options('last.validation.season')[[1]])

#SOS <- createcbsSOS(first.season = 1995, last.season = 2016)
#saveRDS(SOS, "~/Google Drive/NCAA Team Stuff/NCAA/2016_competition/data_2016_specific/other_data/CBSSOS.rds")
