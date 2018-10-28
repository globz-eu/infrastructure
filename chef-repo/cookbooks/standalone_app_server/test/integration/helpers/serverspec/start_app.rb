# Cookbook:: standalone_app_server
# Server Spec:: start_app

require 'spec_helper'

set :backend, :exec

def start_app_spec(app_name, ips, https)
  # manages migrations
  describe command ( "su - app_user -c 'cd && .envs/#{app_name}/bin/python sites/#{app_name}/source/#{app_name}/manage.py makemigrations base #{app_name}'" ) do
    its(:stdout) { should match(/^No changes detected in apps/)}
  end

  describe command ( "su - app_user -c 'cd && .envs/#{app_name}/bin/python sites/#{app_name}/source/#{app_name}/manage.py migrate base'" ) do
    its(:stdout) { should match(/No migrations to apply\./)}
  end

  # runs app tests
  describe file("/var/log/#{app_name}") do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'loggers' }
    it { should be_mode 775 }
  end

  describe file("/var/log/#{app_name}/test_results") do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 700 }
  end

  describe command("ls /var/log/#{app_name}/test_results | tail -1 ") do
    its(:stdout) { should match(/^test_\d{8}-\d{6}\.log$/)}
  end

  describe command("cat $(ls /var/log/#{app_name}/test_results | tail -1) | grep FAILED") do
    its(:stdout) { should_not match(/FAILED/)}
  end

  # nginx is running and site is enabled
  describe file("/etc/nginx/sites-enabled/#{app_name}.conf") do
    it { should exist }
    it { should be_symlink }
    it { should be_owned_by 'root'}
    it { should be_grouped_into 'root' }
    its(:content) { should match (/^# #{app_name}.conf$/) }
  end

  describe file("/etc/nginx/sites-enabled/#{app_name}_down.conf") do
    it { should_not exist }
  end

  describe service('nginx') do
    it { should be_enabled }
    it { should be_running }
  end

  # uwsgi is running
  describe command ( 'pgrep uwsgi' ) do
    its(:stdout) { should match(/^\d+$/) }
  end

  # celery is running
  describe file("/var/log/#{app_name}/celery") do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 700 }
  end

  describe file("/var/run/#{app_name}") do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 700 }
  end

  describe file("/var/run/#{app_name}/celery") do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 700 }
  end

  describe file("/var/run/#{app_name}/celery/w1.pid") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 644 }
  end

  # site is up
  if https
    cmd = "curl -k https://#{ips[os[:release]]}"
  else
    cmd = "curl http://#{ips[os[:release]]}"
  end
  describe command("#{cmd}") do
    its(:stdout) {should match(%r(^\s+<title id="head-title">#{app_name}(\.eu|\.org){0,1} home</title>$)i)}
  end

  # old alignments have been removed
  if app_name == 'formalign'
    title = %r(^\s+<title id="head-title">#{app_name}(\.eu|\.org){0,1} error 404</title>$)i
  elsif app_name == 'django_base'
    title = %r(^<h1>Not Found</h1><p>The requested URL /align-display/ToOldAlignment01 was not found on this server\.</p>$)i
  end
  if https
    cmd = "curl -k https://#{ips[os[:release]]}/align-display/ToOldAlignment01"
  else
    cmd = "curl http://#{ips[os[:release]]}/align-display/ToOldAlignment01"
  end
  describe command("#{cmd}") do
    its(:stdout) {should match(title)}
  end
end
