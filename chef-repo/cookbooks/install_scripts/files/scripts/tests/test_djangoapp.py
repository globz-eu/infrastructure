"""
Tests install_django_app_trusty.py script
"""

import getpass
import io
import re
import os
import sys
import shutil
import subprocess
import datetime
from unittest import mock
from unittest.mock import call
import djangoapp
from djangoapp import InstallDjangoApp, main
from tests.conf_tests import GIT_REPO, APP_HOME, APP_USER, VENV, REQS_FILE, SYS_DEPS_FILE
from tests.conf_tests import TEST_DIR, FIFO_DIR
from tests.helpers import Alternate
from tests.mocks.commandfileutils_mocks import check_process_mock, own_app_mock
from tests.mocks.installdjangoapp_mocks import add_app_to_path_mock, copy_config_mock, clone_app_mock, stop_celery_mock
import tests.mocks.commandfileutils_mocks as mocks
from utilities.commandfileutils import CommandFileUtils
from tests.runandlogtest import RunAndLogTest

__author__ = 'Stefan Dieterle'


class InstallTest(RunAndLogTest):
    def setUp(self):
        RunAndLogTest.setUp(self)
        self.git_repo = GIT_REPO
        self.app_home = APP_HOME
        p = re.compile('https://github.com/[\w\-]+/(\w+)\.git')
        self.app_name = p.match(self.git_repo).group(1)
        self.venv = VENV

        if os.path.exists(os.path.join(os.path.dirname(self.log_file), 'test_results')):
            shutil.rmtree(os.path.join(os.path.dirname(self.log_file), 'test_results'))


class AppTest(InstallTest):
    """
    tests InstallDjangoApp uwsgi and celery methods
    """

    def setUp(self):
        InstallTest.setUp(self)
        self.fifo_dir = FIFO_DIR

    @mock.patch('djangoapp.InstallDjangoApp.check_process', side_effect=check_process_mock)
    def test_start_uwsgi(self, check_process_mock_false):
        """
        tests that start_uwsgi runs the correct command and writes to log
        """
        mocks.alt_bool = Alternate([False, False, True, False])
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, git_repo=self.git_repo)
        cmd = ['uwsgi', '--ini', '%s_uwsgi.ini' % os.path.join(self.app_home, self.app_name)]
        cwd = os.path.join(self.app_home, self.app_name)
        msg = 'started uwsgi server'
        func = 'start_uwsgi'
        args = (self.app_home,)
        # when uwsgi is not running
        self.run_success([cmd], [msg], func, install_django_app.start_uwsgi, args)
        self.run_cwd(cwd, func, install_django_app.start_uwsgi, args)
        self.assertTrue(os.path.exists(os.path.join('/tmp', self.app_name)), 'fifo directory was not created')
        self.log('INFO: changed permissions of %s to %s' % (os.path.join('/tmp', self.app_name), '777'))

        # when uwsgi is running
        msg = 'uwsgi is already running'
        self.run_success([cmd], [msg], func, install_django_app.start_uwsgi, args)

        # when uwsgi is not running
        self.run_error(cmd, func, install_django_app.start_uwsgi, args)
        self.assertEqual(
            [call('uwsgi')] * 4,
            check_process_mock_false.mock_calls,
            check_process_mock_false.mock_calls
        )

    def test_start_celery(self):
        """
        tests that start_celery runs the correct command and writes to log
        """
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level,
            venv=self.venv, git_repo=self.git_repo, celery_pid=self.celery_pid_path
        )
        cmd = [
            os.path.join(self.venv, 'bin', 'python'),
            '-m',
            'celery',
            'multi',
            'start',
            'w1',
            '-A',
            self.app_name,
            '-B',
            '--scheduler=djcelery.schedulers.DatabaseScheduler',
            '--pidfile=%s' % os.path.join(self.celery_pid_path, 'w1.pid'),
            '--logfile=%s' % os.path.join(os.path.dirname(self.log_file), 'celery', 'w1.log'),
            '-l',
            'info'
        ]
        cwd = os.path.join(self.app_home, self.app_name)
        msg = 'started celery and beat'
        func = 'start_celery'
        args = (self.app_home,)
        # when celery is not running
        if os.path.exists(os.path.join(self.celery_pid_path, 'w1.pid')):
            os.remove(os.path.join(self.celery_pid_path, 'w1.pid'))
        self.run_success([cmd], [msg], func, install_django_app.start_celery, args)
        self.run_cwd(cwd, func, install_django_app.start_celery, args)

        # when celery is running
        os.makedirs(self.celery_pid_path, exist_ok=True)
        with open(os.path.join(self.celery_pid_path, 'w1.pid'), 'w') as pid:
            pid.write('celery pid')
        msg = 'celery is already running'
        self.run_success([cmd], [msg], func, install_django_app.start_celery, args)

        # when celery is not running
        if os.path.exists(os.path.join(self.celery_pid_path, 'w1.pid')):
            os.remove(os.path.join(self.celery_pid_path, 'w1.pid'))
        self.run_error(cmd, func, install_django_app.start_celery, args)

    def test_stop_celery(self):
        """
        tests that stop_celery runs the correct command and writes to log
        """
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level,
            venv=self.venv, git_repo=self.git_repo, celery_pid=self.celery_pid_path
        )
        cmd = [
            os.path.join(self.venv, 'bin', 'python'),
            '-m',
            'celery',
            'multi',
            'stopwait',
            'w1',
            '--pidfile=%s' % os.path.join(self.celery_pid_path, 'w1.pid'),
        ]
        cwd = os.path.join(self.app_home, self.app_name)
        msg = 'stopped celery and beat'
        func = 'stop_celery'
        args = (self.app_home,)

        # when celery is running
        os.makedirs(self.celery_pid_path, exist_ok=True)
        with open(os.path.join(self.celery_pid_path, 'w1.pid'), 'w') as pid:
            pid.write('celery pid')
        self.run_success([cmd], [msg], func, install_django_app.stop_celery, args)
        self.run_cwd(cwd, func, install_django_app.stop_celery, args)

        # when celery is not running
        if os.path.exists(os.path.join(self.celery_pid_path, 'w1.pid')):
            os.remove(os.path.join(self.celery_pid_path, 'w1.pid'))
        install_django_app.stop_celery(*args)
        self.log('INFO: did not stop celery, was not running')

    @mock.patch.object(InstallDjangoApp, 'check_process', side_effect=check_process_mock)
    def test_stop_uwsgi(self, check_process_mock):
        """
        tests that stop_uwsgi writes to fifo and writes to log
        """
        djangoapp.FIFO_DIR = self.fifo_dir
        mocks.alt_bool = Alternate([True])
        os.makedirs(os.path.join(self.fifo_dir, self.app_name))
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, git_repo=self.git_repo,
                                              fifo_dir=self.fifo_dir
                                              )
        install_django_app.stop_uwsgi()
        with open(os.path.join(self.fifo_dir, 'fifo0')) as fifo:
            fifo_list = [l for l in fifo]
        self.assertEqual(['q'], fifo_list, fifo_list)
        self.log('INFO: stopped uwsgi server')
        self.assertEqual(
            [call('uwsgi')],
            check_process_mock.mock_calls,
            check_process_mock.mock_calls
        )

    @mock.patch.object(InstallDjangoApp, 'check_process', side_effect=check_process_mock)
    def test_stop_uwsgi_does_nothing_when_uwsgi_is_not_running(self, check_process_mock):
        """
        tests that stop_uwsgi does nothing when uwsgi is not running
        """
        mocks.alt_bool = Alternate([False])
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo,
        )
        install_django_app.stop_uwsgi()
        self.log('INFO: did not stop uwsgi, was not running')
        self.assertEqual(
            [call('uwsgi')],
            check_process_mock.mock_calls,
            check_process_mock.mock_calls
        )

    def test_remove_app(self):
        """
        tests that remove_app removes all files in app
        """
        user = getpass.getuser()
        clone_app_mock(self.app_home)
        site_files = [
            os.path.join(self.app_home, self.app_name, 'static/static_file'),
            os.path.join(self.app_home, self.app_name, 'media/media_file'),
            os.path.join(self.app_home, '%s_uwsgi_params' % self.app_name),
            os.path.join(self.app_home, self.app_name, 'static/base/site_down/index.html'),
            os.path.join(self.app_home, self.app_name)
        ]
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo,
        )
        install_django_app.remove_app(self.app_home, user)
        for s in site_files:
            self.assertFalse(os.path.exists(s), s)
        self.log('INFO: removed %s' % self.app_name)
        self.assertTrue(os.path.exists(self.app_home))


