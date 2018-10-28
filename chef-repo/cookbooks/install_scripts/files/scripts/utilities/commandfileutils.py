import sys
import os
import shutil
import stat
import time
import subprocess
import psutil
import logging
from subprocess import CalledProcessError

__author__ = 'Stefan Dieterle'


class CommandFileUtils:
    """
    Utility class to run commands using the appropriate run method for the specified distribution. Log to file. Manages
    ownership and permissions.
    """
    def __init__(self, dist_version, log_file, log_level):
        """
        Initializes parameters. Sets appropriate run method for distribution.
        :param dist_version: distribution version
        :param log_file: log file path
        :param log_level: general log level
        """
        self.dist_version = dist_version
        self.log_file = log_file
        self.log_level = log_level
        if self.dist_version == '14.04':
            self.run = subprocess.check_call
            self.check = False
        elif self.dist_version == '16.04':
            self.run = subprocess.run
            self.check = True
        else:
            self.write_to_log('distribution not supported', 'CRITICAL')
            sys.exit(1)
        self.pending_dirs = []
        logging.Formatter.converter = time.gmtime
        # logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s',
        #                     datefmt='%Y-%m-%d %H:%M:%S')

    def write_to_log(self, msg, level='DEBUG'):
        """
        Logs message to file according if message level is equal or higher to general log level.
        :param msg: message to be logged
        :param level: message level
        :return: nothing
        """
        log_levels = [
            'DEBUG',
            'INFO',
            'WARNING',
            'ERROR',
            'CRITICAL',
        ]

        logger = logging.getLogger(__name__)
        logger.setLevel(self.log_level)

        handler = logging.FileHandler(self.log_file)
        formatter = logging.Formatter(fmt='%(asctime)s %(levelname)s: %(message)s',
                                      datefmt='%Y-%m-%d %H:%M:%S')
        handler.setFormatter(formatter)
        handler.setLevel(self.log_level)
        logger.addHandler(handler)

        if level in log_levels:
            logging_level = getattr(logger, level.lower())
        else:
            logging_level = logger.error
            msg = 'log level "%s" is not specified or not valid\n' % level
            logging_level(msg)
            sys.exit(1)
        logging_level(msg)

        logger.removeHandler(handler)

    def run_command(self, cmd, msg, cwd=None, out=None, log_error=True):
        """
        Runs command and logs success message to log. Checks that run command is set.
        :param out: stdout and stderr output file (default is None)
        :param cmd: command to be run
        :param msg: message to be logged
        :param cwd: current working directory for command (default is None)
        :param log_error: boolean, controls whether command errors are logged
        :return: 0 on success, exits with 1 if command fails
        """
        if self.check:
            kwargs = dict(check=True)
        else:
            kwargs = {}
        try:
            if out:
                with open(out, 'a') as log:
                    kwargs.update(dict(cwd=cwd, stdout=log, stderr=log))
                    self.run(cmd, **kwargs)
                self.write_to_log(msg, 'INFO')
            elif self.log_level == 'DEBUG':
                with open(self.log_file, 'a') as log:
                    kwargs.update(dict(cwd=cwd, stdout=log, stderr=log))
                    self.run(cmd, **kwargs)
                self.write_to_log(msg, 'INFO')
            else:
                kwargs.update(dict(cwd=cwd))
                self.run(cmd, **kwargs)
                self.write_to_log(msg, 'INFO')
        except CalledProcessError as error:
            if log_error:
                err_msg = '%s exited with exit code %s' % (' '.join(error.cmd), str(error.returncode))
                self.write_to_log(err_msg, 'ERROR')
            sys.exit(1)
        return 0

    def walktree(self, top, f_callback=None, f_args=None, d_callback=None, d_args=None):
        """
        Walks a directory tree from top and calls f_callback with pathname and f_args on files or d_callback with
        pathname and d_args on directories
        :param top: directory to walk
        :param f_callback: callback function for files
        :param f_args: additional positional arguments after pathname for f_callback
        :param d_callback: callback function for directories
        :param d_args: additional positional arguments after pathname for d_callback
        :return: nothing
        """
        for f in os.listdir(top):
            pathname = os.path.join(top, f)
            mode = os.stat(pathname).st_mode
            if stat.S_ISDIR(mode):
                try:
                    if d_callback:
                        if d_args:
                            d_callback(pathname, *d_args)
                        else:
                            d_callback(pathname)
                    self.walktree(pathname, f_callback, f_args, d_callback, d_args)
                except PermissionError as error:
                    msg = '%s on: %s' % (error.strerror, error.filename)
                    self.write_to_log(msg, 'ERROR')
                    sys.exit(1)
            elif stat.S_ISREG(mode):
                try:
                    if f_callback:
                        if f_args:
                            f_callback(pathname, *f_args)
                        else:
                            f_callback(pathname)
                except PermissionError as error:
                    msg = '%s on: %s' % (error.strerror, error.filename)
                    self.write_to_log(msg, 'ERROR')
                    sys.exit(1)
            else:
                self.write_to_log('Unknown file type: %s' % pathname, 'ERROR')

    def permissions(self, path='.', file_permissions='640', dir_permissions='750', recursive=False):
        """
        Recursively sets file and directory permissions in path.
        :param recursive: set permissions recursively if True
        :param path: path to change permissions in
        :param file_permissions: file permissions to apply
        :param dir_permissions: directory permissions to apply
        :return: returns 0 if it reaches the end of its flow
        """
        bit_file_perms = 0
        bit_dir_perms = 0
        for i in range(3):
            for b in range(3):
                bit_file_perms += (int(file_permissions[i]) & 2 ** b) * 2 ** (6 - 3 * i)
                bit_dir_perms += (int(dir_permissions[i]) & 2 ** b) * 2 ** (6 - 3 * i)

        f_args = (bit_file_perms,)
        d_args = (bit_dir_perms,)

        if recursive:
            try:
                os.chmod(path, *d_args)
                self.walktree(path, os.chmod, f_args, os.chmod, d_args)
                msg = 'changed permissions of %s files to %s and directories to %s' % (
                    path, file_permissions, dir_permissions
                )
                self.write_to_log(msg, 'INFO')
            except PermissionError as error:
                msg = '%s on: %s' % (error.strerror, error.filename)
                self.write_to_log(msg, 'ERROR')
                sys.exit(1)
            return 0
        else:
            if os.path.isfile(path):
                os.chmod(path, *f_args)
                msg = 'changed permissions of %s to %s' % (
                    path, file_permissions
                )
                self.write_to_log(msg, 'INFO')
            elif os.path.isdir(path):
                os.chmod(path, *d_args)
                msg = 'changed permissions of %s to %s' % (
                    path, dir_permissions
                )
                self.write_to_log(msg, 'INFO')

    def own(self, path, owner, group):
        """
        Recursively sets ownership to owner:group in path.
        :param path: path to change ownership in
        :param owner: owner
        :param group: group
        :return: nothing
        """
        args = (owner, group)
        try:
            shutil.chown(path, owner, group)
            self.walktree(path, shutil.chown, args, shutil.chown, args)
            msg = 'changed ownership of %s to %s:%s' % (path, owner, group)
            self.write_to_log(msg, 'INFO')
        except PermissionError as error:
            msg = '%s on: %s' % (error.strerror, error.filename)
            self.write_to_log(msg, 'ERROR')
            sys.exit(1)
        return 0

    def check_pending(self, path):
        """
        checks whether a directory is an acceptance tests or pending tests directory and appends it to self.pending_dirs
        if so
        """
        if os.path.basename(path) in ['acceptance_tests', 'pending_tests']:
            self.pending_dirs.append(path)

    def get_pending_dirs(self, top, app_name):
        """
        scans app and returns list of pending tests directories
        :return: list of pending tests directories paths
        """
        self.walktree(top, d_callback=self.check_pending)
        self.pending_dirs = ['.%s' % p[(len(top) + len(app_name) + 1):] for p in self.pending_dirs]
        return self.pending_dirs

    def check_process(self, process):
        """
        checks whether a process is running by process name
        :param process: process name
        """
        for proc in psutil.process_iter():
            try:
                pinfo = proc.as_dict(attrs=['pid', 'name'])
            except psutil.NoSuchProcess:
                pass
            else:
                if pinfo['name'] == process:
                    return True
                else:
                    pass
        return False
