

df <- parseBracket("C:\\Users\\wombat\\Downloads\\sample_submission_2015.csv")
sim <- simTourney(df, 1000, year=2015, progress=TRUE)
bracket <- extractBracket(sim)
printableBracket(bracket)
