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
