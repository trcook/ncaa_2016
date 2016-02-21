import luigi
import yaml
import logging
# import rpy2
# from rpy2.robjects import r
import abc

import datetime
from luigi.s3 import S3Target
from luigi.target import FileSystemTarget
from luigi import LocalTarget
import subprocess
import os

class RTask(luigi.Task):
    """
    Luigi Task to run an R script.
    To use this Task in a pipeline, create a subclass that overrides the methods:
    * `rscript`
    * `arguments`
    seealso:: https://help.mortardata.com/technologies/luigi/r_tasks
    """

    # Location where completion tokens are written
    # e.g. s3://my-bucket/my-path
    # token_path = luigi.Parameter()

    token_path = os.path.join(os.getcwd(),'completions')
    if not os.path.exists(token_path):
        os.makedirs(token_path)

    
    def output_token(self):
        """
        Luigi Target providing path to a token that indicates
        completion of this Task.
        :rtype: Target:
        :returns: Target for Task completion token
        """
        return TargetFactory.get_target('%s/%s' % (self.token_path, self.__class__.__name__))

    def output(self):
        """
        The output for this Task. Returns the output token
        by default, so the task only runs if the token does not 
        already exist.
        :rtype: Target:
        :returns: Target for Task completion token
        """
        return [self.output_token()]

    @abc.abstractmethod
    def rscript(self):
        """
        Path to the R script to run, relative to the root of your Mortar project.
        Ex:
            If you have two files in your Mortar project:
                * luigiscripts/my_r_luigiscript.py
                * rscripts/my_r_script.R
            You would return:
                "rscripts/my_r_script.R"
        :rtype: str:
        :returns: Path to your R script relative to the root of your Mortar project. e.g. rscripts/my_r_script.R
        """
        raise RuntimeError("Please implement the rscript method in your MortarRTask to specify which script to run.")

    def arguments(self):
        """
        Returns list of arguments to be sent to your R script.
        :rtype: list of str:
        :returns: List of arguments to pass to your R script. Default: []
        """
        return []

    def run(self):
        """
        Run an R script using the Rscript program. Pipes stdout and
        stderr back to the logging facility.
        """
        cmd = self._subprocess_command()
        output = subprocess.Popen(
            cmd,
            shell=True,
            stdout = subprocess.PIPE,
            stderr = subprocess.STDOUT,
            bufsize=1
        )
        for line in iter(output.stdout.readline, b''):
            LOGGO.info(line)
        out, err = output.communicate()
        rc = output.returncode
        if rc != 0:
            raise RuntimeError('%s returned non-zero error code %s' % (self._subprocess_command(), rc) )

        TargetFactory.write_file(self.output_token())

    def _subprocess_command(self):
       return "Rscript %s %s" % (self.rscript(), " ".join(self.arguments()))


# Some basic debugging stuff
LOGGO = logging.getLogger('loggo')
LD = LOGGO.debug
logging.basicConfig(format='[%(asctime)s %(levelname)s] %(message)s',
                    level=logging.DEBUG,
                    datefmt='%H:%M:%S')
LOGGO.setLevel(logging.DEBUG)


# with open('./config.yaml','rb') as f:
#   config=yaml.load(f)

class MyRTask(RTask):
    working_files=luigi.Parameter()
    def rscript(self):
        return('./pipeline.R')
    def arguments(self):
        return self.working_files

class TargetFactory():
    @classmethod
    def get_target(cls,path):
        """
        Factory method to create a Luigi Target from a path string.
        Supports the following Target types:
        * S3Target: s3://my-bucket/my-path
        * LocalTarget: /path/to/file or file:///path/to/file
        :type path: str
        :param path: s3 or file URL, or local path
        :rtype: Target:
        :returns: Target for path string
        """
        if path.startswith('s3:'):
            return S3Target(path)
        elif path.startswith('/'):
            return LocalTarget(path)
        elif path.startswith('file://'):
            # remove the file portion
            actual_path = path[7:]
            return LocalTarget(actual_path)
        else:
            raise RuntimeError("Unknown scheme for path: %s" % path)
    @classmethod
    def write_file(cls,out_target, text=None):
        """
        Factory method to write a token file to a Luigi Target.
        :type out_target: Target
        :param out_target: Target where token file should be written
        :type text: str
        :param text: Optional text to write to token file. Default: write current UTC time.
        """
        with out_target.open('w') as token_file:
            if text:
                token_file.write('%s\n' % text)
            else:
                token_file.write('%s' % datetime.datetime.utcnow().isoformat())
