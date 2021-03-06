#! /usr/bin/python3
import sys
import os
import shutil
from optparse import OptionParser
from djangoapp import InstallDjangoApp
from conf import DIST_VERSION, GIT_REPO, APP_HOME_TMP, WEB_USER, WEBSERVER_USER, LOG_FILE, STATIC_PATH
from conf import MEDIA_PATH, UWSGI_PATH, DOWN_PATH, NGINX_CONF, REQS_FILE, SYS_DEPS_FILE, VENV


class ServeStatic(InstallDjangoApp):
    """
    Manages Django app static content.
    """

    def __init__(
        self,
        dist_version,
        app_home,
        log_file, 
        log_level,
        git_repo='https://github.com/globz-eu/django_base.git',
        nginx_conf='/etc/nginx',        
        sys_deps_file='system_dependencies.txt',
        reqs_file='requirements.txt',
        venv=''
    ):
        InstallDjangoApp.__init__(self, dist_version, log_file, log_level, git_repo=git_repo, venv=venv)
        self.app_home = app_home
        self.nginx_conf = nginx_conf
        if self.dist_version == '14.04':
            self.nginx_cmd = ['service', 'nginx', 'restart']
        elif self.dist_version == '16.04':
            self.nginx_cmd = ['systemctl', 'restart', 'nginx']
        self.sys_deps_file = os.path.join(self.app_home, self.app_name, sys_deps_file)
        self.reqs_file = os.path.join(self.app_home, self.app_name, reqs_file)

    def move(self, from_path=None, to_path=None, file_type=None, web_user='web_user', reqs_file='', sys_deps_file=''):
        """
        moves static content from django app
        (and clones it and install venv and dependencies if absent)
        to static_path
        :param sys_deps_file: system package dependencies file from django app
        :param reqs_file: python package requirements file from django app
        :param web_user: web user username
        :param file_type: type of from path (file or dir)
        :param from_path: directory or file path in app to move
        :param to_path: path to directory to move static content to
        :return: 0 if move reaches the end of its flow
        """
        if not reqs_file:
            reqs_file = self.reqs_file
        if not sys_deps_file:
            sys_deps_file = self.sys_deps_file

        if from_path and to_path and file_type:
            try:
                if os.path.exists(to_path):
                    if file_type == 'dir':
                        if os.listdir(to_path):
                            msg = 'content already present in %s' % to_path

                        else:
                            if os.path.exists(to_path):
                                shutil.rmtree(to_path)
                            self.install_app(self.app_home, web_user, sys_deps_file, reqs_file,
                                             chmod_app=False, cp_ini=False)
                            self.collect_static(self.app_home)
                            shutil.move(from_path, os.path.dirname(to_path))
                            os.rename(os.path.join(os.path.dirname(to_path), os.path.basename(from_path)), to_path)
                            msg = '%s moved to %s' % (os.path.basename(from_path), to_path)

                    elif file_type == 'file':
                        if os.path.isfile(os.path.join(to_path, os.path.basename(from_path))):
                            msg = '%s is already present in %s' % (os.path.basename(from_path), to_path)

                        else:
                            self.install_app(self.app_home, web_user, sys_deps_file, reqs_file,
                                             chmod_app=False, cp_ini=False)
                            self.collect_static(self.app_home)
                            shutil.move(from_path, to_path)
                            msg = '%s moved to %s' % (os.path.basename(from_path), to_path)

                    else:
                        msg = 'unknown file type %s' % file_type
                        self.write_to_log(msg, 'ERROR')
                        sys.exit(1)

                    self.write_to_log(msg, 'INFO')

                else:
                    raise FileNotFoundError(from_path)

            except FileNotFoundError as error:
                if error.filename and error.filename2:
                    filename = '%s and %s' % (error.filename, error.filename2)
                elif error.filename and not error.filename2:
                    filename = '%s' % error.filename
                elif error.filename2 and not error.filename:
                    filename = '%s' % error.filename2
                else:
                    filename = error.args[0]
                msg = 'file not found: %s' % filename
                self.write_to_log(msg, 'ERROR')
                sys.exit(1)

        else:
            msg = 'cannot move app files, some path is not specified'
            self.write_to_log(msg, 'ERROR')
            sys.exit(1)

        return 0

    def serve_static(self, web_user, webserver_user, down_path, static_path, media_path, uwsgi_path):
        """
        clones app to temp directory, moves static to static_path and manages ownership and permissions
        :param down_path: server down folder
        :param webserver_user: web server user (usually www-data)
        :param web_user: web user
        :param static_path: path to static content
        :param media_path: path to media content
        :param uwsgi_path: path to uwsgi_params directory
        :return: returns 0 if it reaches the end of its flow
        """
        static_files = [
            {'from_path': os.path.join(self.app_home, self.app_name, 'static', 'base', 'site_down', 'index.html'),
             'to_path': down_path, 'file_type': 'file'},
            {'from_path': os.path.join(self.app_home, self.app_name, 'static'),
             'to_path': static_path, 'file_type': 'dir'},
            {'from_path': os.path.join(self.app_home, self.app_name, 'media'),
             'to_path': media_path, 'file_type': 'dir'},
            {'from_path': os.path.join(self.app_home, self.app_name, 'uwsgi_params'),
             'to_path': uwsgi_path, 'file_type': 'file'},
        ]

        for static in static_files:
            static['web_user'] = web_user
            os.makedirs(self.app_home, exist_ok=True)
            move = self.move(**static)
            if not move:
                self.own(static['to_path'], web_user, webserver_user)
                self.permissions(static['to_path'], '440', '550', recursive=True)
        shutil.rmtree(self.app_home)
        self.write_to_log('serve static exited with code 0\n', 'INFO')
        return 0

    def remove_static(self, down_path, static_path, media_path, uwsgi_path):
        """
        removes static, media and uwsgi_params
        :param down_path: server down folder
        :param static_path: path to static content
        :param media_path: path to media content
        :param uwsgi_path: path to uwsgi_params directory
        :return: returns 0 if it reaches the end of its flow
        """
        paths = [down_path, static_path, media_path, uwsgi_path]
        for path in paths:
            if os.path.exists(path):
                self.permissions(path, '770', '770', recursive=True)
                shutil.rmtree(path)
                os.makedirs(path)
                self.write_to_log('removed files in %s\n' % path, 'INFO')
            else:
                os.makedirs(path)
                self.write_to_log('added missing path %s\n' % path, 'INFO')
        return 0

    def site_toggle_up_down(self, up_down='up'):
        """
        enables site and restarts nginx if up_down is up, enables site_down and restarts nginx if up_down is down
        :param up_down: 'up' or 'down' to enable site or site_down respectively
        :return: 0 if it reaches the end of its flow
        """
        if up_down == 'up':
            to = self.app_name
            fro = '%s_down' % self.app_name
        elif up_down == 'down':
            to = '%s_down' % self.app_name
            fro = self.app_name
        if not os.path.exists(os.path.join(self.nginx_conf, 'sites-enabled', '%s.conf' % to)):
            try:
                if os.path.exists(os.path.join(self.nginx_conf, 'sites-available', '%s.conf' % to)):
                    os.symlink(
                        os.path.join(self.nginx_conf, 'sites-available', '%s.conf' % to),
                        os.path.join(self.nginx_conf, 'sites-enabled', '%s.conf' % to)
                    )
                    os.remove(os.path.join(self.nginx_conf, 'sites-enabled', '%s.conf' % fro))
                    cmd = self.nginx_cmd
                    msg = '%s is %s' % (self.app_name, up_down)
                    self.run_command(cmd, msg)
                else:
                    raise FileNotFoundError(os.path.join(self.nginx_conf, 'sites-available', '%s.conf' % to))
            except FileNotFoundError as error:
                msg = 'file not found: ' + error.args[0]
                self.write_to_log(msg, 'ERROR')
                sys.exit(1)
        else:
            msg = '%s is already enabled' % to
            self.write_to_log(msg, 'INFO')
        return 0


