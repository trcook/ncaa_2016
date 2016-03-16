#PageRank algorithm for basketball teams

library(igraph)
library(caret)
library(reshape)
library(parallel)

setwd("/Volumes/TINY CRYPT/papers/Personal/NCAA/2016 Kaggle Data/march-machine-learning-mania-2016-v1")

#Define paths and file names
kaggle.submission.file <- "SampleSubmission.csv"
season.file <- "RegularSeasonCompactResults.csv"
tourney.file <- "TourneyCompactResults.csv"

#Define training period for features
first.training.season <- 2005
last.training.season <- 2011

makeRank <- function(x){
  pr <- page.rank(graph.data.frame(d=data.frame(from=x$Lteam, to=x$Wteam), directed=T ))$vector
  pr <- data.frame(Team=names(pr), Season=unique(x$Season), pagerank=pr)
}

doPageRank <- function(season.file, first.season=first.training.season, last.season=last.training.season){
  df <- read.csv(season.file)
  #get the correct seasons
  df <- df[ which(df$Season >= first.season & df$Season <= last.season), ]
  df <- getSeasonData(season.file)[, c("Season", "Wteam", "Lteam")]
  spdf <- split(df, as.factor(df$Season))
  pr <- lapply(spdf, function(x) makeRank(x))
  pr <- do.call(rbind, pr)
  return(pr)
}

pr <- doPageRank(season.file)

write.csv(pr, "PageRankfeature.csv", row.names = F)

