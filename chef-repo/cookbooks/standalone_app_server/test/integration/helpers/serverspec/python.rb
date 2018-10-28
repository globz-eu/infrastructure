# Cookbook Name:: django_app_server
# Server Spec:: python

require 'spec_helper'

set :backend, :exec

if os[:release] == '14.04'
  describe package('python3.4') do
    it { should be_installed }
  end

  describe file('/usr/bin/python3.4') do
    it { should exist }
    it { should be_file }
  end

  describe command ( 'pip -V' ) do
    pip3_version = %r(pip \d+\.\d+\.\d+ from /usr/local/lib/python3\.4/dist-packages \(python 3\.4\))
    its(:stdout) { should match(pip3_version)}
  end

  describe package('python3.4-dev') do
    it { should be_installed }
  end

  describe command ('pip list | grep virtualenv') do
    its(:stdout) { should match(/virtualenv\s+\(\d+\.\d+\.\d+\)/)}
  end
end

if os[:release] == '16.04'
  describe package('python3.5') do
    it { should be_installed }
  end

  describe file('/usr/bin/python3.5') do
    it { should exist }
    it { should be_file }
  end

  describe command ( 'pip3 -V' ) do
    pip3_version = %r(pip \d+\.\d+\.\d+ from /usr/local/lib/python3\.5/dist-packages \(python 3\.5\))
    its(:stdout) { should match(pip3_version)}
  end

  describe package('python3.5-dev') do
    it { should be_installed }
  end

  describe package('python3-pip') do
    it { should be_installed }
  end

  describe package('python3-venv') do
    it { should be_installed }
  end
end

