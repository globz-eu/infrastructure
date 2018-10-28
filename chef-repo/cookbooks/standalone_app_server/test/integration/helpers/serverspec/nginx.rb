# Cookbook:: web_server
# Server Spec:: nginx


require 'serverspec'

set :backend, :exec

def nginx_spec(app_name, ips, https, www: false, site_down: true)
  if os[:family] == 'ubuntu'
    ip_regex = Regexp.escape(ips[os[:release]])
    if www
      server_name = /^\s+server_name\s+#{ip_regex}\s+www\.#{ip_regex};$/
    else
      server_name = /^\s+server_name\s+#{ip_regex};$/
    end

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
      https_rules = [
          %r{^\[(\s|\d)\d\]\s+443/tcp\s+ALLOW IN\s+Anywhere\s*$},
          %r{^\[(\s|\d)\d\]\s+443/tcp\s+\(v6\)\s+ALLOW IN\s+Anywhere\s+\(v6\)\s*$}
      ]
      if https
        expected_rules += https_rules
      end
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

    # installs a python runtime
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

    describe file("/etc/nginx/sites-available/#{app_name}.conf") do
      params = [
          /^# #{app_name}.conf$/,
          %r(^\s+server unix:///home/app_user/sites/#{app_name}/sockets/#{app_name}\.sock; # for a file socket$),
          /^\s+# server 127\.0\.0\.1:8001; # for a web port socket/,
          /^\s+listen\s+80;$/,
          server_name,
          %r(^\s+alias /home/web_user/sites/#{app_name}/media;),
          %r(^\s+alias /home/web_user/sites/#{app_name}/static;),
          %r(^\s+include\s+/home/web_user/sites/#{app_name}/uwsgi/uwsgi_params;$)
      ]
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      it { should be_mode 400 }
      params.each do |p|
        its(:content) { should match(p) }
      end
    end

    site_down_conf = %W(/etc/nginx/sites-available/#{app_name}_down.conf
    /etc/nginx/sites-enabled/#{app_name}_down.conf)
    site_down_conf.each() do |f|
      describe file(f) do
        params = [
            /^# #{app_name}_down.conf$/,
            %r(^\s+index index.html;$),
            /^\s+listen\s+80;$/,
            server_name,
            %r(^\s+root /home/web_user/sites/#{app_name}/down;)
        ]
        if f == "/etc/nginx/sites-available/#{app_name}_down.conf"
          it { should exist }
          it { should be_file }
          it { should be_mode 400 }
          it { should be_owned_by 'root' }
          it { should be_grouped_into 'root' }
          params.each do |p|
            its(:content) { should match(p) }
          end
        elsif f == "/etc/nginx/sites-enabled/#{app_name}_down.conf"
          if site_down
            it { should exist }
          else
            it { should_not exist }
          end
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

    describe file("/home/web_user/sites/#{app_name}") do
      it {should exist}
      it {should be_directory}
      it {should be_owned_by 'web_user'}
      it {should be_grouped_into 'www-data'}
      it {should be_mode 550}
    end

    site_paths = %w(static media uwsgi down)
    site_paths.each do |s|
      describe file("/home/web_user/sites/#{app_name}/#{s}") do
        it {should exist}
        it {should be_directory}
        it {should be_owned_by 'web_user'}
        it {should be_grouped_into 'www-data'}
        it {should be_mode 550}
      end
    end

    describe file("/home/web_user/sites/#{app_name}/down/index.html") do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'web_user' }
      it { should be_grouped_into 'www-data' }
      it { should be_mode 440 }
      its(:content) { should match(%r(^\s+<title id="head-title">#{app_name}(\.eu|\.org){0,1} site down</title>$)i) }
    end

    # Install scripts should be present
    describe file("/home/web_user/sites/#{app_name}/scripts") do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by 'web_user' }
      it { should be_grouped_into 'web_user' }
      it { should be_mode 500 }
    end

    scripts = ['webserver.py', 'djangoapp.py']
    scripts.each do |s|
      describe file "/home/web_user/sites/#{app_name}/scripts/#{s}" do
        it { should exist }
        it { should be_file }
        it { should be_owned_by 'web_user' }
        it { should be_grouped_into 'web_user' }
        it { should be_mode 500 }
      end
    end

    describe file "/home/web_user/sites/#{app_name}/scripts/utilities/commandfileutils.py" do
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
    describe file("/home/web_user/sites/#{app_name}/scripts/conf.py") do
      params = [
          %r(^DIST_VERSION = '#{os[:release]}'$),
          %r(^LOG_LEVEL = 'DEBUG'$),
          %r(^NGINX_CONF = ''$),
          %r(^APP_HOME = ''$),
          %r(^APP_HOME_TMP = '/home/web_user/sites/#{app_name}/source'$),
          %r(^APP_USER = ''$),
          %r(^WEB_USER = 'web_user'$),
          %r(^WEBSERVER_USER = 'www-data'$),
          %r(^GIT_REPO = 'https://github\.com/globz-eu/#{app_name}\.git'$),
          %r(^STATIC_PATH = '/home/web_user/sites/#{app_name}/static'$),
          %r(^MEDIA_PATH = '/home/web_user/sites/#{app_name}/media'$),
          %r(^UWSGI_PATH = '/home/web_user/sites/#{app_name}/uwsgi'$),
          %r(^VENV = '/home/web_user/.envs/#{app_name}'$),
          %r(^REQS_FILE = ''$),
          %r(^SYS_DEPS_FILE = ''$),
          %r(^LOG_FILE = '/var/log/#{app_name}/serve_static\.log'$),
          %r(^FIFO_DIR = ''$)
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

    # settings.json file should be present
    describe file("/home/web_user/sites/#{app_name}/conf.d") do
      it {should exist}
      it {should be_directory}
      it {should be_owned_by 'web_user'}
      it {should be_grouped_into 'web_user'}
      it {should be_mode 750}
    end

    describe file("/home/web_user/sites/#{app_name}/conf.d/settings.json") do
      params = [
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
    describe file("/home/web_user/sites/#{app_name}/static/bootstrap") do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by 'web_user' }
      it { should be_grouped_into 'www-data' }
      it { should be_mode 550 }
    end

    describe file("/home/web_user/sites/#{app_name}/static/bootstrap/css/bootstrap.css") do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'web_user' }
      it { should be_grouped_into 'www-data' }
      it { should be_mode 440 }
    end

    describe file("/home/web_user/sites/#{app_name}/media/media.txt") do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'web_user' }
      it { should be_grouped_into 'www-data' }
      it { should be_mode 440 }
    end

    describe file("/home/web_user/sites/#{app_name}/uwsgi/uwsgi_params") do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'web_user' }
      it { should be_grouped_into 'www-data' }
      it { should be_mode 440 }
    end

    # App log directory should be present
    describe file("/var/log/#{app_name}") do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'loggers' }
      it { should be_mode 775 }
    end

    describe file('/etc/nginx/sites-enabled/default') do
      it { should_not exist }
    end
  end
end
