# Cookbook Name:: basic_node
# Recipe:: openssh

include_recipe 'chef-vault'

node_admin_item = chef_vault_item('basic_node', "node_admin#{node['basic_node']['node_number']}")
admin_user = node_admin_item['user']
admin_key = node_admin_item['key']

package 'openssh-server'

service 'ssh' do
  action [:start, :enable]
end

directory "/home/#{admin_user}/.ssh" do
  owner admin_user
  group admin_user
  mode '0750'
end

template "/home/#{admin_user}/.ssh/authorized_keys" do
  source 'authorized_keys.erb'
  action :create
  owner admin_user
  group admin_user
  mode '0640'
  variables({
                admin_key: admin_key,
            })
end

if node['openssh']['sshd']['authorized_users']
  allowed_users = [admin_user] + node['openssh']['sshd']['authorized_users']
else
  allowed_users = [admin_user]
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  variables({
                permit_root_login: node['openssh']['sshd']['permit_root_login'],
                password_authentication: node['openssh']['sshd']['password_authentication'],
                pubkey_authentication: node['openssh']['sshd']['pubkey_authentication'],
                rsa_authentication: node['openssh']['sshd']['rsa_authentication'],
                allowed_users: allowed_users.join(' ')
            })
  notifies :restart, 'service[ssh]', :immediately
end
