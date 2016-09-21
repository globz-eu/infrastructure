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
# Cookbook:: web_server
# Server Spec:: nginx


require 'serverspec'

set :backend, :exec

if os[:family] == 'ubuntu'
  describe command( 'ufw status numbered' ) do
    expected_rules = [
        %r{^\[(\s|\d)\d\]\s+22/tcp\s+ALLOW IN\s+Anywhere\s*$},
        %r{^\[(\s|\d)\d\]\s+80/tcp\s+ALLOW IN\s+Anywhere\s*$},
        %r{^\[(\s|\d)\d\]\s+22/tcp\s+\(v6\)\s+ALLOW IN\s+Anywhere\s+\(v6\)\s*$},
        %r{^\[(\s|\d)\d\]\s+80/tcp\s+\(v6\)\s+ALLOW IN\s+Anywhere\s+\(v6\)\s*$},
        %r{^\[(\s|\d)\d\]\s+22,53,80,443/tcp\s+ALLOW OUT\s+Anywhere\s+\(out\)$},
        %r{^\[(\s|\d)\d\]\s+53,67,68/udp\s+ALLOW OUT\s+Anywhere\s+\(out\)$},
        %r{^\[(\s|\d)\d\]\s+22,53,80,443/tcp\s+\(v6\)\s+ALLOW OUT\s+Anywhere\s+\(v6\)\s+\(out\)$},
        %r{^\[(\s|\d)\d\]\s+53,67,68/udp\s+\(v6\)\s+ALLOW OUT\s+Anywhere\s+\(v6\)\s+\(out\)$}
    ]
    its(:stdout) { should match(/Status: active/) }
    expected_rules.each do |r|
      its(:stdout) { should match(r) }
    end
  end

  describe package('nginx') do
    it { should be_installed }
  end

  describe service('nginx') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/nginx/sites-available/formalign.conf') do
    if os[:release] == '14.04'
    params = [
        /^# formalign.conf$/,
        %r(^\s+server unix:///home/app_user/sites/formalign/sockets/formalign\.sock; # for a file socket$),
        /^\s+# server 127\.0\.0\.1:8001; # for a web port socket/,
        /^\s+listen\s+80;$/,
        /^\s+server_name\s+192\.168\.1\.85;$/,
        %r(^\s+alias /home/web_user/sites/formalign/media;),
        %r(^\s+alias /home/web_user/sites/formalign/static;),
        %r(^\s+include\s+/home/web_user/sites/formalign/uwsgi/uwsgi_params;$)
    ]
    elsif os[:release] == '16.04'
    params = [
        /^# formalign.conf$/,
        %r(^\s+server unix:///home/app_user/sites/formalign/sockets/formalign\.sock; # for a file socket$),
        /^\s+# server 127\.0\.0\.1:8001; # for a web port socket/,
        /^\s+listen\s+80;$/,
        /^\s+server_name\s+192\.168\.1\.86;$/,
        %r(^\s+alias /home/web_user/sites/formalign/media;),
        %r(^\s+alias /home/web_user/sites/formalign/static;),
        %r(^\s+include\s+/home/web_user/sites/formalign/uwsgi/uwsgi_params;$)
    ]
    end
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 400 }
    params.each do |p|
      its(:content) { should match(p) }
    end
  end

  site_down_conf = %w(/etc/nginx/sites-available/formalign_down.conf
 /etc/nginx/sites-enabled/formalign_down.conf)
  site_down_conf.each() do |f|
    describe file(f) do
      if os[:release] == '14.04'
        params = [
            /^# formalign_down.conf$/,
            %r(^\s+index index.html;$),
            /^\s+listen\s+80;$/,
            /^\s+server_name\s+192\.168\.1\.85;$/,
            %r(^\s+root /home/web_user/sites/formalign/down;)
        ]
      elsif os[:release] == '16.04'
        params = [
            /^# formalign_down.conf$/,
            %r(^\s+index index.html;$),
            /^\s+listen\s+80;$/,
            /^\s+server_name\s+192\.168\.1\.86;$/,
            %r(^\s+root /home/web_user/sites/formalign/down;)
        ]
      end

      if f == '/etc/nginx/sites-available/formalign_down.conf'
        it { should exist }
        it { should be_file }
        it { should be_mode 400 }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
        params.each do |p|
          its(:content) { should match(p) }
        end
      elsif f == '/etc/nginx/sites-enabled/formalign_down.conf'
        it { should_not exist }
      end
    end
  end

  describe file('/home/web_user/sites') do
    it {should exist}
    it {should be_directory}
    it {should be_owned_by 'web_user'}
    it {should be_grouped_into 'www-data'}
    it {should be_mode 550}
  end

  describe file('/home/web_user/sites/formalign') do
    it {should exist}
    it {should be_directory}
    it {should be_owned_by 'web_user'}
    it {should be_grouped_into 'www-data'}
    it {should be_mode 550}
  end

  site_paths = ['static', 'media', 'uwsgi', 'down']
  site_paths.each do |s|
    describe file("/home/web_user/sites/formalign/#{s}") do
      it {should exist}
      it {should be_directory}
      it {should be_owned_by 'web_user'}
      it {should be_grouped_into 'www-data'}
      it {should be_mode 550}
    end
  end

  describe file('/home/web_user/sites/formalign/down/index.html') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'web_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 440 }
    its(:content) { should match(%r(^\s+<title id="head-title">Formalign\.eu Site Down</title>$)) }
  end

  # Install scripts should be present
  describe file('/home/web_user/sites/formalign/scripts') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'web_user' }
    it { should be_grouped_into 'web_user' }
    it { should be_mode 500 }
  end

  scripts = ['webserver.py', 'djangoapp.py']
  scripts.each do |s|
    describe file "/home/web_user/sites/formalign/scripts/#{s}" do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'web_user' }
      it { should be_grouped_into 'web_user' }
      it { should be_mode 500 }
    end
  end

  describe file '/home/web_user/sites/formalign/scripts/utilities/commandfileutils.py' do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'web_user' }
    it { should be_grouped_into 'web_user' }
    it { should be_mode 400 }
  end

  # Scripts dependencies should be present
  describe package('python3-pip') do
    it { should be_installed }
  end

  describe command ('pip3 list | grep psutil') do
    its(:stdout) { should match(/psutil\s+\(\d+\.\d+\.\d+\)/)}
  end

  # Config file for for installation scripts should be present
  describe file('/home/web_user/sites/formalign/scripts/conf.py') do
    params = [
        %r(^DIST_VERSION = '#{os[:release]}'$),
        %r(^DEBUG = 'DEBUG'$),
        %r(^NGINX_CONF = ''$),
        %r(^APP_HOME = ''$),
        %r(^APP_HOME_TMP = '/home/web_user/sites/formalign/source'$),
        %r(^APP_USER = ''$),
        %r(^WEB_USER = 'web_user'$),
        %r(^WEBSERVER_USER = 'www-data'$),
        %r(^GIT_REPO = 'https://github\.com/globz-eu/formalign\.git'$),
        %r(^STATIC_PATH = '/home/web_user/sites/formalign/static'$),
        %r(^MEDIA_PATH = '/home/web_user/sites/formalign/media'$),
        %r(^UWSGI_PATH = '/home/web_user/sites/formalign/uwsgi'$),
        %r(^VENV = ''$),
        %r(^REQS_FILE = ''$),
        %r(^SYS_DEPS_FILE = ''$),
        %r(^LOG_FILE = '/var/log/formalign/serve_static\.log'$)
    ]
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'web_user' }
    it { should be_grouped_into 'web_user' }
    it { should be_mode 400 }
    params.each do |p|
      its(:content) { should match(p)}
    end
  end

  # Static files should be present
  describe file('/home/web_user/sites/formalign/static/css') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'web_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 550 }
  end

  describe file('/home/web_user/sites/formalign/static/bootstrap/css/bootstrap.css') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'web_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 440 }
  end

  describe file('/home/web_user/sites/formalign/media/media.txt') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'web_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 440 }
  end

  describe file('/home/web_user/sites/formalign/uwsgi/uwsgi_params') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'web_user' }
    it { should be_grouped_into 'www-data' }
    it { should be_mode 440 }
  end

  # App log directory should be present
  describe file('/var/log/formalign') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 755 }
  end

  describe file('/etc/nginx/sites-enabled/default') do
    it { should_not exist }
  end
end
