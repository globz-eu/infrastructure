# =====================================================================
# Web app infrastructure for Django project
# Copyright (C) 2016 Stefan Dieterle
# e-mail: golgoths@yahoo.fr
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# =====================================================================
#
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
