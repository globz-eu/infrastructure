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

