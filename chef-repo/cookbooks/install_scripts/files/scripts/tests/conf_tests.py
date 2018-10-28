import os

__author__ = 'Stefan Dieterle'

TEST_DIR = '/tmp/scripts_test'
FIFO_DIR = '/tmp/scripts_test/fifo/app_name'

DIST_VERSION = '16.04'
LOG_LEVEL = 'DEBUG'
NGINX_CONF = '/tmp/scripts_test/etc/nginx'
APP_HOME = '/tmp/scripts_test/app_user/sites/app_name/source'
APP_HOME_TMP = '/tmp/scripts_test/web_user/sites/app_name/source'
APP_USER = 'app_user'
WEB_USER = 'web_user'
WEBSERVER_USER = 'www-data'
DB_USER = 'db_user'
DB_ADMIN_USER = 'postgres'
GIT_REPO = 'https://github.com/globz-eu/app_name.git'
STATIC_PATH = '/tmp/scripts_test/web_user/sites/app_name/static_files'
MEDIA_PATH = '/tmp/scripts_test/web_user/sites/app_name/media_files'
UWSGI_PATH = '/tmp/scripts_test/web_user/sites/app_name/uwsgi'
CELERY_PID_PATH = '/tmp/scripts_test/run/celery'
DOWN_PATH = '/tmp/scripts_test/web_user/sites/app_name/down'
VENV = '/tmp/scripts_test/app_user/.envs/app_name'
REQS_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        'test_files/install_system_dependencies/requirements.txt'
    )
)
SYS_DEPS_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        'test_files/install_system_dependencies/system_dependencies.txt'
    )
)
LOG_FILE = os.path.abspath(os.path.join(os.path.dirname(os.path.dirname(__file__)), 'log/tests.log'))
