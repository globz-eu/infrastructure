# Cookbook Name:: install_scripts
# Recipe:: user

users = node['install_scripts']['users']

unless users.empty?
  users.each do |u|
    user_name = u[:user]
    user_pwd = u[:password]

    user user_name do
      home "/home/#{user_name}"
      manage_home true
      shell '/bin/bash'
      password user_pwd
    end if user_name and user_pwd

    unless u[:groups].empty?
      u[:groups].each do |g|
        group g do
          members u[:user]
          append true
        end
      end
    end unless u[:groups].nil?
  end
end
