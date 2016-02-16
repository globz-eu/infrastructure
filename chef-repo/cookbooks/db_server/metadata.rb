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

name 'db_server'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
description 'Installs/Configures db_server'
long_description 'Installs/Configures db_server'
version '0.1.1'

depends 'apt', '~> 2.9.2'
depends 'test-helper'
depends 'chef-vault', '~> 1.3.2'
depends 'firewall', '~> 2.4.0'
depends 'basic_node', '~> 0.1.12'
depends 'postgresql', '~> 4.0.0'
depends 'database', '~> 4.0.9'