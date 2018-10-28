# Cookbook Name:: django_app_server
# Server Spec:: python

require 'spec_helper'

set :backend, :exec

describe command ( 'pip3 list' ) do
  its(:stdout) { should match(/uWSGI/)}
end

describe file('/var/log/uwsgi') do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 755 }
end

