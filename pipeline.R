# do.call("options",yaml.load(as.yaml(c(base_config,data_recipe,model_recipe))))

require(pryr)
require(data.table)

testObject<-function(object){
  exists(as.character(substitute(object)))
}


#' This will put all the parts of the config.yaml into options by top-level key. 

setup_opts<-function(){
	tmp<-file.path(tempfile(fileext = '.yaml'))
	if(file.exists("config.yaml")){
		file.copy(from='config.yaml',to=tmp)
		print(tmp)
		print(file.exists(tmp))
		options(yaml::yaml.load_file(tmp))
	}else{
		source("config.R")
	sink(tmp)
	cat(yaml::as.yaml(c(base_config,data_recipe,model_recipe)))
	sink()
	options(yaml::yaml.load_file(tmp))
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

submission_output<-function(model_=model,validation_data_=validation_data,output_file_name=options('output_file'),season_override=NULL){
	if(is.null(options('output_file')[[1]])){
		output_file_name='submission.csv'
	}
	validation_data_<-data.table::copy(data.table(validation_data_))
	if(exists('train_features',envir = .GlobalEnv)){
		sdnames=train_features
	}else{sdnames=names(validation_data_)}
	validation_data_[,Pred:=predict(model_,newdata=.SD,type='prob')[,1],.SDcols=sdnames]
	
 	
	
	validation_data_[,Id:=paste0(Season,'_',Team1,'_',Team2)]	
	
 	out<-validation_data_[,cbind(Id,Pred)]
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

predictions<-submission_output(model_=model,validation_data_=validation_data,output_file_name=options('output_file'),season_override=options("season_override"))


# produce bracket

if("kaggleNCAA" %in% installed.packages()==F){
	devtools::install_github('zachmayer/kaggleNCAA')
	require(kaggleNCAA)
}

df <- kaggleNCAA::parseBracket(f = repo_wd("submission.csv"))
sim <- kaggleNCAA::simTourney(df, 100, year=2016, progress=TRUE)
bracket <- kaggleNCAA::extractBracket(sim)

x=8
y=x/1.777778

png(filename = repo_wd('bracket.png'),width = x,height = y,units = 'in',res=300,pointsize = 8.5)
print(kaggleNCAA::printableBracket(bracket,add_prob = T,add_seed = F))
dev.off()


pdf(file = repo_wd("bracket.pdf"),width=x,height = y,pointsize = 8.5)
print(kaggleNCAA::printableBracket(bracket,add_prob = T,add_seed = F))
dev.off()




