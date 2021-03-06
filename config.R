




# basic configuration stuff
base_config <- list(path_to_NCAA = '~/Google Drive/NCAA Team Stuff/NCAA/',
                    # should be path to NCAA folder on google drive
                    repository_location = '/Volumes/TINY CRYPT/papers/Personal/NCAA/ncaa_2016-master/'
                    # this should be the path to the folder that this file is in -- the root of
                    # the ncaa_2016 git repository
)



#data_recipe, list scripts relative to repo root here:
data_recipe <- list(
  data_building_files = list(
    # This should always include builder_script.R so that the correct get_features
    # and get team data functions get loaded. Any other scripts can be named in
    # this list along with this one.
    
    # This file takes forever to run, so I saved it's results to the ncaa folder. To regenerate the endurance scores, uncomment the next line and change team.survscores in data_to_load to 'NULL'
    # "data_building/createEnduranceFeature.R",
    
    #"data_building/createCBSRPI.R",
    #"data_building/createCBSSOS.R",
    #"data_building/createOrdinalsFeature.R",
    #"data_building/createPowerFeature.R",
    "data_building/builder_script.R",
    'data_building/impute.R'
  ),
  
  data_to_load = list(
    
    # these files should be specified relative to the NCAA folder
    #Define paths and file names
    
    kaggle.submission.file = "2016_competition/data_2016_specific/kaggle_dataset/SampleSubmission.rds",
    season.file = "2016_competition/data_2016_specific/kaggle_dataset/RegularSeasonDetailedResults.csv",
    tourney.file = "2016_competition/data_2016_specific/kaggle_dataset/TourneyCompactResults.csv"
    
  ),
  features_to_add = list(
    
    # feature names in this list should be the name of the feature to add 
    
    Seed='2016_competition/data_2016_specific/other_data/seedsV2.rds',
    # if the feature is built by a builder script, then enter its file name as NULL. The object returned by the builder script must be the same name as the feature name for it to be properly renamed. For example, the 
    team.survscores = "2016_competition/data_2016_specific/other_data/team.survscores.rds", 
    RPI = "2016_competition/data_2016_specific/other_data/CBSRPI.rds",
    SOS = "2016_competition/data_2016_specific/other_data/CBSSOS.rds", 
    CBSNCSOS = "2016_competition/data_2016_specific/other_data/CBSNCSOS.rds", 
    CBSNCRank = "2016_competition/data_2016_specific/other_data/CBSNCRank.rds", 
    orank = "2016_competition/data_2016_specific/other_data/orank.rds",
    pagerank = "2016_competition/data_2016_specific/other_data/pagerank.rds",
    powerScore = "2016_competition/data_2016_specific/other_data/powerScore.rds"
  ),
  #Define training period for features
  first.training.season = 1995,
  last.training.season = 2015,
  first.validation.season=2016,
  last.validation.season=2017,
  training_split=0, # 
  season_override=2016
)


# Model Recipe:
model_recipe <-	list(
  model_files = list(
    #this should be relative to the repository root
    # This will run the caret models and produce the appropriate model
    # This script will run adabag, regularized random forest and 
  	"modeling_scripts/multiclasssummary.R",
    "modeling_scripts/caret_model2016.R"
    #"modeling_scripts/bracket_2015_printable.R"
  ),
  output_file='submission.csv'
)

