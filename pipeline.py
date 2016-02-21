import luigi_setup
import luigi
from luigi_setup import RTask,MyRTask
import os
import yaml

with open('./config.yaml', 'rb') as f:
    CONFIG=yaml.load(f)

DATA_RECIPE=CONFIG['data_recipe']
MODEL_RECIPE=CONFIG['model_recipe']

class RunModelingScripts(RTask):
    def rscript(self):
        '''
        returns r script to run
        :return:
        '''
        script = self.script_prepare()
        return script
    def script_prepare(self):
        # this should load in the data_loader file, then append the data_scripts
        if MODEL_RECIPE.get('model_files'):
            builder_files=MODEL_RECIPE['model_files']
            # builder_tmp_file=os.path.join(CONFIG['repository_location'],'building_tmp.R')
            # with open(os.path.join(CONFIG['repository_location'],'./data_loader.R'),'rb') as f:
            #     data_loader_script=f.read()
            # Insert here a bunch of code that loads preliminary things into memory (namely, base functions that designate repo root and ncaa root. concatenate to temp script as needed.
            for _file in builder_files:
                file_loc=os.path.join(CONFIG['repository_location'],_file)

                with open(file_loc,'rb') as f:
                    out=out+'\n'+f.read()
            with open(builder_tmp_file,'wb') as f:
                f.write(out)
        return builder_tmp_file


class RunDataScripts(RTask):
    def rscript(self):
        '''
        returns r script to run
        :return:
        '''
        script = self.script_prepare()
        return script
    def script_prepare(self):
        # this should load in the data_loader file, then append the data_scripts
        if DATA_RECIPE.get('builder_files'):
            builder_files=DATA_RECIPE['builder_files']
            builder_tmp_file=os.path.join(CONFIG['repository_location'],'building_tmp.R')
            with open(os.path.join(CONFIG['repository_location'],'./data_loader.R'),'rb') as f:
                data_loader_script=f.read()
            for _file in builder_files:
                file_loc=os.path.join(CONFIG['repository_location'],_file)

                with open(file_loc,'rb') as f:
                    out=out+'\n'+f.read()
            with open(builder_tmp_file,'wb') as f:
                f.write(out)
        return builder_tmp_file




"""
load in all rds files named in data_recipie
     - set dependency of train,test validate on rds files named in data recipie
run reshaping script
    - set dependency of train,test,validate on files named in data recipie and config.yaml
parse out into train, test and validate datasets

"""

