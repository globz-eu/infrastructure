# Cookbook:: django_app_server
# Server Spec:: app_user

require 'spec_helper'

set :backend, :exec

describe user( 'app_user' ) do
  it { should exist }
  it { should belong_to_group 'app_user' }
  it { should belong_to_group 'www-data' }
  it { should belong_to_group 'loggers' }
  it { should have_home_directory '/home/app_user' }
  it { should have_login_shell '/bin/bash' }
  its(:encrypted_password) { should match('$6$g7n0bpuYPHBI.$FVkbyH37IcBhDc000UcrGZ/u4n1f9JaEhLtBrT1VcAwKXL1sh9QDoTb3leMdazZVLQuv/w1FCBeqXX6GZGWid/') }
end
