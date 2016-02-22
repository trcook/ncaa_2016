




# basic configuration stuff
base_config <- list(path_to_NCAA = '~/Google Drive/NCAA/',
	# should be path to NCAA folder on google drive
	repository_location = '/s/Programming/NCAA_2016'
	# this should be the path to the folder that this file is in -- the root of
	# the ncaa_2016 git repository
)
										
										
										
#data_recipe, list scripts relative to repo root here:
data_recipe <- list(
	data_building_files = list(
		# This should always include builder_script.R so that the correct get_features and get team data functions get loaded. Any other scripts can be named in this list along with this one. 
		"data_building/builder_script.R"),
	
	# these files should be specified relative to the NCAA folder
	data_to_load = list(
		#Define paths and file names
		kaggle.submission.file = "2016_competition/data_2016_specific/kaggle_dataset/SampleSubmission.rds",
		season.file = "2016_competition/data_2016_specific/kaggle_dataset/RegularSeasonDetailedResults.csv",
		tourney.file = "2016_competition/data_2016_specific/kaggle_dataset/TourneyCompactResults.csv"
	),
	features_to_add = list(
		# feature names in this list should be the name of the feature to add 
		Seed='2016_competition/data_2016_specific/kaggle_dataset/TourneySeeds.rds'
	),
	#Define training period for features
	first.training.season = 2005,
	last.training.season = 2011,
	first.validation.season=2010,
	last.validation.season=2015,
	training_split=.3

)
										
										
# Model Recipe:
model_recipe <-
	list(model_files = list(#this should be relative to the repository root
		"modeling_scripts/sample_model.R"),
			output_file='submission.csv'
)

										