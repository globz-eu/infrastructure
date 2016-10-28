#! /usr/bin/python3
"""
=====================================================================
Django app deployment scripts
Copyright (C) 2016 Stefan Dieterle
e-mail: golgoths@yahoo.fr

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=====================================================================

Installs system dependencies and python package requirements on a
trusty server

"""

import os
import re
import shutil
import sys
import datetime
import time
from optparse import OptionParser
from conf import DIST_VERSION, GIT_REPO, APP_HOME, APP_USER, VENV, REQS_FILE, SYS_DEPS_FILE, LOG_FILE, CELERY_PID_PATH
from conf import FIFO_DIR
from utilities.commandfileutils import CommandFileUtils


class InstallDjangoApp(CommandFileUtils):
    """
    Runs commands using the appropriate run function for the specified distribution. Logs to file.
    """

    def __init__(
            self, dist_version, log_file, log_level,
            venv=None, git_repo='https://github.com/globz-eu/django_base.git', celery_pid='/var/run/django_base/celery',
            fifo_dir='/tmp'
    ):
        """
        Initializes parameters. Sets appropriate venv creation command and python version for distribution.
        :param dist_version: distribution version
        :param log_file: log file path
        :param log_level: general log level
        :param venv: venv path
        :param git_repo: git repository URL
        """
        CommandFileUtils.__init__(self, dist_version, log_file, log_level)
        self.venv = venv
        if self.venv:
            self.pip = os.path.abspath(os.path.join(self.venv, 'bin/pip'))
            if self.dist_version == '14.04':
                self.venv_cmd = ['virtualenv', '-p', '/usr/bin/python3.4', self.venv]
                self.python_version = 'python3.4'
            elif self.dist_version == '16.04':
                self.venv_cmd = ['pyvenv', self.venv]
                self.python_version = 'python3.5'
        else:
            self.venv_cmd = None
            self.python_version = None
        self.git_repo = git_repo
        p = re.compile('https://github.com/[\w\-]+/(\w+)\.git')
        self.app_name = p.match(git_repo).group(1)
        self.fifo_dir = fifo_dir
        self.celery_pid = os.path.join(celery_pid, 'w1.pid')

    def clone_app(self, app_home):
        """
        clones django app from git repo to app_home
        :param: app_home: folder to install app to
        :return: returns run_command return code
        """
        app_path = os.path.join(app_home, self.app_name)
        if not os.path.exists(app_path):
            cmd = ['git', 'clone', self.git_repo]
            msg = 'successfully cloned %s to %s' % (self.app_name, app_home)
            run = self.run_command(cmd, msg, cwd=app_home)
            return run
        else:
            msg = 'app %s already exists at %s' % (self.app_name, app_home)
            self.write_to_log(msg, 'INFO')
            return 0

    def create_venv(self):
        """
        creates a python3.4 or python3.5 virtual environment
        :return: returns run_command return code
        """
        if not os.path.exists(self.venv):
            msg = 'successfully created virtualenv %s' % self.venv
            run = self.run_command(self.venv_cmd, msg)
            return run
        else:
            msg = 'virtualenv %s already exists' % self.venv
            self.write_to_log(msg, 'INFO')
            return 0

    def read_sys_deps(self, deps_file):
        """
        parses system_dependencies file
        :param: deps_file: system_dependencies file
        :return: dependency list: ['dependency_1', ... , 'dependency_n']
        """
        with open(deps_file) as system_dependencies:
            deps_list = [line.rstrip() for line in system_dependencies]
        return deps_list

    def read_reqs(self, reqs_file):
        """
        parses python packages requirements file
        :param: reqs_file: requirements file
        :return: [['package_1', 'package_1 version'], ... , [['package_n, 'package_n version]]
        """
        with open(reqs_file) as requirements:
            req_list = [r.rstrip().split('==') for r in requirements]
        return req_list

    def install_sys_deps(self, sys_deps):
        """
        installs system dependencies with apt-get install -y dependency_1 ... dependency_n, logs to log file
        :param: sys_deps: list of dependencies parsed by read_sys_deps
        :return: returns run_command return code
        """
        cmd = ['apt-get', 'install', '-y']
        cmd.extend(sys_deps)
        msg = 'successfully installed: ' + ' '.join(sys_deps)
        run = self.run_command(cmd, msg)
        return run

    def check_biopython(self, reqs):
        """
        Checks for presence of biopython in requirements. If biopython is present installs numpy with version specified in
        requirements or newest version if not found in requirements file before installation of biopython by
        install_requirements. Logs to log file.
        :param: reqs: list of requirements and versions returned by read_reqs
        :return: returns run_command return code if biopython is found in requirements otherwise returns 0
        """
        bio_python = [r for r in reqs if r[0] == 'biopython']
        if bio_python:
            numpy_v = [[b[0], b[1]] for b in reqs if b[0] == 'numpy'][0]
            numpy_i = '=='.join(numpy_v) if numpy_v[1] != '0' else 'numpy'
            cmd = [self.pip, 'install', numpy_i]
            msg = 'successfully installed: ' + numpy_i
            run = self.run_command(cmd, msg)
            return run
        else:
            msg = 'biopython was not found in requirements, skipped installation of numpy'
            self.write_to_log(msg, 'DEBUG')
            return 0

    def install_requirements(self, reqs):
        """
        Installs python package dependencies from requirements file after checking for presence of biopython requirements
        and installing numpy package if present, logs to log file
        :param: reqs: list of requirements and versions returned by read_reqs
        :return: returns run_command return code
        """
        self.check_biopython(reqs)
        cmd = [self.pip, 'install']
        cmd.extend(['=='.join(r) for r in reqs])
        msg = 'successfully installed: ' + ' '.join(['('.join(i) + ')' for i in reqs])
        run = self.run_command(cmd, msg)
        return run

    def add_app_to_path(self, app_home):
        """
        Adds django app path to python path in venv
        :param: app_home: folder to install app to
        :param: app_name: django app name
        :return: returns 0
        """
        pth_file = os.path.join(self.venv, 'lib/%s/%s.pth' % (self.python_version, self.app_name))
        app_path = os.path.join(app_home, self.app_name)
        with open(pth_file, 'w+') as pth:
            pth.write(app_path + '\n')
            msg = self.app_name + ' has been added to python path in ' + self.venv
            self.write_to_log(msg, 'INFO')
        return 0

    def copy_config(self, app_home):
        """
        Copies configuration.py and settings_admin.py to app
        :param app_home: folder to install app to
        :param app_name: django app name
        :return: returns 0
        """
        app_conf = os.path.join(os.path.dirname(app_home), 'conf.d')
        conf = [
            {'file': 'settings.json', 'move_to': os.path.join(app_home, self.app_name)},
            {'file': 'settings_admin.py', 'move_to': os.path.join(app_home, self.app_name, self.app_name.lower())},
            {'file': '%s_uwsgi.ini' % self.app_name, 'move_to': app_home}
        ]

        for c in conf:
            if os.path.isfile(os.path.join(c['move_to'], c['file'])):
                self.write_to_log('%s is already present in %s' % (c['file'], self.app_name), 'INFO')
            else:
                try:
                    shutil.copy(
                        os.path.join(app_conf, c['file']),
                        os.path.join(c['move_to'], c['file'])
                    )
                    msg = 'app configuration file ' + c['file'] + ' was copied to app'
                    self.write_to_log(msg, 'INFO')
                except FileNotFoundError:
                    msg = 'could not copy ' + c['file']
                    self.write_to_log(msg, 'ERROR')
                    sys.exit(1)
        return 0

    def run_migrations(self, app_home):
        """
        runs database migrations for django app
        :param app_home: app root
        :return: returns run_command return code as soon as it is not 0 or 0 if all commands are run successfully
        """
        cmds = [
            {
                'cmd': [
                    os.path.join(self.venv, 'bin', 'python'), './manage.py', 'makemigrations',
                    '--settings', '%s.settings_admin' % self.app_name.lower()
                ],
                'msg': 'successfully ran makemigrations'
            },
            {
                'cmd': [
                    os.path.join(self.venv, 'bin', 'python'), './manage.py', 'migrate',
                    '--settings', '%s.settings_admin' % self.app_name.lower()
                ],
                'msg': 'successfully migrated %s' % self.app_name
            }
        ]
        for cmd in cmds:
            run = self.run_command(cmd['cmd'], cmd['msg'], cwd=os.path.join(app_home, self.app_name))
            if run != 0:
                return run
        return 0

    def collect_static(self, app_home):
        """
        runs collectstatic for django app
        :param app_home: app root
        :return: returns run_command return code
        """
        cmd = [
                os.path.join(self.venv, 'bin', 'python'), './manage.py', 'collectstatic',
                '--noinput', '--settings', '%s.settings_admin' % self.app_name
        ]
        cwd = os.path.join(app_home, self.app_name)
        msg = 'successfully collected static for %s' % self.app_name
        run = self.run_command(cmd, msg, cwd=cwd)
        return run

    def run_tests(self, app_home):
        """
        runs app unit and functional tests
        :param app_home: app root
        :return: returns run_command return code
        """
        pending = self.get_pending_dirs(app_home, self.app_name)
        cmd = [os.path.join(self.venv, 'bin', 'python'), './manage.py', 'test']
        for p in pending:
            cmd.extend(['--exclude-dir', p])
        cmd.extend(['--settings', '%s.settings_admin' % self.app_name.lower()])
        cmds = [
            {
                'cmd': cmd,
                'msg': 'successfully ran unit tests for %s' % self.app_name,
            },
            {
                'cmd': [os.path.join(self.venv, 'bin', 'python'), './manage.py', 'behave',
                        '--tags', '~@skip', '--no-skipped', '--junit', '--settings',
                        '%s.settings_admin' % self.app_name.lower()],
                'msg': 'successfully ran functional tests for %s' % self.app_name,
            }
        ]
        now = datetime.datetime.utcnow()
        os.makedirs(os.path.join(os.path.dirname(self.log_file), 'test_results'), exist_ok=True)
        log_file = os.path.join(
            os.path.dirname(self.log_file), 'test_results', 'test_%s.log' % (now.strftime('%Y%m%d-%H%M%S'))
        )
        for cmd in cmds:
            self.run_command(cmd['cmd'], cmd['msg'], cwd=os.path.join(app_home, self.app_name), out=log_file)
        test_files = os.listdir(os.path.dirname(log_file))
        test_files.sort(reverse=True)
        with open(os.path.join(os.path.dirname(log_file), test_files[0])) as log:
            log_list = [l for l in log]
        for l in log_list:
            if 'FAILED' in l:
                self.write_to_log('%s tests failed' % self.app_name, 'ERROR')
                sys.exit(1)
        return 0

    def start_celery(self, app_home):
        """
        starts celery and beat
        :param app_home: app root
        :return: returns run_command return code
        """
        cmd = [
            os.path.join(self.venv, 'bin', 'python'),
            '-m',
            'celery',
            'multi',
            'start',
            'w1',
            '-A',
            self.app_name.lower(),
            '-B',
            '--scheduler=djcelery.schedulers.DatabaseScheduler',
            '--pidfile=%s' % self.celery_pid,
            '--logfile=%s' % os.path.join(os.path.dirname(self.log_file), 'celery', 'w1.log'),
            '-l',
            'info'
        ]
        cwd = os.path.join(app_home, self.app_name)
        msg = 'started celery and beat'
        if not os.path.exists(self.celery_pid):
            run = self.run_command(cmd, msg, cwd=cwd)
        else:
            run = 0
            self.write_to_log('celery is already running', 'INFO')
        return run

    def stop_celery(self, app_home):
        """
        stops celery and beat
        :param app_home: app root
        :return: returns run_command return code
        """
        cmd = [
            os.path.join(self.venv, 'bin', 'python'),
            '-m',
            'celery',
            'multi',
            'stopwait',
            'w1',
            '--pidfile=%s' % self.celery_pid,
        ]
        cwd = os.path.join(app_home, self.app_name)
        msg = 'stopped celery and beat'
        if os.path.exists(self.celery_pid):
            run = self.run_command(cmd, msg, cwd=cwd)
        else:
            run = 0
            self.write_to_log('did not stop celery, was not running', 'INFO')
        return run

    def start_uwsgi(self, app_home):
        """
        starts uwsgi server
        :param app_home: app root
        :return: returns run_command return code
        """
        uwsgi = self.check_process('uwsgi')
        cmd = ['uwsgi', '--ini', os.path.join(app_home, '%s_uwsgi.ini' % self.app_name)]
        msg = 'started uwsgi server'
        cwd = os.path.join(app_home, self.app_name)
        if not uwsgi:
            os.makedirs(os.path.join('/tmp', self.app_name), exist_ok=True)
            self.permissions(os.path.join('/tmp', self.app_name), dir_permissions='777')
            run = self.run_command(cmd, msg, cwd=cwd)
        else:
            run = 0
            self.write_to_log('uwsgi is already running', 'INFO')
        return run

    def stop_uwsgi(self):
        """
        stops uwsgi server
        :return: returns run_command return code
        """
        uwsgi = self.check_process('uwsgi')
        msg = 'stopped uwsgi server'
        if uwsgi:
            with open(os.path.join(self.fifo_dir, 'fifo0'), 'w') as fifo:
                fifo.write('q')
            self.write_to_log(msg, 'INFO')
            run = 0
        else:
            run = 0
            self.write_to_log('did not stop uwsgi, was not running', 'INFO')
        return run

    def install_app(self, app_home, app_user, deps_file='system_dependencies.txt', reqs_file='requirements.txt',
                    chmod_app=True):
        """
        Manages installation of django app as well as system dependencies and python packages requirements, adds django
        app to python path.
        :param: app_home: django app path
        :param: app_user: django app user
        :param: deps_file: location of system dependencies file
        :param: reqs_file: location of python packages requirements file
        :return: returns 0 if it reaches the end of its flow
        """
        self.clone_app(app_home)
        deps_list = self.read_sys_deps(deps_file)
        reqs_list = self.read_reqs(reqs_file)
        self.install_sys_deps(deps_list)
        self.copy_config(app_home)
        self.own(app_home, app_user, app_user)
        if chmod_app:
            self.permissions(app_home, '400', '500', recursive=True)
        self.create_venv()
        self.install_requirements(reqs_list)
        self.add_app_to_path(app_home)
        self.own(os.path.dirname(self.venv), app_user, app_user)
        venvs = [os.path.dirname(self.venv), self.venv]
        for venv in venvs:
            self.permissions(venv, dir_permissions='500')
        self.write_to_log('install django app exited with code 0\n', 'INFO')
        return 0

    def remove_app(self, app_home, app_user):
        """
        removes app home directory
        :param app_user: django app user
        :param app_home: django app path
        :return: returns 0 if it reaches the end of its flow
        """
        if os.path.exists(app_home):
            shutil.rmtree(app_home)
            os.makedirs(app_home)
            self.own(app_home, app_user, app_user)
            self.permissions(app_home, dir_permissions='500')
            self.write_to_log('removed %s' % self.app_name, 'INFO')
        return 0


