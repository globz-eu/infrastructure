# Cookbook:: web_server
# Server Spec:: default

require 'default'

# Cookbook:: web_server
# Server Spec:: web_user

require 'web_user'

# Cookbook:: web_server
# Server Spec:: nginx

app_name = 'django_base'
ips = {'14.04' => '192.168.1.84', '16.04' => '192.168.1.85'}
https = false

require 'nginx'
nginx_spec(app_name, ips, https)
