import os
import sys
import re
import unittest
from unittest import mock
from unittest.mock import call
import webserver
from djangoapp import InstallDjangoApp
from webserver import main, ServeStatic
from tests.helpers import remove_test_dir
from tests.conf_tests import GIT_REPO, APP_HOME_TMP, WEB_USER, WEBSERVER_USER, STATIC_PATH, VENV
from tests.conf_tests import MEDIA_PATH, UWSGI_PATH, DOWN_PATH, TEST_DIR, NGINX_CONF, REQS_FILE, SYS_DEPS_FILE
from tests.runandlogtest import RunAndLogTest
from utilities.commandfileutils import CommandFileUtils
from tests.mocks.commandfileutils_mocks import own_app_mock
from tests.mocks.installdjangoapp_mocks import clone_app_mock, add_app_to_path_mock, copy_config_mock

__author__ = 'Stefan Dieterle'


class StaticTest(RunAndLogTest):
    def setUp(self):
        RunAndLogTest.setUp(self)
        self.app_home = APP_HOME_TMP
        self.web_user = WEB_USER
        self.webserver_user = WEBSERVER_USER
        self.static_path = STATIC_PATH
        self.media_path = MEDIA_PATH
        self.uwsgi_path = UWSGI_PATH
        self.down_path = DOWN_PATH
        self.nginx_conf = NGINX_CONF
        self.git_repo = GIT_REPO
        p = re.compile('https://github.com/[\w\-]+/(\w+)\.git')
        self.app_name = p.match(self.git_repo).group(1)
        self.reqs_file = REQS_FILE
        self.sys_deps_file = SYS_DEPS_FILE
        self.venv = VENV

    def make_site_confs(self, initial_state):
        """
        creates the conf files in the specified initial state
        :param initial_state: up or down
        :return:
        """
        if initial_state == 'up':
            enabled = self.app_name
            available = '%s_down' % self.app_name
        elif initial_state == 'down':
            enabled = '%s_down' % self.app_name
            available = self.app_name
        os.makedirs(os.path.join(self.nginx_conf, 'sites-available'))
        os.makedirs(os.path.join(self.nginx_conf, 'sites-enabled'))
        with open(
                os.path.join(self.nginx_conf, 'sites-enabled', '%s.conf' % enabled), 'w'
        ) as site_conf:
            site_conf.write('%s\n' % enabled)
        with open(
                os.path.join(self.nginx_conf, 'sites-available', '%s.conf' % available), 'w'
        ) as site_down_conf:
            site_down_conf.write('%s\n' % available)


