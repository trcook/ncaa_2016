

cbs <- read.csv("C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\cbs2003-2015_with_ids.csv")
spell <- read.csv("C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\team_spellings.csv")
dat <- merge(cbs, spell, by.x="matchedName", by.y="name_spelling")

fseason  <- factor(dat$season)
sp.dat <- split(dat, fseason)
sp.dat <- lapply(sp.dat, function(x) x[!duplicated(x$team_id),])
dat <- do.call(rbind, sp.dat)
write.csv(dat, "C:\\Users\\wombat\\Documents\\NCAA\\2015 Kaggle Data\\cbs2003-2015_nodups_ids.csv")
