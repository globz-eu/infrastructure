# Cookbook Name:: django_app_server
# Recipe:: uwsgi
#
# Installs uwsgi python package globally, generates uwsgi.ini config
# file

bash 'uwsgi' do
  code 'pip3 install uwsgi'
  user 'root'
  not_if 'pip3 list | grep uWSGI', :user => 'root'
end

directory '/var/log/uwsgi' do
  owner 'root'
  group 'root'
  mode '0755'
end