def main():
    """
    Main flow control. clones app to temp directory, moves static to static path. removes app from temp directory
    exits with code 0 if it reaches the end of its flow
    """
    run = []
    usage = "usage: %prog [options] arg"
    parser = OptionParser(usage)
    parser.add_option('-l', '--log-level', dest='log_level',
                      help='log-level: DEBUG, INFO, WARNING, ERROR, CRITICAL', default='INFO')
    parser.add_option('-m', '--serve-static', dest='serve_static', action='store_true',
                      help='serve-static: collects static files and moves them from app to server static folders',
                      default=False)
    parser.add_option('-x', '--remove-static', dest='remove_static', action='store_true',
                      help='removes static files from server static folders', default=False)
    parser.add_option('-r', '--reload-static', dest='reload_static', action='store_true',
                      help='reloads static files to server static folders', default=False)
    parser.add_option('-s', '--site-manage', dest='site_manage',
                      help='site-manage: (up, down) turns site up or down', default=False)
    (options, args) = parser.parse_args()
    if len(args) > 2:
        parser.error('incorrect number of arguments')

    kwargs = {
        'git_repo': GIT_REPO, 'nginx_conf': NGINX_CONF} if NGINX_CONF else {
        'git_repo': GIT_REPO
    }
    if REQS_FILE:
        kwargs['reqs_file'] = REQS_FILE
    if SYS_DEPS_FILE:
        kwargs['sys_deps_file'] = SYS_DEPS_FILE
    if VENV:
        kwargs['venv'] = VENV

    serve_django_static = ServeStatic(DIST_VERSION, APP_HOME_TMP, LOG_FILE, options.log_level, **kwargs)

    if options.serve_static:
        static = serve_django_static.serve_static(
            WEB_USER, WEBSERVER_USER, DOWN_PATH, STATIC_PATH, MEDIA_PATH, UWSGI_PATH
        )
        run.append(static)

    if options.site_manage:
        if options.site_manage == 'up':
            site_up = serve_django_static.site_toggle_up_down('up')
            run.append(site_up)
        if options.site_manage == 'down':
            site_down = serve_django_static.site_toggle_up_down('down')
            run.append(site_down)

    if options.remove_static:
        remove = serve_django_static.remove_static(
            DOWN_PATH, STATIC_PATH, MEDIA_PATH, UWSGI_PATH
        )
        run.append(remove)

    if options.reload_static:
        remove = serve_django_static.remove_static(
            DOWN_PATH, STATIC_PATH, MEDIA_PATH, UWSGI_PATH
        )
        run.append(remove)
        static = serve_django_static.serve_static(
            WEB_USER, WEBSERVER_USER, DOWN_PATH, STATIC_PATH, MEDIA_PATH, UWSGI_PATH
        )
        run.append(static)

    for r in run:
        if r != 0:
            sys.exit(1)
    sys.exit(0)


if __name__ == '__main__':
    main()
