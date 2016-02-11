default['basic_node']['admin_user']['node_admin'] = 'node_admin'

default['openssh']['sshd']['permit_root_login'] = 'no'
default['openssh']['sshd']['password_authentication'] = 'no'
default['openssh']['sshd']['pubkey_authentication'] = 'yes'
default['openssh']['sshd']['rsa_authentication'] = 'yes'

default['basic_node']['node_admin']['secret_path'] = '/etc/chef/encrypted_data_bag_secret'