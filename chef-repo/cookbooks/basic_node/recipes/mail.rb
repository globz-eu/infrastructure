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

smtp_auth_vault_item = chef_vault_item("basic_node#{node['basic_node']['node_number']}", 'node_smtp')

package 'ssmtp'

package 'mailutils'

template '/etc/ssmtp/ssmtp.conf' do
  source 'ssmtp.conf.erb'
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  variables({
                auth_user: smtp_auth_vault_item['auth_user'],
                password: smtp_auth_vault_item['password'],
                mail_hub: smtp_auth_vault_item['mail_hub'],
                TLS: node['mail']['ssmtp_conf']['TLS'],
                port: node['mail']['ssmtp_conf']['port']
            })
end

firewall_rule 'mail' do
  protocol :tcp
  direction :out
  command :allow
  port 587
end