class ServeStaticTest(StaticTest):
    """
    tests ServeStatic functionality
    """

    def setUp(self):
        StaticTest.setUp(self)
        self.test_dir = TEST_DIR

    def move(self, from_path, to_path, file_type, msg, ret):
        """
        helper for testing move moves static files, removes temp app directory and writes to log
        """
        if file_type == 'dir':
            static_type = os.path.basename(from_path)
            static_file = os.path.join(to_path, '%s_file' % static_type)

        elif file_type == 'file':
            static_type = os.path.basename(from_path)
            static_file = os.path.join(to_path, static_type)

        else:
            static_type = ''
            static_file = ''

        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, venv=self.venv)
        move = serve_django_static.move(
            from_path, to_path, file_type, reqs_file=self.reqs_file, sys_deps_file=self.sys_deps_file
        )

        self.assertEqual(move, ret)
        self.assertTrue(os.path.isfile(static_file))
        with open(static_file) as static:
            static_file_list = [s for s in static]
            self.assertEqual(['%s stuff\n' % static_type], static_file_list, static_file_list)
        self.log(msg)

    def test_servestatic_exits_on_unknown_dist_version(self):
        try:
            ServeStatic('Invalid_dist_version', self.app_home, self.log_file, self.log_level)
        except SystemExit as error:
            self.assertEqual(1, error.code, 'CommandFileUtils exited with: %s' % str(error))
            self.log('CRITICAL: distribution not supported')

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    def test_move_dirs(self, clone_app_mock, own_app_mock, copy_config_mock, add_app_to_path_mock):
        """
        tests move moves static files, removes temp app directory and writes to log
        """
        dirs = [['static', self.static_path], ['media', self.media_path]]
        for d, path in dirs:
            os.makedirs(path)
        os.makedirs(os.path.join(self.app_home, self.app_name))

        for d, path in dirs:
            msg = 'INFO: %s moved to %s' % (d, path)
            self.move(os.path.join(self.app_home, self.app_name, d), path, 'dir', msg, 0)
        self.assertEqual([call(self.app_home)] * 2, clone_app_mock.mock_calls, clone_app_mock.mock_calls)
        self.assertEqual([call(self.app_home, behave=False, uwsgi=False)] * 2, copy_config_mock.mock_calls, copy_config_mock.mock_calls)
        self.assertEqual([call(self.app_home)] * 2, add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)
        self.assertEqual(
            [
                call(self.app_home, self.web_user, self.web_user),
                call(os.path.dirname(self.venv), self.web_user, self.web_user),
            ] * 2, own_app_mock.mock_calls, own_app_mock.mock_calls)

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    def test_move_dirs_handles_existing_content(self, clone_app_mock, own_app_mock, copy_config_mock,
                                                add_app_to_path_mock):
        """
        tests move does not move static files and does not clone app when files
        are already present in destination directory
        """
        dirs = [['static', self.static_path], ['media', self.media_path]]
        for d, path in dirs:
            os.makedirs(path)
            with open(os.path.join(path, '%s_file' % d), 'w') as static:
                static.write('%s stuff\n' % d)
        os.makedirs(os.path.join(self.app_home, self.app_name))

        for d, path in dirs:
            msg = 'INFO: content already present in %s' % path
            self.move(os.path.join(self.app_home, self.app_name, d), path, 'dir', msg, 0)
        self.assertEqual([], clone_app_mock.mock_calls, clone_app_mock.mock_calls)
        self.assertEqual([], copy_config_mock.mock_calls, copy_config_mock.mock_calls)
        self.assertEqual([], add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)
        self.assertEqual([], own_app_mock.mock_calls, own_app_mock.mock_calls)

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    def test_move_file(self, clone_app_mock, own_app_mock, copy_config_mock, add_app_to_path_mock):
        """
        tests move moves files and writes to log
        """
        os.makedirs(self.uwsgi_path)
        msg = 'INFO: %s moved to %s' % ('uwsgi_params', self.uwsgi_path)
        self.move(
            os.path.join(self.app_home, self.app_name, 'uwsgi_params'),
            self.uwsgi_path, 'file', msg, 0
        )
        self.assertEqual([call(self.app_home)], clone_app_mock.mock_calls, clone_app_mock.mock_calls)
        self.assertEqual([call(self.app_home, behave=False, uwsgi=False)], copy_config_mock.mock_calls, copy_config_mock.mock_calls)
        self.assertEqual([call(self.app_home)], add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)
        self.assertEqual([
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
        ], own_app_mock.mock_calls, own_app_mock.mock_calls)

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    def test_move_handles_already_existing_static_dir(self, clone_app_mock, own_app_mock, copy_config_mock,
                                                      add_app_to_path_mock):
        """
        tests that move moves static files even if static directory already exists
        """
        to_dir = os.path.join(self.app_home, self.app_name, 'static')
        os.makedirs(to_dir)
        os.makedirs(self.static_path)
        with open(os.path.join(self.app_home, self.app_name, 'static/static_file'), 'w') as static_file:
            static_file.write('static stuff\n')

        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, sys_deps_file=self.sys_deps_file,
                                          reqs_file=self.reqs_file, venv=self.venv)
        serve_django_static.move(to_dir, self.static_path, 'dir')

        self.assertTrue(os.path.isfile(os.path.join(self.static_path, 'static_file')))
        with open(os.path.join(self.static_path, 'static_file')) as static_file:
            static_file_list = [s for s in static_file]
            self.assertEqual(['static stuff\n'], static_file_list, static_file_list)
        self.log('INFO: static moved to %s' % self.static_path)
        self.assertEqual([call(self.app_home)], clone_app_mock.mock_calls, clone_app_mock.mock_calls)
        self.assertEqual([call(self.app_home, behave=False, uwsgi=False)], copy_config_mock.mock_calls, copy_config_mock.mock_calls)
        self.assertEqual([call(self.app_home)], add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)
        self.assertEqual([
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user)
        ], own_app_mock.mock_calls, own_app_mock.mock_calls)

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    def test_move_file_handles_existing_file(self, clone_app_mock, own_app_mock, copy_config_mock,
                                             add_app_to_path_mock):
        """
        tests move does not move files when they are already present in destination directory
        """
        os.makedirs(self.uwsgi_path)
        with open(os.path.join(self.uwsgi_path, 'uwsgi_params'), 'w') as static:
            static.write('uwsgi_params stuff\n')
        msg = 'INFO: %s is already present in %s' % ('uwsgi_params', self.uwsgi_path)
        self.move(
            os.path.join(self.app_home, self.app_name, 'uwsgi_params'),
            self.uwsgi_path, 'file', msg, 0
        )
        self.assertEqual([], clone_app_mock.mock_calls, clone_app_mock.mock_calls)
        self.assertEqual([], copy_config_mock.mock_calls, copy_config_mock.mock_calls)
        self.assertEqual([], add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)
        self.assertEqual([], own_app_mock.mock_calls, own_app_mock.mock_calls)

    @mock.patch.object(InstallDjangoApp, 'add_app_to_path', side_effect=add_app_to_path_mock)
    @mock.patch.object(InstallDjangoApp, 'copy_config', side_effect=copy_config_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    def test_move_exits_on_error(self, clone_app_mock, own_app_mock, copy_config_mock, add_app_to_path_mock):
        """
        tests move exits on error and writes to log
        """
        os.makedirs(os.path.dirname(self.static_path))
        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo)

        try:
            serve_django_static.move(os.path.join(self.app_home, self.app_name, 'static'), self.static_path, 'dir')

        except SystemExit as error:
            self.assertEqual(1, error.code, 'move exited with: ' + str(error))
            self.log('ERROR: file not found: %s' % os.path.join(self.app_home, self.app_name, 'static'))
        self.assertEqual([], clone_app_mock.mock_calls, clone_app_mock.mock_calls)
        self.assertEqual([], copy_config_mock.mock_calls, copy_config_mock.mock_calls)
        self.assertEqual([], add_app_to_path_mock.mock_calls, add_app_to_path_mock.mock_calls)
        self.assertEqual([], own_app_mock.mock_calls, own_app_mock.mock_calls)

    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_serve_static(self, own_app_mock, clone_app_mock):
        """
        tests serve_static creates app_home and static directories and runs install app and collectstatic commands,
        writes to log
        """
        user = 'web_user'
        os.makedirs(self.static_path)
        os.makedirs(self.media_path)
        os.makedirs(self.uwsgi_path)
        os.makedirs(self.down_path)
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name))
        os.makedirs(os.path.join(os.path.dirname(self.app_home), 'conf.d'))
        conf = [
            {'file': 'settings.json', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'behave.ini', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'settings_admin.py', 'move_to': os.path.join(self.app_home, self.app_name, self.app_name)},
            {'file': '%s_uwsgi.ini' % self.app_name, 'move_to': self.app_home}
        ]
        for f in conf:
            with open(os.path.join(os.path.dirname(self.app_home), 'conf.d', f['file']), 'w') as config:
                config.write('%s file\n' % f['file'])
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version, 'site-packages'))

        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, sys_deps_file=self.sys_deps_file,
                                          reqs_file=self.reqs_file, venv=self.venv)
        ret = serve_django_static.serve_static(
            user, user, self.down_path, self.static_path, self.media_path, self.uwsgi_path
        )

        # check that serve_static returns no error
        self.assertEqual(0, ret, str(ret))

        # check that temp path where app was cloned to was removed
        self.assertFalse(os.path.exists(self.app_home))

        # check that static, media and uwsgi files and directory structures have been correctly moved
        fds = [
            {'name': 'index.html', 'path': self.down_path, 'file': 'index.html'},
            {'name': 'static', 'path': self.static_path, 'file': 'static_file'},
            {'name': 'media', 'path': self.media_path, 'file': 'media_file'},
            {'name': 'uwsgi_params', 'path': self.uwsgi_path, 'file': 'uwsgi_params'},
        ]
        for f in fds:
            self.assertTrue(os.path.isdir(f['path']), f['path'])
            self.assertTrue(os.path.isfile(os.path.join(f['path'], f['file'])), f['file'])
            with open(os.path.join(f['path'], f['file'])) as static:
                static_list = [s for s in static]
                self.assertEqual(['%s stuff\n' % f['name']], static_list, static_list)

        # check calls to mocks
        self.assertEqual([
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.down_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.static_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.media_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.uwsgi_path, self.web_user, self.web_user),
        ], own_app_mock.mock_calls, own_app_mock.mock_calls)
        self.assertEqual([call(self.app_home)] * 4, clone_app_mock.mock_calls, clone_app_mock.mock_calls)

        # check that all expected log entries are present
        # for install_app and collect_static
        msgs = [
            'INFO: successfully cloned app_name to %s' % self.app_home,
            'INFO: virtualenv %s already exists' % self.venv,
            'INFO: successfully installed: numpy==1.11.0',
            'INFO: successfully installed: biopython(1.66) cssselect(0.9.1) Django(1.9.5) django-debug-toolbar(1.4) '
            'django-with-asserts(0.0.1) lxml(3.6.0) numpy(1.11.0) psycopg2(2.6.1) requests(2.9.1) sqlparse(0.1.19)',
            'INFO: successfully installed: libpq-dev python3-numpy libxml2-dev libxslt1-dev zlib1g-dev',
            'INFO: app configuration file settings.json was copied to app',
            'INFO: changed permissions of %s to %s' % (os.path.dirname(self.venv), '700'),
            'INFO: changed permissions of %s to %s' % (self.venv, '700'),
            'INFO: successfully collected static for %s' % self.app_name,
        ]
        for m in msgs:
            self.log(m)

        # self.log('INFO: successfully cloned app_name to %s' % self.app_home)

        # for move
        for f in fds:
            self.log('INFO: %s moved to %s' % (f['name'], f['path']))

        # for own and permissions
        own_and_perm_msgs = [
            'changed ownership of %s to %s:%s' % (self.static_path, user, user),
            'changed permissions of %s files to 440 and directories to 550' % self.static_path,
        ]
        for o in own_and_perm_msgs:
            self.log('INFO: %s' % o)

        # for successful exit
        self.log('INFO: serve static exited with code 0')

    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_remove_static(self, own_app_mock, clone_app_mock):
        """
        tests that remove_static removes the static directories and files, writes to log
        """
        user = 'web_user'
        os.makedirs(self.static_path)
        os.makedirs(self.media_path)
        os.makedirs(self.uwsgi_path)
        os.makedirs(self.down_path)
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name))
        os.makedirs(os.path.join(os.path.dirname(self.app_home), 'conf.d'))
        conf = [
            {'file': 'settings.json', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'behave.ini', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'settings_admin.py', 'move_to': os.path.join(self.app_home, self.app_name, self.app_name)},
            {'file': '%s_uwsgi.ini' % self.app_name, 'move_to': self.app_home}
        ]
        for f in conf:
            with open(os.path.join(os.path.dirname(self.app_home), 'conf.d', f['file']), 'w') as config:
                config.write('%s file\n' % f['file'])
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version, 'site-packages'))

        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, sys_deps_file=self.sys_deps_file,
                                          reqs_file=self.reqs_file, venv=self.venv)
        serve_django_static.serve_static(
            user, user, self.down_path, self.static_path, self.media_path, self.uwsgi_path
        )

        serve_django_static.remove_static(self.down_path, self.static_path, self.media_path, self.uwsgi_path)

        # check calls to mocks
        self.assertEqual([
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.down_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.static_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.media_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.uwsgi_path, self.web_user, self.web_user),
        ], own_app_mock.mock_calls, own_app_mock.mock_calls)
        self.assertEqual([call(self.app_home)] * 4, clone_app_mock.mock_calls, clone_app_mock.mock_calls)

        fds = [
            {'path': self.down_path, 'file': 'index.html'},
            {'path': self.static_path, 'file': 'static_file'},
            {'path': self.media_path, 'file': 'media_file'},
            {'path': self.uwsgi_path, 'file': 'uwsgi_params'},
        ]
        for f in fds:
            self.assertTrue(os.path.exists(f['path']), '%s was removed' % f['path'])
            self.assertFalse(os.path.exists(os.path.join(f['path'], f['file'])), '%s was not removed' % f['file'])
            self.log('INFO: removed files in %s' % f['path'])

    def test_remove_static_adds_static_paths_if_missing(self):
        """
        tests that remove_static adds static paths if missing and writes to log
        """
        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo)
        serve_django_static.remove_static(self.down_path, self.static_path, self.media_path, self.uwsgi_path)

        fds = [
            self.down_path,
            self.static_path,
            self.media_path,
            self.uwsgi_path,
        ]
        for f in fds:
            self.assertTrue(os.path.exists(f), '%s not present' % f)
            self.log('INFO: added missing path %s' % f)

    def test_site_toggle_down(self):
        """
        tests that site_toggle_up_down removes the site.conf file from enabled sites, links the site_down.conf file to enabled
        sites and restarts nginx
        """
        self.make_site_confs('up')
        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, nginx_conf=self.nginx_conf)
        if self.dist_version == '14.04':
            cmd = ['service', 'nginx', 'restart']
        elif self.dist_version == '16.04':
            cmd = ['systemctl', 'restart', 'nginx']
        msg = '%s is down' % self.app_name
        func = 'site_down'
        args = ('down',)
        self.run_success([cmd], [msg], func, serve_django_static.site_toggle_up_down, args)
        self.assertTrue(os.path.islink(os.path.join(self.nginx_conf, 'sites-enabled', '%s_down.conf' % self.app_name)))
        self.assertFalse(os.path.isfile(os.path.join(self.nginx_conf, 'sites-enabled', '%s.conf' % self.app_name)))
        remove_test_dir()
        self.make_site_confs('up')
        self.run_error(cmd, func, serve_django_static.site_toggle_up_down, args)

    def test_site_toggle_up(self):
        """
        tests that site_toggle_up_down removes the site_down.conf file from enabled sites, links the site.conf file to enabled
        sites and restarts nginx
        """
        self.make_site_confs('down')
        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, nginx_conf=self.nginx_conf)
        if self.dist_version == '14.04':
            cmd = ['service', 'nginx', 'restart']
        elif self.dist_version == '16.04':
            cmd = ['systemctl', 'restart', 'nginx']
        msg = '%s is up' % self.app_name
        func = 'site_down'
        args = ('up',)
        self.run_success([cmd], [msg], func, serve_django_static.site_toggle_up_down, args)
        self.assertTrue(os.path.islink(os.path.join(self.nginx_conf, 'sites-enabled', '%s.conf' % self.app_name)))
        self.assertFalse(os.path.isfile(os.path.join(self.nginx_conf, 'sites-enabled', '%s_down.conf' % self.app_name)))
        remove_test_dir()
        self.make_site_confs('down')
        self.run_error(cmd, func, serve_django_static.site_toggle_up_down, args)

    def test_site_toggle_exits_when_sites_available_conf_file_is_absent(self):
        """
        tests that site_toggle_up_down exits when sites available conf file is absent
        """
        self.make_site_confs('down')
        os.remove(os.path.join(self.nginx_conf, 'sites-available', '%s.conf' % self.app_name))
        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, nginx_conf=self.nginx_conf)
        try:
            serve_django_static.site_toggle_up_down('up')
            self.fail('site_toggle_up_down failed to exit on file not found error')
        except SystemExit as error:
            self.assertEqual(1, error.code, 'move exited with: ' + str(error))
            self.log('ERROR: file not found: %s' % os.path.join(
                self.nginx_conf, 'sites-available', '%s.conf' % self.app_name
            ))

    def test_site_toggle_does_nothing_when_site_already_enabled(self):
        """
        tests that site_toggle_up_down does nothing when site is already enabled
        :return:
        """
        self.make_site_confs('up')
        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, nginx_conf=self.nginx_conf)
        serve_django_static.site_toggle_up_down('up')
        self.log('INFO: %s is already enabled' % self.app_name)


