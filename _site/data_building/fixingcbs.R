require(data.table)
require(RecordLinkage)
require(plyr)
m<-fread(ncaa_wd("2016_competition/data_2016_specific/other_data/CBS_revised.csv"))
setnames(m,'school','name')
mnames<-unique(m$name)

sp<-read.csv(ncaa_wd("2016_competition/data_2016_specific/other_data/team_spellings.csv"))


match_key<-data.table(ldply(mnames,function(i){
	match_names<-adist(x=i,y=sp$name_spelling,ignore.case=T)
	min_nam<-min(match_names)
	match_row<-which(match_names==min(match_names))[1]
	match_name<-sp$name_spelling[match_row]
	match_code<-sp$team_id[match_row]
	return(data.frame(name=i,sp_name=match_name,dist=min_nam,team_id=match_code))
	}))
setkey(match_key,name)
setkey(m,name)
m[match_key,team:=team_id]
