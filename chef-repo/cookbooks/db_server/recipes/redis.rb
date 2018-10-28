include_recipe 'apt'
include_recipe 'chef-vault'

if node['db_server']['redis']['install']
  apt_repository 'redis-server' do
    repo_name 'redis-server'
    uri 'ppa:chris-lea/redis-server'
    deb_src true
  end

  package 'redis-server'
end