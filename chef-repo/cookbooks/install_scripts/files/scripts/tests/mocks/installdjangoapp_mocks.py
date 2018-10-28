import os
from tests.conf_tests import DIST_VERSION, VENV, LOG_FILE, LOG_LEVEL, CELERY_PID_PATH
from utilities.commandfileutils import CommandFileUtils


__author__ = 'Stefan Dieterle'


def clone_app_mock(app_home):
    static_files = [
        ['static', 'static/static_file', 'static'],
        ['media', 'media/media_file', 'media'],
        ['', 'uwsgi_params', 'uwsgi_params'],
        ['static/base/site_down', 'static/base/site_down/index.html', 'index.html']
    ]
    for static_dir, static_file_path, static_name in static_files:
        os.makedirs(os.path.join(app_home, 'app_name', static_dir), exist_ok=True)
        static_file_abs_path = os.path.join(app_home, 'app_name', static_file_path)
        with open(static_file_abs_path, 'w') as static_file:
            static_file.write('%s stuff\n' % static_name)
    cfu = CommandFileUtils(DIST_VERSION, LOG_FILE, LOG_LEVEL)
    cfu.write_to_log('successfully cloned %s to %s' % ('app_name', app_home), 'INFO')


def add_app_to_path_mock(app_home):
    if DIST_VERSION == '14.04':
        python_version = 'python3.4'
    elif DIST_VERSION == '16.04':
        python_version = 'python3.5'
    else:
        python_version = None
    pth_path = os.path.join(VENV, 'lib', python_version)
    os.makedirs(pth_path, exist_ok=True)
    with open(os.path.join(pth_path, 'app_name.pth'), 'w') as pth:
        pth.write(app_home)
    return 0


def copy_config_mock(app_home, uwsgi=True, behave=True):
    os.makedirs(os.path.join(app_home, 'app_name', 'app_name'), exist_ok=True)
    cfu = CommandFileUtils(DIST_VERSION, LOG_FILE, LOG_LEVEL)
    cfu.write_to_log('app configuration file settings.json was copied to app', 'INFO')
    cfu.write_to_log('app configuration file behave.ini was copied to app', 'INFO')
    return 0


def stop_celery_mock(app_home):
    cfu = CommandFileUtils(DIST_VERSION, LOG_FILE, LOG_LEVEL)
    cfu.write_to_log('stopped celery and beat', 'INFO')
    if os.path.exists(os.path.join(CELERY_PID_PATH, 'w1.pid')):
        os.remove(os.path.join(CELERY_PID_PATH, 'w1.pid'))
    return 0
