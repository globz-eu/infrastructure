# Cookbook Name:: install_scripts
# Recipe:: scripts

users = node['install_scripts']['users']
app_repo = node['install_scripts']['git']['app_repo']
/https:\/\/github.com\/[\w\-]+\/(?<name>\w+)\.git/ =~ app_repo
unless name == nil
  app_name = name.downcase
end
scripts = {web: %w(scripts/webserver.py scripts/djangoapp.py), app: ['scripts/djangoapp.py'], db: ['scripts/dbserver.py']}

package 'python3-pip'

bash 'update_pip' do
  code 'pip3 install --upgrade pip'
  user 'root'
end

unless users.empty?
  directory "/var/log/#{app_name}" do
    owner 'root'
    group 'loggers'
    mode '0775'
  end

  users.each do |u|
    if u[:groups].nil?
      group = u[:user]
      mode = '0500'
    else
      if u[:groups].include? 'www-data'
        group = 'www-data'
        mode = '0550'
      else
        group = u[:user]
        mode = '0500'
      end
    end

    base_dirs = %W(sites sites/#{app_name})
    base_dirs.each do |b|
      directory "/home/#{u[:user]}/#{b}" do
        owner u[:user]
        group group
        mode mode
      end
    end

    scripts_dirs = %W(/home/#{u[:user]}/sites/#{app_name}/scripts /home/#{u[:user]}/sites/#{app_name}/scripts/utilities)
    scripts_dirs.each do |s|
      directory s do
        owner u[:user]
        group u[:user]
        mode '0500'
      end
    end

    scripts[u[:scripts].to_sym].each do |s|
      cookbook_file "/home/#{u[:user]}/sites/#{app_name}/#{s}" do
        source s
        owner u[:user]
        group u[:user]
        mode '0500'
      end
    end

    utility_files = %w(utilities/commandfileutils.py requirements.txt)
    utility_files.each do |ut|
      cookbook_file "/home/#{u[:user]}/sites/#{app_name}/scripts/#{ut}" do
        source "scripts/#{ut}"
        owner u[:user]
        group u[:user]
        mode '0400'
      end
    end
  end

  bash 'install_scripts_requirements' do
    cwd "/home/#{users[0][:user]}/sites/#{app_name}/scripts"
    code 'pip3 install -r requirements.txt'
    user 'root'
  end
end
