import luigi_setup
import luigi
from luigi_setup import RTask,LOGGO
import os
import yaml
from luigi import LocalTarget


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
            _tmp_file=os.path.join(CONFIG['repository_location'],'modeling_tmp.R')
            # with open(os.path.join(CONFIG['repository_location'],'./data_loader.R'),'rb') as f:
            #     data_loader_script=f.read()
            # Insert here a bunch of code that loads preliminary things into memory (namely, base functions that designate repo root and ncaa root. concatenate to temp script as needed.
            for _file in builder_files:
                file_loc=os.path.join(CONFIG['repository_location'],_file)

                with open(file_loc,'rb') as f:
                    out=out+'\n'+f.read()
            with open(_tmp_file,'wb') as f:
                f.write(out)
        return _tmp_file
    def require(self):
        return RunDataScripts()


class RunDataScripts(RTask):
    def __init__(self):
        super(RunDataScripts,self).__init__()
        self._tmp_file=os.path.join(CONFIG['repository_location'],'building_tmp.R')
        LOGGO.info("__INIT_INFO")
        LOGGO.info(DATA_RECIPE)
    def rscript(self):
        '''
        returns r script to run
        :return:
        '''
        script = self.script_prepare()
        return script
    def output(self):
        return LocalTarget(path=self._tmp_file)
    def script_prepare(self):
        # this should load in the data_loader file, then append the data_scripts
        if DATA_RECIPE.get('builder_files'):
            builder_files=DATA_RECIPE['builder_files']
            builder_tmp_file = self._tmp_file
            with open(os.path.join(CONFIG['repository_location'],'./data_loader.R'),'rb') as f:
                data_loader_script=f.read()
            for _file in builder_files:
                file_loc=os.path.join(CONFIG['repository_location'],_file['path_relative_to_repo_root'])
                out=data_loader_script
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

if __name__ == '__main__':
    from luigi.mock import MockFile # import this here for compatibility with Windows
    # if you are running windows, you would need --lock-pid-dir argument;
    # Modified run would look like
    # luigi.run(["--lock-pid-dir", "D:\\temp\\", "--local-scheduler"], main_task_cls=DecoratedTask)
    luigi.run(["--local-scheduler"], main_task_cls=RunDataScripts)