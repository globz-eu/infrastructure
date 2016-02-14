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

include_recipe 'chef-vault'

admin_email_vault_item = chef_vault_item('basic_node', 'node_admin')

package 'unattended-upgrades'

template '/etc/apt/apt.conf.d/50unattended-upgrades' do
  source '50unattended-upgrades.erb'
  action :create
  owner 'root'
  mode '0644'
  variables(admin_email: admin_email_vault_item['email'])
end

template '/etc/apt/apt.conf.d/10periodic' do
  source '10periodic.erb'
  action :create
  owner 'root'
  mode '0644'
end

package 'apticron'

template '/etc/apticron/apticron.conf' do
  source 'apticron.conf.erb'
  action :create
  owner 'root'
  mode '0644'
  variables(admin_email: admin_email_vault_item['email'])
end
