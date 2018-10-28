import os


DIST_VERSION = '14.04'
DEBUG = False
APP_HOME = '/tmp/source'
APP_USER = 'app_user'
GIT_REPO = 'https://github.com/globz-eu/app_name.git'
VENV = '/tmp/.envs/app_name'
REQS_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        'test_files/install_system_dependencies/requirements.txt'
    )
)
SYS_DEPS_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        'test_files/install_system_dependencies/system_dependencies.txt'
    )
)
LOG_FILE = os.path.abspath(os.path.join(os.path.dirname(__file__), 'log/sys_deps.log'))
