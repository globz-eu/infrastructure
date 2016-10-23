"""
=====================================================================
Chef server infrastructure
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
"""

import requests
import os
from utilities.commandfileutils import CommandFileUtils
from conf import DOWNLOAD_FOLDER

__author__ = 'Stefan Dieterle'


class InstallFromURL(CommandFileUtils):
    """
    Installs a package from a URL
    """

    def __init__(self, dist_version='16.04', log_file='/tmp/install_from_url.log', log_level='INFO',
                 metadata_url=None, download_folder=DOWNLOAD_FOLDER):
        """
        Initializes parameters.
        :param dist_version: distribution version
        :param log_file: log file path
        :param log_level: log level
        :param metadata_url: url for retrieving metadata
        :param download_folder: folder to download package and metadata to
        """
        CommandFileUtils.__init__(self, dist_version, log_file, log_level)
        self.metadata_url = metadata_url
        self.download_folder = download_folder

    def retrieve_metadata(self):
        """
        Retrieves the metadata file for the package. Writes the sha256 file for the package.
        :return package metadata as a dict: {
                                                'status_code': response status code,
                                                'sha1': sha1 sum of package,
                                                'sha256': sha256 sum of package,
                                                'url': download url of package,
                                                ''version': package version
                                            }
        """
        os.makedirs(self.download_folder, exist_ok=True)
        payload = {'p': 'ubuntu', 'pv': '16.04', 'm': 'x86_64'}
        r = requests.get(self.metadata_url, params=payload)
        r_text = r.content.decode('utf-8')
        r_dict = {k: v for k, v in [l.split('\t') for l in r_text.split('\n')]}
        r_dict['status_code'] = r.status_code
        with open(os.path.join(self.download_folder, 'chef-server.sha256'), 'w') as sha256_file:
            sha256_file.write('%s\tchef-server.deb\n' % (r_dict['sha256']))
        self.write_to_log('successfully retrieved metadata for chef-server.deb', 'INFO')
        return r_dict

    def install_chef_server(self):
        meta = self.retrieve_metadata()
        cmds = [
            {'cmd': [
                'wget',
                meta['url'],
                '-O',
                'chef-server.deb'
            ],
                'msg': 'successfully downloaded chef-server'
            },

            {'cmd': [
                'sha256sum', '-c', 'chef-server.sha256', '2>&1', '|', 'grep', 'OK'
            ],
                'msg': 'sha256sum verified'
            },
            {'cmd': [
                'dpkg', '-i', 'chef-server.deb'
            ], 'msg': 'successfully installed chef-server package'}
        ]
        for cmd in cmds:
            run = self.run_command(cmd['cmd'], cmd['msg'], cwd=self.download_folder)
            if run != 0:
                return run
        return 0
