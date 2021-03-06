# Cookbook Name:: install_scripts
# Server Spec:: scripts

require 'spec_helper'

set :backend, :exec

if os[:family] == 'ubuntu'
  describe package('python3-pip') do
    it { should be_installed }
  end

  # log directory for scripts should be present
  describe file('/var/log/django_base') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 755 }
  end
  users = [{
                user: 'app_user',
                group: 'www-data',
                mode: 550,
                scripts: ['djangoapp.py']
            },
            {
                user: 'web_user',
                group: 'web_user',
                mode: 500,
                scripts: %w(webserver.py djangoapp.py)
            },
            {
                user: 'db_user',
                group: 'db_user',
                mode: 500,
                scripts: ['dbserver.py']
            }
  ]

  users.each do |u|
    # File structure for scripts should be present
    describe file("/home/#{u[:user]}/sites") do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by u[:user] }
      it { should be_grouped_into u[:group] }
      it { should be_mode u[:mode] }
    end

    describe file("/home/#{u[:user]}/sites/django_base") do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by u[:user] }
      it { should be_grouped_into u[:group] }
      it { should be_mode u[:mode] }
    end

    # Install scripts should be present
    describe file("/home/#{u[:user]}/sites/django_base/scripts") do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by u[:user] }
      it { should be_grouped_into u[:user] }
      it { should be_mode 500 }
    end

    u[:scripts].each do |s|
      describe file "/home/#{u[:user]}/sites/django_base/scripts/#{s}" do
        it { should exist }
        it { should be_file }
        it { should be_owned_by u[:user] }
        it { should be_grouped_into u[:user] }
        it { should be_mode 500 }
      end
    end

    describe file "/home/#{u[:user]}/sites/django_base/scripts/utilities/commandfileutils.py" do
      it { should exist }
      it { should be_file }
      it { should be_owned_by u[:user] }
      it { should be_grouped_into u[:user] }
      it { should be_mode 400 }
    end

    describe file "/home/#{u[:user]}/sites/django_base/scripts/requirements.txt" do
      it { should exist }
      it { should be_file }
      it { should be_owned_by u[:user] }
      it { should be_grouped_into u[:user] }
      it { should be_mode 400 }
    end
  end

  # Scripts dependencies should be present
  describe command ('pip3 list | grep psutil') do
    its(:stdout) { should match(/psutil\s+\(\d+\.\d+\.\d+\)/)}
  end
end