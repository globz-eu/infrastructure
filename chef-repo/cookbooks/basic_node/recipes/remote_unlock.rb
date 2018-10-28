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
  notifies :run, 'execute[update-initramfs -u]', :immediately
end

execute 'update-initramfs -u' do
  action :nothing
  notifies :run , 'execute[update-rc.d -f dropbear remove]', :immediately
end

execute 'update-rc.d -f dropbear remove' do
  action :nothing
end
