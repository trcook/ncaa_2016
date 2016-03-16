

df <- parseBracket(f = repo_wd("submission.csv"))
sim <- simTourney(df, 1000, year=2015, progress=TRUE)
bracket <- extractBracket(sim)
printableBracket(bracket)
