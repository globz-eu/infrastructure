# Cookbook Name:: django_app_server
# Server Spec:: default

require 'default'

# Cookbook:: django_app_server
# Server Spec:: app_user

require 'app_user'

# Cookbook Name:: django_app_server
# Server Spec:: python

require 'python'

# Cookbook Name:: django_app_server
# Server Spec:: django_app

require 'django_app'
app_name = 'django_base'
ips = {'14.04' => '192.168.1.82', '16.04' => '192.168.1.83'}
django_app_spec(app_name: app_name,ips: ips)

# Cookbook Name:: django_app_server
# Server Spec:: uwsgi

require 'uwsgi'
