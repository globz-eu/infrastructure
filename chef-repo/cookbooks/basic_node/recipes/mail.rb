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
# Recipe:: mail

include_recipe 'chef-vault'

smtp_vault = chef_vault_item('basic_node', "node_smtp#{node['basic_node']['node_number']}")

package 'ssmtp'

package 'mailutils'

template '/etc/ssmtp/ssmtp.conf' do
  source 'ssmtp.conf.erb'
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  variables({
                auth_user: smtp_vault['auth_user'],
                password: smtp_vault['password'],
                mail_hub: smtp_vault['mail_hub'],
                TLS: node['basic_node']['mail']['ssmtp_conf']['TLS'],
                port: node['basic_node']['mail']['ssmtp_conf']['port']
            })
end

