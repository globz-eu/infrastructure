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
# Recipe:: default

include_recipe 'chef-vault'

node_admin_item = chef_vault_item('basic_node', "node_admin#{node['basic_node']['node_number']}")

node.default['apt']['unattended_upgrades']['mail'] = node_admin_item['email']

include_recipe 'apt::default'
include_recipe 'apt::unattended-upgrades'

resources('package[bsd-mailx]').action []

include_recipe 'basic_node::mail'
include_recipe 'basic_node::admin_user'
include_recipe 'basic_node::openssh'
include_recipe 'basic_node::security_updates'
include_recipe 'basic_node::firewall'
include_recipe 'basic_node::ntp'
include_recipe 'basic_node::remote_unlock'
