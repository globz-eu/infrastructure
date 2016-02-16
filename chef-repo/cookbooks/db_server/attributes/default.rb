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

default['postgresql']['version'] = '9.5'
default['postgresql']['enable_pgdg_apt'] = true
default['postgresql']['dir'] = '/etc/postgresql/9.5/main'
default['postgresql']['client']['packages'] = ['postgresql-server-dev-9.5', 'postgresql-client-9.5']
default['postgresql']['server']['packages'] = ['postgresql-server-dev-9.5', 'postgresql-9.5']
default['postgresql']['server']['service_name'] = 'postgresql'
default['postgresql']['contrib']['packages'] = ['postgresql-contrib-9.5']