class WebServerMainTest(StaticTest):
    def setUp(self):
        StaticTest.setUp(self)

    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_run_main_default(self, own_app_mock, clone_app_mock):
        """
        tests run main script with move static parameter returns no error
        """
        sys.argv = ['webserver', '-m', '-l', 'DEBUG']
        paths = [self.static_path, self.media_path, self.uwsgi_path, self.down_path]
        for p in paths:
            os.makedirs(p)
        webserver.DIST_VERSION = self.dist_version
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name))
        os.makedirs(os.path.join(os.path.dirname(self.app_home), 'conf.d'))
        conf = [
            {'file': 'settings.json', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'behave.ini', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'settings_admin.py', 'move_to': os.path.join(self.app_home, self.app_name, self.app_name)},
            {'file': '%s_uwsgi.ini' % self.app_name, 'move_to': self.app_home}
        ]
        for f in conf:
            with open(os.path.join(os.path.dirname(self.app_home), 'conf.d', f['file']), 'w') as config:
                config.write('%s file\n' % f['file'])
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version, 'site-packages'))

        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        expected_calls = [call(self.down_path, self.web_user, self.webserver_user),
                          call(os.path.dirname(self.venv), self.web_user, self.web_user),
                          call(self.app_home, self.web_user, self.web_user),
                          call(self.static_path, self.web_user, self.webserver_user),
                          call(self.media_path, self.web_user, self.webserver_user),
                          call(self.uwsgi_path, self.web_user, self.webserver_user)]
        for e in expected_calls:
            self.assertTrue(e in own_app_mock.mock_calls, '%s not in %s' % (e, own_app_mock.mock_calls))
        self.assertEqual([call(self.app_home)] * 4, clone_app_mock.mock_calls, clone_app_mock.mock_calls)

    def test_run_main_site_down(self):
        """
        tests that site can be turned down
        """
        self.make_site_confs('up')
        sys.argv = ['webserver', '-s', 'down', '-l', 'DEBUG']
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.log('INFO: %s is down' % self.app_name)

    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_run_main_remove_static(self, own_app_mock, clone_app_mock):
        """
        tests run main script with remove static parameter returns no error
        """
        user = 'web_user'
        os.makedirs(self.static_path)
        os.makedirs(self.media_path)
        os.makedirs(self.uwsgi_path)
        os.makedirs(self.down_path)
        webserver.DIST_VERSION = self.dist_version
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name))
        os.makedirs(os.path.join(os.path.dirname(self.app_home), 'conf.d'))
        conf = [
            {'file': 'settings.json', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'behave.ini', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'settings_admin.py', 'move_to': os.path.join(self.app_home, self.app_name, self.app_name)},
            {'file': '%s_uwsgi.ini' % self.app_name, 'move_to': self.app_home}
        ]
        for f in conf:
            with open(os.path.join(os.path.dirname(self.app_home), 'conf.d', f['file']), 'w') as config:
                config.write('%s file\n' % f['file'])
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version, 'site-packages'))

        serve_django_static = ServeStatic(self.dist_version, self.app_home, self.log_file, self.log_level,
                                          git_repo=self.git_repo, sys_deps_file=self.sys_deps_file,
                                          reqs_file=self.reqs_file, venv=self.venv)
        serve_django_static.serve_static(
            user, user, self.down_path, self.static_path, self.media_path, self.uwsgi_path
        )

        sys.argv = ['webserver', '-x', '-l', 'DEBUG']
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))

        self.assertEqual([
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.down_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.static_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.media_path, self.web_user, self.web_user),
            call(self.app_home, self.web_user, self.web_user),
            call(os.path.dirname(self.venv), self.web_user, self.web_user),
            call(self.uwsgi_path, self.web_user, self.web_user),
        ], own_app_mock.mock_calls, own_app_mock.mock_calls)
        self.assertEqual([call(self.app_home)] * 4, clone_app_mock.mock_calls, clone_app_mock.mock_calls)

        fds = [
            self.down_path,
            self.static_path,
            self.media_path,
            self.uwsgi_path,
        ]
        for f in fds:
            self.assertTrue(os.path.exists(f), '%s not present' % f)
            self.log('INFO: removed files in %s' % f)

    @mock.patch.object(InstallDjangoApp, 'clone_app', side_effect=clone_app_mock)
    @mock.patch.object(CommandFileUtils, 'own', side_effect=own_app_mock)
    def test_run_main_reload_static(self, own_app_mock, clone_app_mock):
        """
        tests run main script with move static parameter returns no error
        """
        sys.argv = ['webserver', '-r', '-l', 'DEBUG']
        paths = [self.static_path, self.media_path, self.uwsgi_path, self.down_path]
        for p in paths:
            os.makedirs(p)
        webserver.DIST_VERSION = self.dist_version
        os.makedirs(os.path.join(self.app_home, self.app_name, self.app_name))
        os.makedirs(os.path.join(os.path.dirname(self.app_home), 'conf.d'))
        conf = [
            {'file': 'settings.json', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'behave.ini', 'move_to': os.path.join(self.app_home, self.app_name)},
            {'file': 'settings_admin.py', 'move_to': os.path.join(self.app_home, self.app_name, self.app_name)},
            {'file': '%s_uwsgi.ini' % self.app_name, 'move_to': self.app_home}
        ]
        for f in conf:
            with open(os.path.join(os.path.dirname(self.app_home), 'conf.d', f['file']), 'w') as config:
                config.write('%s file\n' % f['file'])
        if self.dist_version == '14.04':
            self.python_version = 'python3.4'
        elif self.dist_version == '16.04':
            self.python_version = 'python3.5'
        os.makedirs(os.path.join(self.venv, 'lib', self.python_version, 'site-packages'))

        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))

        expected_calls = [call(self.down_path, self.web_user, self.webserver_user),
                          call(os.path.dirname(self.venv), self.web_user, self.web_user),
                          call(self.app_home, self.web_user, self.web_user),
                          call(self.static_path, self.web_user, self.webserver_user),
                          call(self.media_path, self.web_user, self.webserver_user),
                          call(self.uwsgi_path, self.web_user, self.webserver_user)]
        for e in expected_calls:
            self.assertTrue(e in own_app_mock.mock_calls, '%s not in %s' % (e, own_app_mock.mock_calls))

        self.assertEqual([call(self.app_home)] * 4, clone_app_mock.mock_calls, clone_app_mock.mock_calls)

        fds = [
            self.down_path,
            self.static_path,
            self.media_path,
            self.uwsgi_path,
        ]
        for f in fds:
            self.assertTrue(os.path.exists(f), '%s not present' % f)
            self.log('INFO: removed files in %s' % f)

    def test_run_main_site_up(self):
        """
        tests that site can be turned down
        """
        self.make_site_confs('down')
        sys.argv = ['webserver', '-s', 'up', '-l', 'DEBUG']
        try:
            main()
        except SystemExit as sysexit:
            self.assertEqual('0', str(sysexit), 'main returned: ' + str(sysexit))
        self.log('INFO: %s is up' % self.app_name)


if __name__ == '__main__':
    unittest.main()
