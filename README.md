# ncaa_2016
NCAA tournament pipeline


To use: 
create a config.yaml file that specifies the following: 
```{yaml}

# in yaml, comments begin with a hashtag.
path_to_NCAA: ~/Google Drive/NCAA/
repository_location: /s/Programming/NCAA_2016
data_building_files:
- data_building/builder_script.R
# you should probably always include this file. 

data_to_load:
	# These are specified as dataset_name: dataset_location -- relative to the ncaa folder
  kaggle.submission.file: 2016_competition/data_2016_specific/kaggle_dataset/SampleSubmission.rds
  season.file: 2016_competition/data_2016_specific/kaggle_dataset/RegularSeasonDetailedResults.csv
  tourney.file: 2016_competition/data_2016_specific/kaggle_dataset/TourneyCompactResults.csv

features_to_add:
  Seed: 2016_competition/data_2016_specific/kaggle_dataset/TourneySeeds.rds

first.training.season: 2005.0
last.training.season: 2011.0

model_files:
- modeling_scripts/analysis03142015.R


```
Alternatively, you can specifiy this in a file called config.R and the pipeline will generate the corresponding yaml file for you. This is a more finicky way of doing this though and the file must be structured very similarly to config.R.example.

## Description of parameters

### path_to_NCAA

this is required. it is the path to the NCAA folder on your local machine. 

### repository_location

this is required. it is the path to this repo on your local machine.

### features_to_add

These are specified as feature_name: feature_location -- relative to the ncaa folder. The feature dataset should have 3 columns: one for  

### data_to_load

these are the names and locations of the datasets to load in. they are specified relative to the root of the NCAA folder. At least one of these should be named `tourney.file'. if using the builder_script, this dataset will form the base dataset into which features are merged. The tourney.file in the example above is the location of the compact tourney results file supplied by kaggle. 


### last.training.season and first.training.season

these is used by `getTourneyData()` in the builder_script to properly subset data for a specified set of 
seasons

### data_building_files:

these are files specified relative to the repo root. They are files you want to run to manipulate data prior to model estimation. You should probably keep the builder_script in this list as this script will properly transform the tourney data and load features in the `features_to_add` list


### model_files: 

these are the model building files that are run to generate model estimates. these scripts should expect an object called tourneydata and return a model object with a standard predict method. 

