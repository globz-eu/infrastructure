from tests.helpers import Alternate
from tests.conf_tests import DIST_VERSION, LOG_FILE, LOG_LEVEL
from utilities.commandfileutils import CommandFileUtils

__author__ = 'Stefan Dieterle'

alt_bool = Alternate([])


def check_process_mock(process):
    global alt_bool
    return alt_bool(process)


def own_app_mock(path, owner, group):
    cfu = CommandFileUtils(DIST_VERSION, LOG_FILE, LOG_LEVEL)
    cfu.write_to_log('changed ownership of %s to %s:%s' % (path, owner, group), 'INFO')
