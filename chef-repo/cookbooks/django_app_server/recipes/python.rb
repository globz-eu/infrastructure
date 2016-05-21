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
#
# Cookbook Name:: django_app_server
# Recipe:: python
#
# Installs python3.4 or python3.5 runtime

if node['platform_version'].include?('14.04')
  # install python3.4 runtime
  python_runtime '3.4'

  bash 'install_virtualenv' do
    code 'pip install virtualenv'
    user 'root'
    not_if 'pip list | grep virtualenv', :user => 'root'
  end
end

if node['platform_version'].include?('16.04')
  # install python3.5 runtime
  package ['python3.5-dev', 'python3-pip', 'python3-venv']
end
