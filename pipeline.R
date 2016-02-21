#----File Info--------------------------------------------------------------
#
#          This file runs the test-train-validate pipeline for our models.
#          It should be run trough Luigi
#
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


#----prelims--------------------------------------------------------------
#
#                                      Prelims
#
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

require(yaml)
require(pryr)
#' set directory for 
config<-yaml.load_file('./config.yaml')

#' This will put all the parts of the config.yaml into options by top-level key. 
for(i in seq_along(config)){
options(config[i])
print(config[i])
}
args = commandArgs(trailingOnly=TRUE)




# The ncaa_wd function will produce a file path relative to the NCAA folder on your machine, based on the config.yaml file settings. Example: wd('2016_competition/data_2016_specific/') produces '/Users/tom/Google Drive/NCAA/2016_competition/data_2016_specific/'. This is used to specify file locations relative to the NCAA folder without needing to switch directories from the git repo
ncaa_wd<-partial(file.path,options("path_to_NCAA"))

# The repo_wd function will produce a file path relative to the NCAA folder on your machine, based on the config.yaml file settings. Example: wd('2016_competition/data_2016_specific/') produces '/Users/tom/Google Drive/NCAA/2016_competition/data_2016_specific/'. This is used to specify file locations relative to the NCAA folder without needing to switch directories from the git repo
repo_wd<-partial(file.path,options("repository_location"))



print(args)

for(i in seq_along(args)){
		nam<-names(args)[i]
		fil<-args[i]

	eval(substitute(nam<-readRDS(fil),env=list(nam=as.name(nam),fil=ncaa_wd(paste(fil,'.RDS',sep='')))))
}


save.image(file=repo_wd('working_data.rda'))