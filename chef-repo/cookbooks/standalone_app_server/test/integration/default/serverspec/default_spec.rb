# Cookbook Name:: standalone_app_server
# Server Spec:: default

app_name = 'django_base'
ips = {'14.04' => '192.168.1.86', '16.04' => '192.168.1.87'}
https = false

require 'default'

# Cookbook:: db_server
# Server Spec:: db_user

require 'db_user'

# Cookbook:: db_server
# Server Spec:: postgresql

require 'postgresql'
postgresql_spec(app_name)

# Cookbook:: db_server
# Server Spec:: redis

require 'redis'

# Cookbook:: web_server
# Spec:: web_user

require 'web_user'

# Cookbook:: web_server
# Server Spec:: nginx

require 'nginx'
nginx_spec(app_name, ips, https, site_down: false)

# Cookbook:: django_app_server
# Server Spec:: app_user

require 'app_user'

# Cookbook Name:: django_app_server
# Server Spec:: python

require 'python'

# Cookbook Name:: django_app_server
# Server Spec:: django_app

require 'django_app'
django_app_spec(app_name: app_name, ips: ips)

# Cookbook Name:: django_app_server
# Server Spec:: uwsgi

require 'uwsgi'
