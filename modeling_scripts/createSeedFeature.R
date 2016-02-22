#script to make the seeds feature
library(caret)

setwd("/Volumes/TINY CRYPT/papers/Personal/NCAA/2016 Kaggle Data/march-machine-learning-mania-2016-v1")

seeds <- read.csv("TourneySeeds.csv")

#Make seed
seeds$Seed <- as.numeric(gsub("[aA-zZ]", "", seeds$Seed))

write.csv(seeds, "TourneySeeds_feature.csv", row.names=F)
