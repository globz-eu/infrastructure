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
# Cookbook Name:: web_server
# Spec:: nginx

require 'spec_helper'

def app(version, https: false, www: false)
  if version == '14.04'
    ip_end = '84'
    ip = '192.168.1.84'
  elsif version == '16.04'
    ip_end = '85'
    ip = '192.168.1.85'
  end

  if https
    listen_port = '443'
    port_regex = [/^\s+listen\s+443 ssl;$/]
  else
    listen_port = '80'
    port_regex = [/^\s+listen\s+80;$/]
  end

  if www
    server_name = [/^\s+server_name\s+192\.168\.1\.#{ip_end}\s+www.192\.168\.1\.#{ip_end};$/]
  else
    server_name = [/^\s+server_name\s+192\.168\.1\.#{ip_end};$/]
  end

  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  it 'includes chef-vault and firewall recipes' do
    recipes = %w(chef-vault basic_node::firewall django_app_server::python)
    recipes.each do |r|
      expect(chef_run).to include_recipe(r)
    end
  end

  it 'creates the /home/web_user/.envs directory' do
    expect(chef_run).to create_directory('/home/web_user/.envs').with(
        owner: 'web_user',
        group: 'web_user',
        mode: '0700',
    )
  end

  it 'installs the nginx package' do
    expect(chef_run).to install_package( 'nginx' )
  end

  it 'does not start nginx service until notified' do
    expect(chef_run).to_not start_service( 'nginx' )
  end

  it 'creates firewall rules' do
    if https
      %w(http https).each do |r|
        expect(chef_run).to create_firewall_rule(r)
      end
    else
      expect(chef_run).to create_firewall_rule('http')
      expect(chef_run).to_not create_firewall_rule('https')
    end
  end

  it 'creates or updates django_base.conf file' do
    params = [
        /^# django_base.conf$/,
        %r(^\s+server unix:///home/app_user/sites/django_base/sockets/django_base\.sock; # for a file socket$),
        /^\s+# server 127\.0\.0\.1:8001; # for a web port socket/,
        %r(^\s+alias /home/web_user/sites/django_base/media;),
        %r(^\s+alias /home/web_user/sites/django_base/static;),
        %r(^\s+include\s+/home/web_user/sites/django_base/uwsgi/uwsgi_params;$)
    ]
    params += port_regex
    params += server_name
    if https
      source_file = 'app_name_https.conf.erb'
    else
      source_file = 'app_name.conf.erb'
    end
    expect(chef_run).to create_template('/etc/nginx/sites-available/django_base.conf').with({
        owner: 'root',
        group: 'root',
        mode: '0400',
        source: source_file,
        variables: {
            app_name: 'django_base',
            server_unix_socket: 'server unix:///home/app_user/sites/django_base/sockets/django_base.sock;',
            server_tcp_socket: '# server 127.0.0.1:8001;',
            listen_port: listen_port,
            server_name: ip,
            static_path: '/home/web_user/sites/django_base/static',
            media_path: '/home/web_user/sites/django_base/media',
            uwsgi_path: '/home/web_user/sites/django_base/uwsgi'
        }
    })
    params.each do |p|
      expect(chef_run).to render_file('/etc/nginx/sites-available/django_base.conf').with_content(p)
    end
  end

  it 'installs the git package' do
    expect( chef_run ).to install_package('git')
  end

  it 'creates the site file structure' do
    sites_paths = ['static', 'media', 'uwsgi', 'down']
    sites_paths.each do |s|
      expect(chef_run).to create_directory("/home/web_user/sites/django_base/#{s}").with(
          owner: 'web_user',
          group: 'www-data',
          mode: '0550',
      )
    end
  end

  it 'creates the /home/web_user/sites/django_base/conf.d directory' do
    expect(chef_run).to create_directory('/home/web_user/sites/django_base/conf.d').with(
        owner: 'web_user',
        group: 'web_user',
        mode: '0750',
    )
  end

  it 'creates the /home/web_user/sites/django_base/scripts/conf.py file' do
    expect(chef_run).to create_template('/home/web_user/sites/django_base/scripts/conf.py').with(
        owner: 'web_user',
        group: 'web_user',
        mode: '0400',
        source: 'conf.py.erb',
        variables: {
            dist_version: version,
            log_level: 'DEBUG',
            nginx_conf: '',
            git_repo: 'https://github.com/globz-eu/django_base.git',
            app_home: '',
            app_home_tmp: '/home/web_user/sites/django_base/source',
            app_user: '',
            web_user: 'web_user',
            webserver_user: 'www-data',
            static_path: '/home/web_user/sites/django_base/static',
            media_path: '/home/web_user/sites/django_base/media',
            uwsgi_path: '/home/web_user/sites/django_base/uwsgi',
            down_path: '/home/web_user/sites/django_base/down',
            venv: '/home/web_user/.envs/django_base',
            log_file: '/var/log/django_base/serve_static.log',
            fifo_dir: ''
        }
    )
    install_app_conf = [
        %r(^DIST_VERSION = '#{version}'$),
        %r(^LOG_LEVEL = 'DEBUG'$),
        %r(^NGINX_CONF = ''$),
        %r(^APP_HOME_TMP = '/home/web_user/sites/django_base/source'$),
        %r(^APP_HOME = ''$),
        %r(^APP_USER = ''$),
        %r(^WEB_USER = 'web_user'$),
        %r(^WEBSERVER_USER = 'www-data'$),
        %r(^GIT_REPO = 'https://github\.com/globz-eu/django_base\.git'$),
        %r(^STATIC_PATH = '/home/web_user/sites/django_base/static'$),
        %r(^MEDIA_PATH = '/home/web_user/sites/django_base/media'$),
        %r(^UWSGI_PATH = '/home/web_user/sites/django_base/uwsgi'$),
        %r(^DOWN_PATH = '/home/web_user/sites/django_base/down'$),
        %r(^VENV = '/home/web_user/\.envs/django_base'$),
        %r(^REQS_FILE = ''$),
        %r(^SYS_DEPS_FILE = ''$),
        %r(^LOG_FILE = '/var/log/django_base/serve_static\.log'$),
        %r(^FIFO_DIR = ''$)
    ]
    install_app_conf.each do |u|
      expect(chef_run).to render_file(
                              '/home/web_user/sites/django_base/scripts/conf.py'
                          ).with_content(u)
    end
  end

  it 'creates the /home/web_user/sites/django_base/conf.d/settings.json file' do
    expect(chef_run).to create_template('/home/web_user/sites/django_base/conf.d/settings.json').with(
      owner: 'web_user',
      group: 'web_user',
      mode: '0400',
      source: 'settings.json.erb',
      variables: {
        secret_key: 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!',
        allowed_host: '',
        db_engine: '',
        db_name: '',
        db_user: '',
        db_password: '',
        db_admin_user: '',
        db_admin_password: '',
        db_host: '',
        test_db_name: '',
        broker_url: '',
        celery_result_backend: ''
      }
    )
    config = [
        %r(^\s+"SECRET_KEY": "n\)#o5pw7kelvr982iol48tz--n#q!\*8681k3sv0\^\*q#-lddwv!",$),
        %r(^\s+"DEBUG": false,$),
        %r(^\s+"ALLOWED_HOSTS": \[""\],$),
        %r(^\s+"DB_ENGINE": "",$),
        %r(^\s+"DB_NAME": "",$),
        %r(^\s+"DB_USER": "",$),
        %r(^\s+"DB_PASSWORD": "",$),
        %r(^\s+"DB_ADMIN_USER": "",$),
        %r(^\s+"DB_ADMIN_PASSWORD": "",$),
        %r(^\s+"DB_HOST": "",$),
        %r(^\s+"TEST_DB_NAME": "",$),
        %r(^\s+"BROKER_URL": "",$),
        %r(^\s+"CELERY_RESULT_BACKEND": "",$),
        %r(^\s+"SECURE_SSL_REDIRECT": false,$),
        %r(^\s+"SECURE_PROXY_SSL_HEADER": \[\],$),
        %r(^\s+"CHROME_DRIVER": "",$),
        %r(^\s+"FIREFOX_BINARY": "",$),
        %r(^\s+"SERVER_URL": "",$),
        %r(^\s+"HEROKU": false$),
    ]
    config.each do |u|
      expect(chef_run).to render_file('/home/web_user/sites/django_base/conf.d/settings.json').with_content(u)
    end
  end

  it 'runs the create_venv script' do
    expect(chef_run).to run_bash('create_venv').with(
        cwd: '/home/web_user/sites/django_base/scripts',
        code: './djangoapp.py -e',
        user: 'web_user'
    )
  end

  it 'runs the serve_static script' do
    expect(chef_run).to run_bash('serve_static').with(
        cwd: '/home/web_user/sites/django_base/scripts',
        code: './webserver.py -m',
        user: 'root'
    )
  end

  it 'creates the server down index page' do
    params = [
        %r(^\s+<h1>django_base is down for maintenance\. Please come back later\.</h1>$)
    ]
    expect(chef_run).to_not create_template('/home/web_user/sites/django_base/down/index.html').with(
        owner: 'web_user',
        group: 'www-data',
        mode: '0440',
        source: 'index_down.html.erb',
        variables: {
            app_name: 'django_base'
        }
    )
    params.each do |p|
      expect(chef_run).to_not render_file('/home/web_user/sites/django_base/down/index.html').with_content(p)
    end
  end

  it 'creates or updates django_base_down.conf file' do
    params = [
        /^# django_base_down.conf$/,
        %r(^\s+index index\.html;$),
        %r(^\s+root /home/web_user/sites/django_base/down;),
        %r(^\s+alias /home/web_user/sites/django_base/media;),
        %r(^\s+alias /home/web_user/sites/django_base/static;),
    ]
    params += port_regex
    params += server_name

    if https
      source_file = 'app_name_down_https.conf.erb'
    else
      source_file = 'app_name_down.conf.erb'
    end
    expect(chef_run).to create_template('/etc/nginx/sites-available/django_base_down.conf').with({
         owner: 'root',
         group: 'root',
         mode: '0400',
         source: source_file,
         variables: {
             app_name: 'django_base',
             listen_port: listen_port,
             server_name: ip,
             down_path: '/home/web_user/sites/django_base/down',
             static_path: '/home/web_user/sites/django_base/static',
             media_path: '/home/web_user/sites/django_base/media',
         }
     })
    params.each do |p|
      expect(chef_run).to render_file('/etc/nginx/sites-available/django_base_down.conf').with_content(p)
    end
  end

  it 'disables the default site' do
    expect(chef_run).to delete_file('/etc/nginx/sites-enabled/default')
  end

  it 'enables the server down site' do
    expect(chef_run).to create_link('/etc/nginx/sites-enabled/django_base_down.conf').with(
        owner: 'root',
        group: 'root',
        to: '/etc/nginx/sites-available/django_base_down.conf'
    )
  end

  it 'notifies nginx to restart' do
    site_down_enabled = chef_run.link('/etc/nginx/sites-enabled/django_base_down.conf')
    expect(site_down_enabled).to notify('service[nginx]').to(:restart).immediately
  end
end

describe 'web_server::nginx' do
  %w(14.04 16.04).each do |version|
    context "When git repo is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['web_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          if version == '14.04'
            node.set['web_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['web_server']['node_number'] = '001'
          end
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/web_user/sites/django_base/down/index.html').and_return(true)
        stub_command('pip list | grep virtualenv').and_return(false)
      end

      app(version)

    end
  end
end

describe 'web_server::nginx' do
  %w(14.04 16.04).each do |version|
    context "When git repo is specified and https and www are true, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['web_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['web_server']['nginx']['https'] = true
          node.set['web_server']['nginx']['www'] = true
          if version == '14.04'
            node.set['web_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['web_server']['node_number'] = '001'
          end
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/web_user/sites/django_base/down/index.html').and_return(true)
        stub_command('pip list | grep virtualenv').and_return(false)
      end

      app(version, https: true, www: true)

      it 'creates the ssl directory' do
        expect(chef_run).to create_directory('/etc/nginx/ssl').with(
                                                                  owner: 'root',
                                                                  group: 'www-data',
                                                                  mode: '0550'
        )
      end

      it 'creates the certificate file' do
        expect(chef_run).to create_template('/etc/nginx/ssl/server.crt').with(
                owner: 'root',
                group: 'www-data',
                mode: '0640',
                source: 'server.crt.erb',
                variables: {
                    server_crt: '-----BEGIN CERTIFICATE-----
MIIDeTCCAmGgAwIBAgIJAIfZ6tbDllOqMA0GCSqGSIb3DQEBCwUAMFMxCzAJBgNV
BAYTAkRFMQwwCgYDVQQIDANOUlcxEDAOBgNVBAcMB0vDg8K2bG4xDTALBgNVBAoM
BGNvbXAxFTATBgNVBAMMDDE5Mi4xNjguMS44NTAeFw0xNjEwMTMxMTI3NDBaFw0x
NzEwMTMxMTI3NDBaMFMxCzAJBgNVBAYTAkRFMQwwCgYDVQQIDANOUlcxEDAOBgNV
BAcMB0vDg8K2bG4xDTALBgNVBAoMBGNvbXAxFTATBgNVBAMMDDE5Mi4xNjguMS44
NTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL5nq0uyGluYyGDf4UwV
1v7pUXgc4kS53wXKeGRXTMZwl3qw+9OzLa6OUT6GzZ1NXM9ooThr5GJz6WkNVga5
GPNcPZaiWoXDGf5QvnkIzLyAUHPCJeW7rLsT5BhScEY6C30j6zbtWBo3RFlsaImq
J4VHDDcQQVyZ7AeGjV999YGE68/EGP1mypMkzTOAFUgn27XgD4UYvMON5CUxH+jI
aJtxD2M/ArNHq4HxglioOcFJAGUho0kPPS177LY1FT/PbPw8xDjm/Fl7mJlA9VPD
93KzN2FDF6NKe1zaju/NWlD4uB3AN4Pm+MgpTG9lkMEgczDiv+hOfvhd/M7+bWoG
LQ8CAwEAAaNQME4wHQYDVR0OBBYEFH7lcxFrkiXis2w9v9P13Da1AAR4MB8GA1Ud
IwQYMBaAFH7lcxFrkiXis2w9v9P13Da1AAR4MAwGA1UdEwQFMAMBAf8wDQYJKoZI
hvcNAQELBQADggEBAIkmQL/275kTQp5Seg3Gps8M7pdzOKVIt4raOBieWMSi7GfN
t7fuinvHyKlR6sY+GTWhZWOmGCTh04EivjfDSSFK8ykV3F8lRrldmMXmzoYMuPhd
MvTYOmuHtyTBRxU0DHMjXe2Sni5RAH6QHOjW7KrnWqfDyOxM34o5zEGcmqUWMP6E
LhBoVKHR5QCmLraQSMI/VtG9+P/Qe6UdkUXD/3ETo/+0BvtB3KVOmEl3VeVJhqJw
XRahbovwyL7vi+tY7Qzq+zqQNEe6YbUlEo1iz3BZlYO6YuETjJhpKqzeNrVnPtba
vbr1DeQa+11K7lCzww5gXdpSdZ4ozRECcuBcnGU=
-----END CERTIFICATE-----'
                }
        )
        expect(chef_run).to render_file('/etc/nginx/ssl/server.crt').with_content(%r(^-----BEGIN CERTIFICATE-----
MIIDeTCCAmGgAwIBAgIJAIfZ6tbDllOqMA0GCSqGSIb3DQEBCwUAMFMxCzAJBgNV
BAYTAkRFMQwwCgYDVQQIDANOUlcxEDAOBgNVBAcMB0vDg8K2bG4xDTALBgNVBAoM
BGNvbXAxFTATBgNVBAMMDDE5Mi4xNjguMS44NTAeFw0xNjEwMTMxMTI3NDBaFw0x
NzEwMTMxMTI3NDBaMFMxCzAJBgNVBAYTAkRFMQwwCgYDVQQIDANOUlcxEDAOBgNV
BAcMB0vDg8K2bG4xDTALBgNVBAoMBGNvbXAxFTATBgNVBAMMDDE5Mi4xNjguMS44
NTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL5nq0uyGluYyGDf4UwV
1v7pUXgc4kS53wXKeGRXTMZwl3qw\+9OzLa6OUT6GzZ1NXM9ooThr5GJz6WkNVga5
GPNcPZaiWoXDGf5QvnkIzLyAUHPCJeW7rLsT5BhScEY6C30j6zbtWBo3RFlsaImq
J4VHDDcQQVyZ7AeGjV999YGE68/EGP1mypMkzTOAFUgn27XgD4UYvMON5CUxH\+jI
aJtxD2M/ArNHq4HxglioOcFJAGUho0kPPS177LY1FT/PbPw8xDjm/Fl7mJlA9VPD
93KzN2FDF6NKe1zaju/NWlD4uB3AN4Pm\+MgpTG9lkMEgczDiv\+hOfvhd/M7\+bWoG
LQ8CAwEAAaNQME4wHQYDVR0OBBYEFH7lcxFrkiXis2w9v9P13Da1AAR4MB8GA1Ud
IwQYMBaAFH7lcxFrkiXis2w9v9P13Da1AAR4MAwGA1UdEwQFMAMBAf8wDQYJKoZI
hvcNAQELBQADggEBAIkmQL/275kTQp5Seg3Gps8M7pdzOKVIt4raOBieWMSi7GfN
t7fuinvHyKlR6sY\+GTWhZWOmGCTh04EivjfDSSFK8ykV3F8lRrldmMXmzoYMuPhd
MvTYOmuHtyTBRxU0DHMjXe2Sni5RAH6QHOjW7KrnWqfDyOxM34o5zEGcmqUWMP6E
LhBoVKHR5QCmLraQSMI/VtG9\+P/Qe6UdkUXD/3ETo/\+0BvtB3KVOmEl3VeVJhqJw
XRahbovwyL7vi\+tY7Qzq\+zqQNEe6YbUlEo1iz3BZlYO6YuETjJhpKqzeNrVnPtba
vbr1DeQa\+11K7lCzww5gXdpSdZ4ozRECcuBcnGU=
-----END CERTIFICATE-----$))
        end

      it 'creates the key file' do
        expect(chef_run).to create_template('/etc/nginx/ssl/server.key').with(
            owner: 'root',
            group: 'www-data',
            mode: '0640',
            source: 'server.key.erb',
            variables: {
                server_key: '-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQC+Z6tLshpbmMhg
3+FMFdb+6VF4HOJEud8FynhkV0zGcJd6sPvTsy2ujlE+hs2dTVzPaKE4a+Ric+lp
DVYGuRjzXD2WolqFwxn+UL55CMy8gFBzwiXlu6y7E+QYUnBGOgt9I+s27VgaN0RZ
bGiJqieFRww3EEFcmewHho1fffWBhOvPxBj9ZsqTJM0zgBVIJ9u14A+FGLzDjeQl
MR/oyGibcQ9jPwKzR6uB8YJYqDnBSQBlIaNJDz0te+y2NRU/z2z8PMQ45vxZe5iZ
QPVTw/dyszdhQxejSntc2o7vzVpQ+LgdwDeD5vjIKUxvZZDBIHMw4r/oTn74XfzO
/m1qBi0PAgMBAAECggEBAJuqjfUY60uvoULyRnO590f44M5ebu7ZN2i4m60NYotq
Sa3ZPElb2CE54VpJQ5kzQomfdQ93xgRn15A3gvmEIs3zv7aDjZaGZ53vzYmOlDQY
g63gMLOduB5KqNTpsTj5A6OP1iHV8Y2dWZfydZT3M9BWwbnS5F0cykdszfAgPrNf
2pstooNAL7jhbHWHeAiedAG3P22jHApmz/EEEOb2B4kI7c5rPPvX2uXBK7xFk0ZK
SGDRZh0RQIlOxJKwS9t47qH/OI6V+8cU8xH8Ap6Vt+72MpcMinR/sjKVtuKfpqOz
32jQ6tCkDE/TTtrFHqpeMxtP+mwaobb3cJoU0zAMKkECgYEA7cmIiKA0N4d8jDv3
4i1JS2vzsBHNvckFTir26Oc6LAu3Hg6pQVYk7hzOYKnMbIA0b8uTcSWzx67kf41B
zwp02TLvNwlzr8rCVoPfAQR0tePKlQag6zNEaMLh5U9ked537WgDyBl6/1SS36VF
2W0D1aKNQOXhddVn5X26Z7YiGMkCgYEAzP0Tui0Pxu2vTK/1myrQ0cOq96uLn5rA
azTcnbxRwWkjRbYWYRpf9dfTXyh/ax3jb20mk+uhfs8JHMUC8+VUac2h5d+qmMT/
RdWhdZZiUUPFU+A1a90ytFno3pBrlaXEfUkVw79vhk3/M3um2PLFsFXh9Upz2Y9l
IbASU3ay2xcCgYEA6WpHSDZai5fHvrCvJ6pkpFCXqWIQoBfPyWeLcBxqkgn9+tdR
df1lywcj3udO78L5tjQTy6HC1GTtj/fNfbs58Gt7Pn9cvFdAZUSVh54kItg0aA1V
sQtmP5/ttvc0Hh0vhC/yZl38yt7uPfMymbfVZ8Rk/CusIcsWbcP5Uw0Kc2ECgYBz
0TloIzWay4gT6Ab4mIRLQCZEsOO+VY0KBV/wrwnyIRkQtgSG8IPvPvXp+dOkDcsG
lcEKKkOghhE79APrEVNURB6I5opYrlUce8sxyLnb+FJxRWhpfRy80V/FAAwJDROr
RbPKWUsFsuPRjreCNAiFzMBR+rLh5SbalcSE67e6GQKBgQCkJbn5236qHJRB7jrG
7GVfhQbPZ7NCGpfIBYSL2MjtsesItDVTrR3cLZxXmcYPWxoIBUXMnkMPG4s3WUnj
EKV92GGnJyYKPUjcjUNTLytn0Dn5kAtWHUD6ew+ohtfeWtyydMJkRdzH71O1z/4p
ceMkZ96kunsVNfj3/JAjC7F6LQ==
-----END PRIVATE KEY-----'
            }
        )
        expect(chef_run).to render_file('/etc/nginx/ssl/server.key').with_content(%r(^-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQC\+Z6tLshpbmMhg
3\+FMFdb\+6VF4HOJEud8FynhkV0zGcJd6sPvTsy2ujlE\+hs2dTVzPaKE4a\+Ric\+lp
DVYGuRjzXD2WolqFwxn\+UL55CMy8gFBzwiXlu6y7E\+QYUnBGOgt9I\+s27VgaN0RZ
bGiJqieFRww3EEFcmewHho1fffWBhOvPxBj9ZsqTJM0zgBVIJ9u14A\+FGLzDjeQl
MR/oyGibcQ9jPwKzR6uB8YJYqDnBSQBlIaNJDz0te\+y2NRU/z2z8PMQ45vxZe5iZ
QPVTw/dyszdhQxejSntc2o7vzVpQ\+LgdwDeD5vjIKUxvZZDBIHMw4r/oTn74XfzO
/m1qBi0PAgMBAAECggEBAJuqjfUY60uvoULyRnO590f44M5ebu7ZN2i4m60NYotq
Sa3ZPElb2CE54VpJQ5kzQomfdQ93xgRn15A3gvmEIs3zv7aDjZaGZ53vzYmOlDQY
g63gMLOduB5KqNTpsTj5A6OP1iHV8Y2dWZfydZT3M9BWwbnS5F0cykdszfAgPrNf
2pstooNAL7jhbHWHeAiedAG3P22jHApmz/EEEOb2B4kI7c5rPPvX2uXBK7xFk0ZK
SGDRZh0RQIlOxJKwS9t47qH/OI6V\+8cU8xH8Ap6Vt\+72MpcMinR/sjKVtuKfpqOz
32jQ6tCkDE/TTtrFHqpeMxtP\+mwaobb3cJoU0zAMKkECgYEA7cmIiKA0N4d8jDv3
4i1JS2vzsBHNvckFTir26Oc6LAu3Hg6pQVYk7hzOYKnMbIA0b8uTcSWzx67kf41B
zwp02TLvNwlzr8rCVoPfAQR0tePKlQag6zNEaMLh5U9ked537WgDyBl6/1SS36VF
2W0D1aKNQOXhddVn5X26Z7YiGMkCgYEAzP0Tui0Pxu2vTK/1myrQ0cOq96uLn5rA
azTcnbxRwWkjRbYWYRpf9dfTXyh/ax3jb20mk\+uhfs8JHMUC8\+VUac2h5d\+qmMT/
RdWhdZZiUUPFU\+A1a90ytFno3pBrlaXEfUkVw79vhk3/M3um2PLFsFXh9Upz2Y9l
IbASU3ay2xcCgYEA6WpHSDZai5fHvrCvJ6pkpFCXqWIQoBfPyWeLcBxqkgn9\+tdR
df1lywcj3udO78L5tjQTy6HC1GTtj/fNfbs58Gt7Pn9cvFdAZUSVh54kItg0aA1V
sQtmP5/ttvc0Hh0vhC/yZl38yt7uPfMymbfVZ8Rk/CusIcsWbcP5Uw0Kc2ECgYBz
0TloIzWay4gT6Ab4mIRLQCZEsOO\+VY0KBV/wrwnyIRkQtgSG8IPvPvXp\+dOkDcsG
lcEKKkOghhE79APrEVNURB6I5opYrlUce8sxyLnb\+FJxRWhpfRy80V/FAAwJDROr
RbPKWUsFsuPRjreCNAiFzMBR\+rLh5SbalcSE67e6GQKBgQCkJbn5236qHJRB7jrG
7GVfhQbPZ7NCGpfIBYSL2MjtsesItDVTrR3cLZxXmcYPWxoIBUXMnkMPG4s3WUnj
EKV92GGnJyYKPUjcjUNTLytn0Dn5kAtWHUD6ew\+ohtfeWtyydMJkRdzH71O1z/4p
ceMkZ96kunsVNfj3/JAjC7F6LQ==
-----END PRIVATE KEY-----$))
      end
    end
  end
end
