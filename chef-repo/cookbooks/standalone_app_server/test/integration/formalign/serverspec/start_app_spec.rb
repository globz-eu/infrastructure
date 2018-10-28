# Cookbook:: standalone_app_server
# Server Spec:: start_app

require 'start_app'
app_name = 'formalign'
https = true
ips = {'14.04' => '192.168.1.86', '16.04' => '192.168.1.87'}
start_app_spec(app_name, ips, https)
