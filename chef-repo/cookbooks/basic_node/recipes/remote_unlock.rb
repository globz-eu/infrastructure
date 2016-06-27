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
# Recipe:: remote_unlock

include_recipe 'chef-vault'

node_number = node['basic_node']['node_number']
node_admin_item = chef_vault_item('basic_node', "node_admin#{node_number}")
node_ip_item = chef_vault_item('basic_node', "node_ips#{node_number}")

package 'dropbear'

directory '/etc/initramfs-tools/root/.ssh' do
  owner 'root'
  group 'root'
  mode '0750'
  recursive true
end

template '/etc/initramfs-tools/root/.ssh/authorized_keys' do
  owner 'root'
  group 'root'
  mode '0640'
  source 'authorized_keys.erb'
  variables({
      admin_key: node_admin_item['key']
            })
end

template '/etc/initramfs-tools/hooks/crypt_unlock.sh' do
  owner 'root'
  group 'root'
  mode '0750'
  source 'crypt_unlock.sh.erb'
end

template '/usr/share/initramfs-tools/scripts/init-bottom/dropbear' do
  owner 'root'
  group 'root'
  mode '0640'
  source 'dropbear.erb'
  variables({
      interface: node_ip_item['local_interface']
            })
end

template '/etc/initramfs-tools/initramfs.conf' do
  owner 'root'
  group 'root'
  mode '0640'
  source 'initramfs.conf.erb'
  variables({
      interface: node_ip_item['local_interface'],
      ip: node_ip_item['local_ip'],
      netmask: node_ip_item['local_mask'],
      dropbear: 'DROPBEAR=y'
            })
end

execute 'update-initramfs -u' do
  action :nothing
  subscribes :run, 'template[/etc/initramfs-tools/initramfs.conf]', :immediate
end

execute 'update-rc.d -f dropbear remove' do
  action :nothing
  subscribes :run, 'execute[update-initramfs -u]', :immediate
end
