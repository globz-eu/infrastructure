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

# chef_gem 'chef-vault'
# require 'chef-vault'

# node_admin_password = ChefVault::Item.load('basic_node', 'node_admin')

# Load the secrets file and the encrypted data bag item that holds the root and user passwords
password_secret = Chef::EncryptedDataBagItem.load_secret(node['basic_node']['node_admin']['secret_path'])
node_admin_password = Chef::EncryptedDataBagItem.load('basic_node', 'node_admin', password_secret)

user node['basic_node']['admin_user']['node_admin'] do
  home '/home/' + node['basic_node']['admin_user']['node_admin']
  supports :manage_home => true
  password node_admin_password['password']
  shell '/bin/bash'
end