import luigi_setup
import luigi
from luigi_setup import RTask,MyRTask
import os

class RunModelingScripts(RTask):
    script = luigi.Parameter()
    def rscript(self):
        return os.path.join("modeling_scripts",self.script)
    def requires(self):
        return MyRTask()