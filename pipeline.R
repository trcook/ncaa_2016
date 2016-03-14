# do.call("options",yaml.load(as.yaml(c(base_config,data_recipe,model_recipe))))

require(pryr)
require(data.table)

testObject<-function(object){
  exists(as.character(substitute(object)))
}


#' This will put all the parts of the config.yaml into options by top-level key. 

setup_opts<-function(){
	if(file.exists("config.yaml")){
		options(yaml::yaml.load_file('config.yaml'))
	}else{
		source("config.R")
	sink("config.yaml")
	cat(yaml::as.yaml(c(base_config,data_recipe,model_recipe)))
	sink()
	options(yaml::yaml.load_file('config.yaml'))
	}

	if(any(
		is.null(options("path_to_NCAA")),
		is.null(options('repository_location'))
		)){
		stop('path_to_ncaa not set in recipe, or recipe not found')
	}
}



# functions to translate relative locations on different machines
setup_location_func<-function(){
	repo_wd<<-pryr::partial(file.path,options("repository_location"))
	ncaa_wd<<-pryr::partial(file.path,options("path_to_NCAA"))

}

#get extension of file
ext_getter<-function(x){
gsub(x,pattern='.*\\.([^\\.]+?)$',replacement='\\1')
}


	load_list<-function(x){
		for(i in seq_along(x)){
			if(x[[i]]=='NULL'){
				next()
			}
			load_dat<-x[[i]]
			name_dat<-names(x)[[i]]
			ext<-ext_getter(load_dat)
			load_method<-switch(ext,rds=readRDS,csv=read.csv,dta=foreign::read.dta)
			assign(name_dat,load_method(ncaa_wd(load_dat)),envir = .GlobalEnv)
		}
			}

run_list<-function(x){
	for(i in x){
		source(repo_wd(i))
	}
	}

submission_output<-function(model_=model,validation_data_=validation_data,output_file_name=options('output_file')){
	if(is.null(options('output_file')[[1]])){
		output_file_name='submission.csv'
	}
	validation_data_<-data.table::copy(data.table(validation_data_))
	validation_data_[,Pred:=predict(model_,newdata=.SD)]
	return(validation_data_)
 	validation_data_[,Id:=paste0(Season,'_',Team1,'_',Team2)]
 	out<-validation_data_[,.(Id,Pred)]
 	write.csv(out,file=repo_wd(output_file_name),row.names = F)
 	return(out)
}




setup_opts()
setup_location_func()

# Run the requisite functions
#todo: implement functions to take output from load_data and split into train, validate, test datasets. Have them be labeled train, test, validate in memory


# load data and load feature datasets

load_list(options("data_to_load")[[1]])
load_list(options("features_to_add")[[1]])

# run data_ building files
run_list(options("data_building_files")[[1]])




run_list(options("model_files")[[1]])


submission_output(model_=model,validation_data_=validation_data,output_file_name=options('output_file'))
