import re
import sys
import datetime
import subprocess
from subprocess import CalledProcessError
from tests.conf_tests import DB_ADMIN_USER, GIT_REPO, LOG_FILE, DIST_VERSION

__author__ = 'Stefan Dieterle'


def run_command_mock(cmd, msg, cwd=None, out=None, log_error=True):
    git_repo = GIT_REPO
    p = re.compile('https://github.com/[\w\-]+/(\w+)\.git')
    db_name = p.match(git_repo).group(1)
    if DIST_VERSION == '14.04':
        run = subprocess.check_call
        check = False
    elif DIST_VERSION == '16.04':
        run = subprocess.run
        check = True
    if check:
        kwargs = dict(check=True)
    else:
        kwargs = {}
    try:
        if out:
            with open(out, 'a') as log:
                kwargs.update(dict(cwd=cwd, stdout=log, stderr=log))
                try:
                    run(cmd, **kwargs)
                    now = datetime.datetime.utcnow()
                    log.write('%s %s: %s\n' % (now.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3], 'INFO', msg))
                except CalledProcessError:
                    if 'CREATE DATABASE %s;' % db_name in cmd:
                        db_exists_msg = 'ERROR:  database "%s" already exists\n' % db_name
                    elif 'DROP DATABASE %s;' % db_name in cmd:
                        db_exists_msg = 'ERROR:  database "%s" does not exist\n' % db_name
                    log.write(db_exists_msg)
                    raise CalledProcessError(returncode=1, cmd=cmd)
    except CalledProcessError as error:
        if log_error:
            err_msg = '%s exited with exit code %s' % (' '.join(error.cmd), str(error.returncode))
            with open(out, 'a') as log:
                now = datetime.datetime.utcnow()
                log.write('%s %s: %s\n' % (now.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3], 'ERROR', err_msg))
        sys.exit(1)
    return 0
