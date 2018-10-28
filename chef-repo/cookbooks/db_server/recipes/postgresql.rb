# Cookbook Name:: db_server
# Recipe:: postgresql
#
# Installs and configures a postgresql9.5 server, creates a database and
# a db user with default SELECT, INSERT, UPDATE, DELETE privileges

include_recipe 'chef-vault'

postgres_vault = chef_vault_item('pg_server', "postgres#{node['db_server']['node_number']}")
db_user_vault = chef_vault_item('pg_server', "db_user#{node['db_server']['node_number']}")
db_user = db_user_vault['user']
db_admin_user = postgres_vault['user']
node.default['postgresql']['password']['postgres'] = postgres_vault['password']
app_repo = node['db_server']['git']['app_repo']
app_name = false
db_name = false
if app_repo
  /https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
  if name
    app_name = name.downcase
    db_name = name.downcase
  end
end

if node['platform_version'].include?('14.04')
  include_recipe 'postgresql::server'
  include_recipe 'postgresql::contrib'
elsif node['platform_version'].include?('16.04')
  package %w(postgresql postgresql-contrib-9.5 postgresql-server-dev-9.5)

  service 'postgresql' do
    action :start
  end

  bash 'set_postgres_password' do
    code "sudo -u #{postgres_vault['user']} psql -c \"ALTER USER #{postgres_vault['user']} WITH PASSWORD '#{postgres_vault['password']}';\""
    user 'root'
  end

  template('/etc/postgresql/9.5/main/pg_hba.conf') do
    owner 'postgres'
    group 'postgres'
    mode '0600'
    source 'pg_hba.conf.erb'
    variables({
                  postgres_local: 'ident',
                  all_local: 'md5',
                  all_IPv4: 'md5',
                  all_IPv6: 'md5',
              })
    notifies :restart, 'service[postgresql]', :immediately
  end
end

if db_name
  bash 'create_user' do
    code "sudo -u #{postgres_vault['user']} psql -c \"CREATE USER #{db_user} WITH PASSWORD '#{db_user_vault['password']}';\""
    user 'root'
    not_if "sudo -u #{postgres_vault['user']} psql -c '\\du' | grep #{db_user}", :user => 'root'
  end

  template "/home/#{db_user}/sites/#{app_name}/scripts/conf.py" do
    owner db_user
    group db_user
    mode '0400'
    source 'conf.py.erb'
    variables({
        dist_version: node['platform_version'],
        log_level: 'DEBUG',
        nginx_conf: '',
        git_repo: app_repo,
        app_home: '',
        app_home_tmp: '',
        app_user: '',
        web_user: '',
        webserver_user: '',
        db_user: db_user,
        db_admin_user: db_admin_user,
        static_path: '',
        media_path: '',
        uwsgi_path: '',
        down_path: '',
        log_file: "/var/log/#{app_name}/create_db.log",
        fifo_dir: ''
              })
  end

  bash 'run_create_database' do
    cwd "/home/#{db_user}/sites/#{app_name}/scripts"
    code './dbserver.py -c'
    user 'root'
  end
end