def main():
    """
    Main flow control. Parses command line arguments and passe them on to install_dependencies. Passes parameters from
    configuration file to install_dependencies.
    exits with code 0 if it reaches the end of its flow
    """
    run = []
    usage = "usage: %prog [options] arg"
    parser = OptionParser(usage)
    parser.add_option('-i', '--install', dest='install', action='store_true',
                      help='install: installs django app, requirements and dependencies', default=False)
    parser.add_option('-l', '--log-level', dest='log_level',
                      help='log-level: DEBUG, INFO, WARNING, ERROR, CRITICAL', default='INFO')
    parser.add_option('-m', '--migrate', dest='migrate', action='store_true',
                      help='migrate: runs database migrations', default=False)
    parser.add_option('-s', '--collect-static', dest='collect_static', action='store_true',
                      help='collect-static: runs collects static files to static root', default=False)
    parser.add_option('-t', '--run-tests', dest='tests', action='store_true',
                      help='run-tests: runs app tests', default=False)
    parser.add_option('-c', '--celery', dest='celery',
                      help='celery and beat: start, stop, restart', default=False)
    parser.add_option('-u', '--uwsgi', dest='uwsgi',
                      help='uwsgi: start, stop, restart', default=False)
    parser.add_option('-x', '--remove-app', dest='remove_app', action='store_true',
                      help='remove-app: stops uwsgi server and removes app', default=False)
    (options, args) = parser.parse_args()
    if len(args) > 2:
        parser.error('incorrect number of arguments')

    install_django_app = InstallDjangoApp(
        DIST_VERSION, LOG_FILE, options.log_level, venv=VENV, git_repo=GIT_REPO, celery_pid=CELERY_PID_PATH,
        fifo_dir=FIFO_DIR
    )

    kwargs = {}
    if REQS_FILE:
        kwargs['reqs_file'] = REQS_FILE
    if SYS_DEPS_FILE:
        kwargs['deps_file'] = SYS_DEPS_FILE

    if options.install:
        install = install_django_app.install_app(APP_HOME, APP_USER, **kwargs)
        run.append(install)
    if options.migrate:
        migrate = install_django_app.run_migrations(APP_HOME)
        run.append(migrate)
    if options.collect_static:
        collect_static = install_django_app.collect_static(APP_HOME)
        run.append(collect_static)
    if options.tests:
        tests = install_django_app.run_tests(APP_HOME)
        run.append(tests)
    if options.celery == 'start':
        celery = install_django_app.start_celery(APP_HOME)
        run.append(celery)
    if options.celery == 'stop':
        celery = install_django_app.stop_celery(APP_HOME)
        run.append(celery)
    if options.celery == 'restart':
        celery = install_django_app.stop_celery(APP_HOME)
        run.append(celery)
        time.sleep(1)
        celery = install_django_app.start_celery(APP_HOME)
        run.append(celery)
    if options.uwsgi == 'start':
        uwsgi = install_django_app.start_uwsgi(APP_HOME)
        run.append(uwsgi)
    if options.uwsgi == 'stop':
        uwsgi = install_django_app.stop_uwsgi()
        run.append(uwsgi)
    if options.uwsgi == 'restart':
        uwsgi = install_django_app.stop_uwsgi()
        run.append(uwsgi)
        time.sleep(1)
        uwsgi = install_django_app.start_uwsgi(APP_HOME)
        run.append(uwsgi)
    if options.remove_app:
        uwsgi = install_django_app.stop_uwsgi()
        run.append(uwsgi)
        remove = install_django_app.remove_app(APP_HOME, APP_USER)
        run.append(remove)
    elif not options.uwsgi:
        pass
    for r in run:
        if r != 0:
            sys.exit(1)
    sys.exit(0)


if __name__ == '__main__':
    main()
