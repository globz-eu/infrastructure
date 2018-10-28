# Cookbook:: standalone_app_server
# Recipe:: start_app

include_recipe 'chef-vault'

node_nr = node['standalone_app_server']['node_number']

app_user_vault = chef_vault_item('app_user', "app_user#{node_nr}")
app_user = app_user_vault['user']
web_user_item = chef_vault_item('web_user', "web_user#{node_nr}")
web_user = web_user_item['user']
app_repo = node['standalone_app_server']['git']['app_repo']
/https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
unless name == nil
  app_name = name.downcase
end

celery = node['standalone_app_server']['start_app']['celery']

directory "/var/log/#{app_name}/test_results" do
  owner 'root'
  group 'root'
  mode '0700'
end

bash 'update_app_user_pip' do
  code "/home/#{app_user}/.envs/#{app_name}/bin/pip install --upgrade pip"
  user app_user
end

bash 'update_web_user_pip' do
  code "/home/#{web_user}/.envs/#{app_name}/bin/pip install --upgrade pip"
  user web_user
end

bash 'migrate_and_test' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -mt'
  user 'root'
end

bash 'start_celery' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -c start'
  user 'root'
end if celery

bash 'start_uwsgi' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -u start'
  user 'root'
end

bash 'init_users' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code "/home/#{app_user}/.envs/#{app_name}/bin/python ./initialize/init_users.py"
  user 'root'
  only_if "ls /home/#{app_user}/sites/#{app_name}/source/#{app_name}/initialize/init_users.py"
end

bash 'init_data' do
  cwd "/home/#{app_user}/sites/#{app_name}/source/#{app_name}"
  code "/home/#{app_user}/.envs/#{app_name}/bin/python ./initialize/init_data.py"
  user 'root'
  only_if "ls /home/#{app_user}/sites/#{app_name}/source/#{app_name}/initialize/init_data.py"
end

bash 'restart_celery' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -c restart'
  user 'root'
end if celery

bash 'restart_uwsgi' do
  cwd "/home/#{app_user}/sites/#{app_name}/scripts"
  code './djangoapp.py -u restart'
  user 'root'
end

bash 'server_up' do
  cwd "/home/#{web_user}/sites/#{app_name}/scripts"
  code './webserver.py -s up'
  user 'root'
end
