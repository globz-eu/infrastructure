import os


DIST_VERSION = '16.04'
LOG_LEVEL = 'DEBUG'
TEST_DIR = '/tmp/scripts_test'
LOG_FILE = os.path.abspath(os.path.join(os.path.dirname(os.path.dirname(__file__)), 'log/tests.log'))
APP_HOME = os.path.join(TEST_DIR, 'app_user', 'sites', 'app_name', 'source')
DOWNLOAD_FOLDER = os.path.join(TEST_DIR, 'chef-server')
METADATA_FILE = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        'test_files/chef_server_metadata'
    )
)