class InstallDjangoAppTest(InstallTest):
    """
    tests InstallDjangoApp methods
    """

    def setUp(self):
        InstallTest.setUp(self)
        self.test_dir = TEST_DIR
        self.pip = os.path.abspath(os.path.join(self.venv, 'bin/pip'))
        self.reqs_file = REQS_FILE
        self.sys_deps_file = SYS_DEPS_FILE
        self.app_user = APP_USER

        if os.path.exists(os.path.join(os.path.dirname(self.log_file), 'test_results')):
            shutil.rmtree(os.path.join(os.path.dirname(self.log_file), 'test_results'))

    def test_installdjangoapp_exits_on_unknown_dist_version(self):
        try:
            InstallDjangoApp('Invalid_dist_version', self.log_file, self.log_level)
        except SystemExit as error:
            self.assertEqual(1, error.code, 'CommandFileUtils exited with: %s' % str(error))
            self.log('CRITICAL: distribution not supported')

    def test_clone_app(self):
        """
        tests clone_app runs git clone command, exits on error and writes to log
        """
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo)
        cmd = ['git', 'clone', self.git_repo]
        msg = 'successfully cloned app_name to %s' % self.app_home
        func = 'clone_app'
        args = (self.app_home,)
        self.run_success([cmd], [msg], func, install_django_app.clone_app, args)
        self.run_error(cmd, func, install_django_app.clone_app, args)

    def test_clone_app_does_nothing_if_app_is_alreday_installed(self):
        """
        tests clone_app does nothing if app is already present and writes to log
        """
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo='https://github.com/bla/tmp.git'
        )
        install_django_app.clone_app('/')
        msg = 'INFO: app tmp already exists at /'
        self.log(msg)

    def test_create_venv(self):
        """
        tests create_venv runs virtualenv command, runs pip upgrade, exits on error and writes to log
        """
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version))
        shutil.rmtree(self.venv)
        if self.dist_version == '14.04':
            cmds = [
                ['virtualenv', '-p', '/usr/bin/' + self.python_version, self.venv],
                [self.pip, 'install', '--upgrade', 'pip']
            ]
        elif self.dist_version == '16.04':
            cmds = [
                ['pyvenv', self.venv],
                [self.pip, 'install', '--upgrade', 'pip']
            ]
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, venv=self.venv)
        msgs = [
            'successfully created virtualenv %s' % self.venv,
            'successfully updated pip for virtualenv %s' % self.venv
        ]
        func = 'create_venv'
        args = ()
        self.run_success(cmds, msgs, func, install_django_app.create_venv, args)
        for cmd in cmds:
            self.run_error(cmd, func, install_django_app.create_venv, args)

    def test_create_venv_does_nothing_if_already_present(self):
        """
        tests create_venv does nothing if venv is already present and writes to log
        """
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version))
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, venv=self.venv)
        install_django_app.create_venv()
        msg = 'INFO: virtualenv %s already exists' % self.venv
        self.log(msg)

    def test_requirements_are_correctly_read(self):
        """"
        tests read_reqs returns correct structure
        """
        reqs_list = [
            ['biopython', '1.66'],
            ['cssselect', '0.9.1'],
            ['Django', '1.9.5'],
            ['django-debug-toolbar', '1.4'],
            ['django-with-asserts', '0.0.1'],
            ['lxml', '3.6.0'],
            ['numpy', '1.11.0'],
            ['psycopg2', '2.6.1'],
            ['requests', '2.9.1'],
            ['sqlparse', '0.1.19'],
        ]
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, venv=self.venv)
        reqs = install_django_app.read_reqs(self.reqs_file)
        self.assertEqual(reqs_list, reqs, format(reqs))

    def test_deps_are_correctly_read(self):
        """
        tests read_sys_deps returns correct structure
        """
        deps_list = [
            'libpq-dev',
            'python3-numpy',
            'libxml2-dev',
            'libxslt1-dev',
            'zlib1g-dev',
        ]
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, venv=self.venv)
        deps = install_django_app.read_sys_deps(self.sys_deps_file)
        self.assertEqual(deps_list, deps, deps)

    def test_check_biopython(self):
        """"
        tests check_biopython calls numpy install command, exits on error and writes to log
        """
        biopython_reqs = 'numpy==1.11.0'
        reqs_list = [
            ['biopython', '1.66'],
            ['cssselect', '0.9.1'],
            ['Django', '1.9.5'],
            ['django-debug-toolbar', '1.4'],
            ['django-with-asserts', '0.0.1'],
            ['lxml', '3.6.0'],
            ['numpy', '1.11.0'],
            ['psycopg2', '2.6.1'],
            ['requests', '2.9.1'],
            ['sqlparse', '0.1.19'],
        ]
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, venv=self.venv)
        cmd = [self.pip, 'install', biopython_reqs]
        msg = 'successfully installed: numpy==1.11.0'
        func = 'check_biopython'
        args = (reqs_list,)
        self.run_success([cmd], [msg], func, install_django_app.check_biopython, args)
        self.run_error(cmd, func, install_django_app.check_biopython, args)

    def test_install_requirements(self):
        """
        tests install_requirements calls install requirements command, exits on error and writes to log
        """
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, venv=self.venv)
        reqs_list = [
            ['biopython', '1.66'],
            ['cssselect', '0.9.1'],
            ['Django', '1.9.5'],
            ['django-debug-toolbar', '1.4'],
            ['django-with-asserts', '0.0.1'],
            ['lxml', '3.6.0'],
            ['numpy', '1.11.0'],
            ['psycopg2', '2.6.1'],
            ['requests', '2.9.1'],
            ['sqlparse', '0.1.19'],
        ]
        cmd = [
            self.pip,
            'install',
            'biopython==1.66',
            'cssselect==0.9.1',
            'Django==1.9.5',
            'django-debug-toolbar==1.4',
            'django-with-asserts==0.0.1',
            'lxml==3.6.0',
            'numpy==1.11.0',
            'psycopg2==2.6.1',
            'requests==2.9.1',
            'sqlparse==0.1.19']
        msg = 'successfully installed: numpy==1.11.0'
        func = 'install_requirements'
        args = (reqs_list,)
        self.run_success([cmd], [msg], func, install_django_app.install_requirements, args)
        self.run_error(cmd, func, install_django_app.install_requirements, args)

    def test_install_sys_deps(self):
        """
        tests install_sys_deps calls apt-get install command, exits on error and writes to log
        """
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        install_django_app = InstallDjangoApp(self.dist_version, self.log_file, self.log_level, venv=self.venv)
        deps = install_django_app.read_sys_deps(self.sys_deps_file)
        cmd = ['apt-get',
               'install',
               '-y',
               'libpq-dev',
               'python3-numpy',
               'libxml2-dev',
               'libxslt1-dev',
               'zlib1g-dev']
        msg = 'successfully installed: libpq-dev python3-numpy libxml2-dev libxslt1-dev zlib1g-dev'
        func = 'install_sys_deps'
        args = (deps,)
        self.run_success([cmd], [msg], func, install_django_app.install_sys_deps, args)
        self.run_error(cmd, func, install_django_app.install_sys_deps, args)

    def test_add_app_to_path(self):
        """
        tests that app is added to python path and message is logged
        """
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version, 'site-packages'))
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )
        install_django_app.add_app_to_path(self.app_home)

        pth = os.path.join(self.venv, 'lib', self.python_version, 'site-packages', 'app_name.pth')
        msg = '%s has been added to python path in %s' % (self.app_name, self.venv)
        with open(pth) as pth_file:
            pth_list = [l for l in pth_file]
            self.assertEqual(['%s\n' % os.path.join(self.app_home, self.app_name)], pth_list, pth_list)
        self.log('INFO: %s' % msg)

    def test_add_app_to_path_does_not_alter_pth_file_when_already_added(self):
        """
        tests that app is added to python path and message is logged
        """
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version, 'site-packages'))
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )
        pth = os.path.join(self.venv, 'lib', self.python_version, 'site-packages', 'app_name.pth')
        msg = '%s has been added to python path in %s' % (self.app_name, self.venv)
        with open(pth, 'w') as pth_file:
            pth_file.write('%s\n' % os.path.join(self.app_home, self.app_name))
        install_django_app.add_app_to_path(self.app_home)
        with open(pth) as pth_file:
            pth_list = [l for l in pth_file]
            self.assertEqual(['%s\n' % os.path.join(self.app_home, self.app_name)], pth_list, pth_list)
        self.log('INFO: %s' % msg)

    def test_copy_config_copies_config_files_to_app(self):
        """
        tests that config files are copied to app and action is logged
        """
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name))
        os.makedirs(os.path.join(os.path.dirname(self.app_home), 'conf.d'))
        conf = [
            {'file': 'settings.json', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'behave.ini', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': '%s_uwsgi.ini' % self.app_name, 'move_to': self.app_home}
        ]
        for f in conf:
            with open(os.path.join(os.path.dirname(self.app_home), 'conf.d', f['file']), 'w') as config:
                config.write('%s file\n' % f['file'])
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )

        install_django_app.copy_config(self.app_home)

        for f in conf:
            self.assertTrue(os.path.isfile(os.path.join(f['move_to'], f['file'])), f['file'])
            with open(os.path.join(f['move_to'], f['file'])) as file:
                file_list = [l for l in file]
                self.assertEqual(['%s file\n' % f['file']], file_list, file_list)
            self.log('INFO: app configuration file %s was copied to app' % f['file'])

    def test_copy_config_does_nothing_when_config_files_are_already_present_in_app(self):
        """
        tests that copy_config does nothing when config files are already present in app
        """
        conf = [
            {'file': 'settings.json', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'behave.ini', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': '%s_uwsgi.ini' % self.app_name, 'move_to': self.app_home}
        ]
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name))
        for f in conf:
            with open(os.path.join(f['move_to'], f['file']), 'w') as file:
                file.write('%s file\n' % f['file'])
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )

        install_django_app.copy_config(self.app_home)

        for f in conf:
            self.log('INFO: %s is already present in %s' % (f['file'], self.app_name))

    def copy_config_exits_when_conf_file_missing(self, conf):
        """
        helper function that tests that copy_config exits when the conf file is missing
        :param conf: missing conf file
        """
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )

        try:
            install_django_app.copy_config(self.app_home)

        except SystemExit as error:
            self.assertEqual(1, error.code, 'copy_config' + ' exited with: ' + str(error))
        self.log('ERROR: could not copy %s' % conf)

    def test_copy_config_exits_on_error(self):
        """
        tests that copy_config exits when conf files are absent and writes to log
        """
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name))
        os.makedirs(os.path.join(os.path.dirname(self.app_home), 'conf.d'))
        self.copy_config_exits_when_conf_file_missing('settings.json')

        with open(os.path.join(os.path.dirname(self.app_home), 'conf.d', 'settings.json'), 'w') as file:
            file.write('settings.json\n')

        self.copy_config_exits_when_conf_file_missing('%s_uwsgi.ini' % self.app_name)

        with open(os.path.join(os.path.dirname(self.app_home), 'conf.d', '%s_uwsgi.ini' % self.app_name), 'w') as file:
            file.write('uwsgi.ini\n')

        self.copy_config_exits_when_conf_file_missing('behave.ini')

    def test_migrate(self):
        """
        tests that run_migration runs the right command from the right directory and writes to log.
        """
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo)
        cmds = [
            [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'makemigrations',
                '--settings', 'settings_admin'
            ],
            [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'migrate',
                '--settings', 'settings_admin'
            ]
        ]
        msg = ['successfully ran makemigrations', 'successfully migrated %s' % self.app_name]
        cwd = os.path.join(self.app_home, self.app_name)
        func = 'migrate'
        args = (self.app_home,)
        self.run_success(cmds, msg, func, install_django_app.run_migrations, args)
        self.run_cwd(cwd, func, install_django_app.run_migrations, args)
        for c in cmds:
            self.run_error(c, func, install_django_app.run_migrations, args)

    def test_run_app_tests(self):
        """
        tests that run_tests runs the right command from the right directory and writes to log
        """
        now = datetime.datetime.utcnow()
        os.makedirs(os.path.join(os.path.dirname(self.log_file), 'test_results'), exist_ok=True)
        os.makedirs(os.path.join(self.app_home, self.app_name), exist_ok=True)
        log_file_now = os.path.join(
            os.path.dirname(self.log_file), 'test_results', 'test_%s.log' % (now.strftime('%Y%m%d-%H%M%S'))
        )
        with open(log_file_now, 'w') as log:
            log.write('OK')
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )
        cmds = [
            [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'test',
                '--settings', 'settings_admin'
            ],
            [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'behave',
                '--tags', '~@skip', '--tags', '~@pending', '--no-skipped', '--junit', '--settings', 'settings_admin'
            ]
        ]
        msgs = [
            'successfully ran unit tests for %s' % self.app_name,
            'successfully ran functional tests for %s' % self.app_name,
        ]
        cwd = os.path.join(self.app_home, self.app_name)
        func = 'run_tests'
        args = (self.app_home,)
        self.run_success(cmds, msgs, func, install_django_app.run_tests, args)
        self.run_cwd(cwd, func, install_django_app.run_tests, args)
        for c in cmds:
            self.run_error(c, func, install_django_app.run_tests, args)

    def test_run_app_tests_with_acceptance_tests(self):
        """
        tests that run_tests runs the right command, excluding acceptance tests, from the right directory and writes to
        log
        """
        now = datetime.datetime.utcnow()
        os.makedirs(os.path.join(os.path.dirname(self.log_file), 'test_results'), exist_ok=True)
        os.makedirs(os.path.join(self.app_home, self.app_name, 'acceptance_tests'), exist_ok=True)
        log_file_now = os.path.join(
            os.path.dirname(self.log_file), 'test_results', 'test_%s.log' % (now.strftime('%Y%m%d-%H%M%S'))
        )
        with open(log_file_now, 'w') as log:
            log.write('OK')
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )
        cmds = [
            [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'test', '--exclude-dir', './acceptance_tests',
                '--settings', 'settings_admin'
            ],
            [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'behave',
                '--tags', '~@skip', '--tags', '~@pending', '--no-skipped', '--junit', '--settings', 'settings_admin'
            ]
        ]
        msgs = [
            'successfully ran unit tests for %s' % self.app_name,
            'successfully ran functional tests for %s' % self.app_name,
        ]
        cwd = os.path.join(self.app_home, self.app_name)
        func = 'run_tests'
        args = (self.app_home,)
        self.run_success(cmds, msgs, func, install_django_app.run_tests, args)
        self.run_cwd(cwd, func, install_django_app.run_tests, args)
        for c in cmds:
            self.run_error(c, func, install_django_app.run_tests, args)

    def test_run_app_tests_with_pending_tests(self):
        """
        tests that run_tests runs the right command, excluding acceptance tests and pending tests, from the right
        directory and writes to log
        """
        now = datetime.datetime.utcnow()
        os.makedirs(os.path.join(os.path.dirname(self.log_file), 'test_results'), exist_ok=True)
        os.makedirs(os.path.join(self.app_home, self.app_name, 'acceptance_tests'), exist_ok=True)
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name, 'functional_tests', 'pending_tests'),
                    exist_ok=True)
        os.makedirs(os.path.join(self.app_home, self.app_name, 'base', 'unit_tests', 'pending_tests'), exist_ok=True)
        log_file_now = os.path.join(
            os.path.dirname(self.log_file), 'test_results', 'test_%s.log' % (now.strftime('%Y%m%d-%H%M%S'))
        )
        with open(log_file_now, 'w') as log:
            log.write('OK')
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )
        cmds = [
            [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'test',
                '--exclude-dir', './acceptance_tests',
                '--exclude-dir', './base/unit_tests/pending_tests',
                '--exclude-dir', './%s/functional_tests/pending_tests' % self.app_name,
                '--settings', 'settings_admin'
            ],
            [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'behave',
                '--tags', '~@skip', '--tags', '~@pending', '--no-skipped', '--junit', '--settings', 'settings_admin'
            ]
        ]
        msgs = [
            'successfully ran unit tests for %s' % self.app_name,
            'successfully ran functional tests for %s' % self.app_name,
        ]
        cwd = os.path.join(self.app_home, self.app_name)
        func = 'run_tests'
        args = (self.app_home,)
        self.run_success(cmds, msgs, func, install_django_app.run_tests, args)
        self.run_cwd(cwd, func, install_django_app.run_tests, args)
        for c in cmds:
            self.run_error(c, func, install_django_app.run_tests, args)

    def test_run_tests_exits_on_failed_test(self):
        """
        tests that run_tests exits when app tests fail and writes to log.
        """
        now = datetime.datetime.utcnow()
        yesterday = now - datetime.timedelta(days=1)
        os.makedirs(os.path.join(os.path.dirname(self.log_file), 'test_results'), exist_ok=True)
        os.makedirs(os.path.join(self.app_home, self.app_name), exist_ok=True)
        log_file_now = os.path.join(
            os.path.dirname(self.log_file), 'test_results', 'test_%s.log' % (now.strftime('%Y%m%d-%H%M%S'))
        )
        log_file_yesterday = os.path.join(
            os.path.dirname(self.log_file), 'test_results', 'test_%s.log' % (yesterday.strftime('%Y%m%d-%H%M%S'))
        )
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo
        )
        with open(log_file_now, 'w') as log:
            log.write('FAILED')
        with open(log_file_yesterday, 'w') as log:
            log.write('OK')
        try:
            install_django_app.run_tests(self.app_home)
            self.fail('run_tests did not exit on failed test')
        except SystemExit as error:
            self.assertEqual(1, error.code, 'run_tests exited with: %s' % str(error))
            self.log('ERROR: %s tests failed' % self.app_name)

    def test_run_tests_log_file(self):
        """
        tests that run_tests logs to the right file.
        """
        os.makedirs(os.path.join(self.app_home, self.app_name), exist_ok=True)
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo,
        )
        install_django_app.run_tests(self.app_home)
        if self.dist_version == '14.04':
            args, kwargs = subprocess.check_call.call_args
        if self.dist_version == '16.04':
            args, kwargs = subprocess.run.call_args
        self.assertTrue(isinstance(kwargs['stderr'], io.TextIOWrapper), kwargs['stderr'])
        log_file_regex = re.compile('%s/test_results/test_\d{8}-\d{6}\.log' % os.path.dirname(self.log_file))
        self.assertTrue(
            log_file_regex.match(kwargs['stderr'].name), kwargs['stderr'].name
        )

    def test_collect_static(self):
        """
        tests that collect_static runs the right command and writes to log
        """
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level, venv=self.venv, git_repo=self.git_repo)
        cmd = [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'collectstatic', '-c',
                '--noinput', '--settings', 'settings_admin'
        ]
        msg = 'successfully collected static for %s' % self.app_name
        cwd = os.path.join(self.app_home, self.app_name)
        func = 'collect_static'
        args = (self.app_home,)
        self.run_success([cmd], [msg], func, install_django_app.collect_static, args)
        self.run_cwd(cwd, func, install_django_app.run_migrations, args)
        self.run_error(cmd, func, install_django_app.run_migrations, args)

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    def test_install_app(self, copy_config_mock, add_app_to_path_mock):
        """
        tests install_app runs commands and writes to log
        """
        biopython_reqs = 'numpy==1.11.0'
        user = getpass.getuser()
        install_django_app = InstallDjangoApp(
            self.dist_version, self.log_file, self.log_level,
            venv=self.venv, git_repo=self.git_repo
        )
        ret = install_django_app.install_app(self.app_home, user, self.sys_deps_file, self.reqs_file)
        cmds = [
            ['git', 'clone', self.git_repo],
            [self.pip, 'install', biopython_reqs],
            [
                self.pip,
                'install',
                'biopython==1.66',
                'cssselect==0.9.1',
                'Django==1.9.5',
                'django-debug-toolbar==1.4',
                'django-with-asserts==0.0.1',
                'lxml==3.6.0',
                'numpy==1.11.0',
                'psycopg2==2.6.1',
                'requests==2.9.1',
                'sqlparse==0.1.19'],
            ['apt-get',
             'install',
             '-y',
             'libpq-dev',
             'python3-numpy',
             'libxml2-dev',
             'libxslt1-dev',
             'zlib1g-dev'],
        ]
        if self.dist_version == '14.04':
            calls = [args for args, kwargs in subprocess.check_call.call_args_list]
            cmds.append(['virtualenv', '-p', '/usr/bin/python3.4', self.venv])
        else:
            if self.dist_version == '16.04':
                calls = [args for args, kwargs in subprocess.run.call_args_list]
                cmds.append(['pyvenv', self.venv])

        self.assertEqual(0, ret, str(ret))
        for cmd in cmds:
            self.assertTrue((cmd,) in calls, calls)

        msgs = [
            'INFO: successfully cloned app_name to %s' % self.app_home,
            'INFO: successfully created virtualenv %s' % VENV,
            'INFO: successfully installed: numpy==1.11.0',
            'INFO: successfully installed: biopython(1.66) cssselect(0.9.1) Django(1.9.5) django-debug-toolbar(1.4) '
            'django-with-asserts(0.0.1) lxml(3.6.0) numpy(1.11.0) psycopg2(2.6.1) requests(2.9.1) sqlparse(0.1.19)',
            'INFO: successfully installed: libpq-dev python3-numpy libxml2-dev libxslt1-dev zlib1g-dev',
            'INFO: app configuration file settings.json was copied to app',
            'INFO: app configuration file behave.ini was copied to app',
            'INFO: changed ownership of %s to %s:%s' % (self.app_home, user, user),
            'INFO: changed permissions of %s files to 400 and directories to 500' % self.app_home,
            'INFO: changed ownership of %s to %s:%s' % (os.path.dirname(self.venv), user, user),
            'INFO: changed permissions of %s to %s' % (os.path.dirname(self.venv), '700'),
            'INFO: changed permissions of %s to %s' % (self.venv, '700'),
            'INFO: install django app exited with code 0'
        ]
        for m in msgs:
            self.log(m)

        self.assertEqual([call(self.app_home, behave=True, uwsgi=True)], copy_config_mock.mock_calls, copy_config_mock.mock_calls)
        self.assertEqual([call(self.app_home)], add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)


