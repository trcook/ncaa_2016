

# basic configuration stuff
base_config<-list(
path_to_NCAA='~/Google Drive/NCAA/',
# should be path to NCAA folder on google drive
repository_location= '/s/Programming/NCAA_2016'
# this should be the path to the folder that this file is in -- the root of the ncaa_2016 git repository
)



#data_recipe, list scripts relative to repo root here:
data_recipe<-list(

data_building_recipe=list(
	"data_building/builder_script.R"
	),

# these files should be specified relative to the NCAA folder
data_to_load=list(
	
	#Define paths and file names
	kaggle.submission.file = "2016_competition/data_2016_specific/kaggle_dataset/SampleSubmission.rds",
	season.file ="2016_competition/data_2016_specific/kaggle_dataset/RegularSeasonDetailedResults.csv",
	tourney.file = "2016_competition/data_2016_specific/kaggle_dataset/TourneyCompactResults.csv"
	)

)


# Model Recipe:
model_recipe<-list(
	model_files=list(
		#this should be relative to the repository root
		"modeling_scripts/analysis03142015.R"
		)
	)


