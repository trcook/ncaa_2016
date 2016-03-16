#script to make the seeds feature
library(caret)

#setwd("/Volumes/TINY CRYPT/papers/Personal/NCAA/2016 Kaggle Data/march-machine-learning-mania-2016-v1")
#seeds <- "TourneySeeds.csv"

#Make seed
makeSeedFeature <- function(seeds.file){
  seeds <- read.csv(seeds.file)
  seeds$Seed <- as.numeric(gsub("[aA-zZ]", "", seeds$Seed))  
  return(seeds)
}

seeds <- makeSeedFeature(seeds.file="TourneySeeds.csv")

#saveRDS(seeds, "~/Google Drive/NCAA Team Stuff/NCAA/2016_competition/data_2016_specific/other_data/seedsV2.rds")