class TestInstallDjangoAppMain(InstallTest):
    """
    Tests django_app.main()
    """
    def setUp(self):
        InstallTest.setUp(self)
        self.app_user = APP_USER
        self.fifo_dir = FIFO_DIR

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_run_main_install(self, own_app_mock, copy_config_mock, add_app_to_path_mock):
        """
        tests run main script with install parameter returns no error
        """
        sys.argv = ['djangoapp', '-i', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.assertEqual(
            [call(self.app_home, self.app_user, self.app_user),
             call(os.path.dirname(self.venv), self.app_user, self.app_user)],
            own_app_mock.mock_calls,
            own_app_mock.mock_calls
        )
        self.assertEqual([call(self.app_home, behave=True, uwsgi=True)], copy_config_mock.mock_calls, copy_config_mock.mock_calls)
        self.assertEqual([call(self.app_home)], add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)
        msgs = [
            'INFO: successfully cloned app_name to %s' % self.app_home,
            'INFO: successfully created virtualenv %s' % self.venv,
            'INFO: successfully installed: numpy==1.11.0',
            'INFO: successfully installed: biopython(1.66) cssselect(0.9.1) Django(1.9.5) django-debug-toolbar(1.4) '
            'django-with-asserts(0.0.1) lxml(3.6.0) numpy(1.11.0) psycopg2(2.6.1) requests(2.9.1) sqlparse(0.1.19)',
            'INFO: successfully installed: libpq-dev python3-numpy libxml2-dev libxslt1-dev zlib1g-dev',
            'INFO: app configuration file settings.json was copied to app',
            'INFO: app configuration file behave.ini was copied to app',
            'INFO: changed ownership of %s to %s:%s' % (self.app_home, 'app_user', 'app_user'),
            'INFO: changed permissions of %s files to 400 and directories to 500' % self.app_home,
            'INFO: changed ownership of %s to %s:%s' % (os.path.dirname(self.venv), 'app_user', 'app_user'),
            'INFO: changed permissions of %s to %s' % (os.path.dirname(self.venv), '700'),
            'INFO: changed permissions of %s to %s' % (self.venv, '700'),
            'INFO: install django app exited with code 0'
        ]
        for m in msgs:
            self.log(m)

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_run_main_install_migrate_collect_static_and_test(self, own_app_mock, copy_config_mock, add_app_to_path_mock):
        """
        tests run main script with install, migrate, collect-static and run-tests parameters returns no error
        """
        mocks.alt_bool = Alternate([False])
        sys.argv = ['djangoapp', '-imts', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.assertEqual(
            [call(self.app_home, self.app_user, self.app_user),
             call(os.path.dirname(self.venv), self.app_user, self.app_user)],
            own_app_mock.mock_calls,
            own_app_mock.mock_calls
        )
        self.assertEqual([call(self.app_home, behave=True, uwsgi=True)],
                         copy_config_mock.mock_calls,
                         copy_config_mock.mock_calls)
        self.assertEqual([call(self.app_home)], add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)
        msgs = [
            'INFO: successfully cloned app_name to %s' % self.app_home,
            'INFO: successfully created virtualenv %s' % self.venv,
            'INFO: successfully installed: numpy==1.11.0',
            'INFO: successfully installed: biopython(1.66) cssselect(0.9.1) Django(1.9.5) django-debug-toolbar(1.4) '
            'django-with-asserts(0.0.1) lxml(3.6.0) numpy(1.11.0) psycopg2(2.6.1) requests(2.9.1) sqlparse(0.1.19)',
            'INFO: successfully installed: libpq-dev python3-numpy libxml2-dev libxslt1-dev zlib1g-dev',
            'INFO: app configuration file settings.json was copied to app',
            'INFO: app configuration file behave.ini was copied to app',
            'INFO: changed ownership of %s to %s:%s' % (self.app_home, 'app_user', 'app_user'),
            'INFO: changed permissions of %s files to 400 and directories to 500' % self.app_home,
            'INFO: changed ownership of %s to %s:%s' % (os.path.dirname(self.venv), 'app_user', 'app_user'),
            'INFO: changed permissions of %s to %s' % (os.path.dirname(self.venv), '700'),
            'INFO: changed permissions of %s to %s' % (self.venv, '700'),
            'INFO: successfully ran makemigrations',
            'INFO: successfully migrated %s' % self.app_name,
            'INFO: successfully collected static for %s' % self.app_name,
            'INFO: successfully ran unit tests for %s' % self.app_name,
            'INFO: successfully ran functional tests for %s' % self.app_name,
            'INFO: install django app exited with code 0',
        ]
        for m in msgs:
            self.log(m)

    def test_run_main_start_celery(self):
        """
        tests run main script with celery start parameter returns no error
        """
        sys.argv = ['djangoapp', '-c', 'start', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        msg = 'INFO: started celery and beat'
        self.log(msg)

    def test_run_main_stop_celery(self):
        """
        tests run main script with celery stop parameter returns no error
        """
        os.makedirs(self.celery_pid_path, exist_ok=True)
        with open(os.path.join(self.celery_pid_path, 'w1.pid'), 'w') as pid:
            pid.write('celery pid')
        sys.argv = ['djangoapp', '-c', 'stop', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        msg = 'INFO: stopped celery and beat'
        self.log(msg)

    @mock.patch.object(InstallDjangoApp, 'stop_celery', side_effect=stop_celery_mock)
    def test_run_main_restart_celery(self, stop_celery_mock):
        """
        tests run main script with celery stop parameter returns no error
        """
        os.makedirs(self.celery_pid_path, exist_ok=True)
        with open(os.path.join(self.celery_pid_path, 'w1.pid'), 'w') as pid:
            pid.write('celery pid')
        sys.argv = ['djangoapp', '-c', 'restart', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.assertEqual(
            [call(self.app_home)],
            stop_celery_mock.mock_calls,
            stop_celery_mock.mock_calls
        )
        msgs = ['INFO: stopped celery and beat', 'INFO: started celery and beat']
        for msg in msgs:
            self.log(msg)

    @mock.patch.object(InstallDjangoApp, 'check_process', side_effect=check_process_mock)
    def test_run_main_start_uwsgi(self, check_process_mock):
        """
        tests run main script with uwsgi start parameter returns no error
        """
        mocks.alt_bool = Alternate([False])
        sys.argv = ['djangoapp', '-u', 'start', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.assertEqual(
            [call('uwsgi')],
            check_process_mock.mock_calls,
            check_process_mock.mock_calls
        )
        msgs = [
            'INFO: started uwsgi server',
            'INFO: changed permissions of %s to %s' % (os.path.join('/tmp', self.app_name), '777'),
        ]
        for m in msgs:
            self.log(m)

    @mock.patch.object(InstallDjangoApp, 'check_process', side_effect=check_process_mock)
    def test_run_main_stop_uwsgi(self, check_process_mock):
        """
        tests that main with parameter -u stop stops uwsgi
        """
        os.makedirs(os.path.join(self.fifo_dir, self.app_name))
        mocks.alt_bool = Alternate([True])
        sys.argv = ['djangoapp', '-u', 'stop', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.assertEqual(
            [call('uwsgi')],
            check_process_mock.mock_calls,
            check_process_mock.mock_calls
        )
        self.log('INFO: stopped uwsgi server')

    @mock.patch.object(InstallDjangoApp, 'check_process', side_effect=check_process_mock)
    @mock.patch('djangoapp.time.sleep')
    def test_run_main_restart_uwsgi(self, sleep_mock, check_process_mock):
        """
        tests that main with parameter -u stop stops uwsgi
        """
        os.makedirs(os.path.join(self.fifo_dir, self.app_name))
        mocks.alt_bool = Alternate([True, False])
        sys.argv = ['djangoapp', '-u', 'restart', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.assertEqual([call(1)], sleep_mock.mock_calls, sleep_mock.mock_calls)
        self.assertEqual(
            [call('uwsgi')] * 2,
            check_process_mock.mock_calls,
            check_process_mock.mock_calls
        )
        msgs = [
            'INFO: stopped uwsgi server',
            'INFO: started uwsgi server',
            'INFO: changed permissions of %s to %s' % (os.path.join('/tmp', self.app_name), '777')
        ]
        for m in msgs:
            self.log(m)

    @mock.patch.object(InstallDjangoApp, 'check_process', side_effect=check_process_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_run_main_remove_app(self, own_app_mock, check_process_mock):
        """
        tests that main with parameter -x removes app
        """
        clone_app_mock(self.app_home)
        os.makedirs(os.path.join(self.fifo_dir, self.app_name))
        mocks.alt_bool = Alternate([True])
        sys.argv = ['djangoapp', '-x', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.assertEqual(
            [call(self.app_home, self.app_user, self.app_user)],
            own_app_mock.mock_calls,
            own_app_mock.mock_calls
        )
        self.assertEqual(
            [call('uwsgi')],
            check_process_mock.mock_calls,
            check_process_mock.mock_calls
        )
        msgs = [
            'INFO: stopped uwsgi server',
            'INFO: removed %s' % self.app_name,
        ]
        for m in msgs:
            self.log(m)

    def test_run_main_create_venv(self):
        """
        tests that main with parameter -x removes app
        """
        clone_app_mock(self.app_home)
        os.makedirs(os.path.join(self.fifo_dir, self.app_name))
        mocks.alt_bool = Alternate([True])
        sys.argv = ['djangoapp', '-e', '-l', 'DEBUG']
        djangoapp.DIST_VERSION = self.dist_version
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))

        msgs = [
            'INFO: successfully created virtualenv %s' % self.venv,
            'INFO: successfully updated pip for virtualenv %s' % self.venv,
        ]
        for m in msgs:
            self.log(m)
