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
# Cookbook:: install_scripts
# Spec:: user

require 'spec_helper'

set :backend, :exec

users = [{
             user: 'app_user',
             password: '$6$3lI29czRRrey9x4$1OF/0nPqqKXUTTNk1zTvMJBbuAdn7ZmjB1OokHFbhlwBRLTZZGgYsLe1gRZE9sC8LhNfvouIl4/8BovOpMR440',
             group: 'www-data',
         },
         {
             user: 'web_user',
             password: '$6$2gyFi.Z4G5U$mixtbKdAjZJJbt9Uatd0gaFf80XvSVKYSjXz01.Cb0Qztsy74Z/Os92bcGu1OoaoI.Btsx0Z5X3x.xm7svejP1',
         },
         {
             user: 'db_user',
             password: '$6$J2qPIW16o3S6MvW0$3XCyfHwXLj9QKnyhvAhzUocSxdKvoqfpV3ygAuepvEaslfMsEs5F0eeDFDQmMS4tNTuFfe4ZulTyJy2LPl0a21',
         }
]

users.each do |u|
  describe user( u[:user] ) do
    it { should exist }
    it { should belong_to_group u[:user] }
    unless u[:group].nil?
      it { should belong_to_group u[:group] }
    end
    it { should have_home_directory "/home/#{u[:user]}" }
    it { should have_login_shell '/bin/bash' }
    its(:encrypted_password) {
      should match( u[:password] )
    }
  end
end
