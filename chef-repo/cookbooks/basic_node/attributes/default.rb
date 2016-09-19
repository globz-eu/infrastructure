default['openssh']['sshd']['permit_root_login'] = 'no'
default['openssh']['sshd']['password_authentication'] = 'no'
default['openssh']['sshd']['pubkey_authentication'] = 'yes'
default['openssh']['sshd']['rsa_authentication'] = 'yes'
default['openssh']['sshd']['authorized_users'] = ['vagrant']



default['firewall']['ufw']['defaults']['policy'] = {
    input: 'DROP',
    output: 'DROP',
    forward: 'DROP',
    application: 'SKIP'
}

default['apt']['unattended_upgrades']['enable'] = true
default['apt']['unattended_upgrades']['allowed_origins'] = ['Ubuntu trusty-security']
default['apt']['unattended_upgrades']['mail'] = 'admin@example.com'
default['apt']['unattended_upgrades']['remove_unused_dependencies'] = true

default['basic_node']['node_number'] = '000'
default['basic_node']['node_admin']['secret_path'] = '/etc/chef/encrypted_data_bag_secret'
default['basic_node']['mail']['ssmtp_conf']['TLS'] = 'YES'
default['basic_node']['mail']['ssmtp_conf']['port'] = '587'
default['basic_node']['firewall']['mail'] = true
default['basic_node']['firewall']['web_server'] = false
default['basic_node']['remote_unlock']['encryption'] = false
