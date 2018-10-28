import os


DIST_VERSION = '14.04'
DEBUG = False
APP_HOME = '/tmp/source'
APP_USER = 'app_user'
GIT_REPO = 'https://github.com/globz-eu/app_name.git'
LOG_FILE = os.path.abspath(os.path.join(os.path.dirname(__file__), 'log/serve_static.log'))
