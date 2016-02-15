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
# Cookbook Name:: basic_node
# Recipe:: openssh

include_recipe 'chef-vault'

node_admin_vault_item = chef_vault_item('basic_node', 'node_admin')

package 'openssh-server'

service 'ssh' do
  action [:start, :enable]
end

directory "/home/#{node_admin_vault_item['user']}/.ssh"

template "/home/#{node_admin_vault_item['user']}/.ssh/authorized_keys" do
  source 'authorized_keys.erb'
  action :create
  owner node_admin_vault_item['user']
  mode '0640'
  variables({
                admin_key: node_admin_vault_item['key'],
            })
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  action :create
  owner 'root'
  mode '0644'
  variables({
                permit_root_login: node['openssh']['sshd']['permit_root_login'],
                password_authentication: node['openssh']['sshd']['password_authentication'],
                pubkey_authentication: node['openssh']['sshd']['pubkey_authentication'],
                rsa_authentication: node['openssh']['sshd']['rsa_authentication'],
                allowed_users: node_admin_vault_item['user']
            })
  notifies :restart, 'service[ssh]'
end