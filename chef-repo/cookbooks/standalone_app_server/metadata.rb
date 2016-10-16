# =====================================================================
# Web app infrastructure for Django project
# Copyright (C) 2016 Stefan Dieterle
# e-mail: golgoths@yahoo.fr
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# =====================================================================

name 'standalone_app_server'
maintainer 'Stefan Dieterle'
maintainer_email 'golgoths@yahoo.fr'
license 'GNU General Public License'
description 'Installs/Configures standalone_app_server'
long_description 'Installs/Configures standalone_app_server'
version '0.2.4'

depends 'basic_node', '~> 0.2.0'
depends 'django_app_server', '~> 0.2.1'
depends 'chef-vault', '~> 1.3.3'
depends 'apt', '~> 4.0.1'
depends 'test-helper'
depends 'firewall', '~> 2.5.2'
depends 'postgresql', '~> 4.0.6'
depends 'database', '~> 5.1.2'
depends 'db_server', '~> 0.2.1'
depends 'web_server', '~> 0.2.0'
depends 'install_scripts', '~> 0.1.6'
