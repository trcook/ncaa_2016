import luigi
import yaml
import logging
LOGGO = logging.getLogger('loggo')
LD = LOGGO.debug
logging.basicConfig(format='[%(asctime)s %(levelname)s] %(message)s',
                    level=logging.DEBUG,
                    datefmt='%H:%M:%S')
LOGGO.setLevel(logging.DEBUG)


with open('./config.yaml','rb') as f:
	config=yaml.load(f)

LD(config['path_to_NCAA'])