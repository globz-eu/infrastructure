# Cookbook:: standalone_app_server
# Spec:: start_app

require 'spec_helper'

def common
  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  it 'includes the chef-vault recipe' do
    expect(chef_run).to include_recipe('chef-vault')
  end

  # manages migrations, runs app tests and starts celery and uwsgi
  it 'creates test log file structure' do
    expect(chef_run).to create_directory('/var/log/django_base/test_results').with({
         owner: 'root',
         group: 'root',
         mode: '0700'
     })
  end

  it "updates app_user's app venv pip" do
    expect(chef_run).to run_bash('update_app_user_pip').with({
        code: '/home/app_user/.envs/django_base/bin/pip install --upgrade pip',
        user: 'app_user'
    })
  end

  it "updates web_user's app venv pip" do
    expect(chef_run).to run_bash('update_web_user_pip').with({
        code: '/home/web_user/.envs/django_base/bin/pip install --upgrade pip',
        user: 'web_user'
    })
  end

  it 'migrates the database and test the app' do
    expect(chef_run).to run_bash('migrate_and_test').with({
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -mt',
        user: 'root'
    })
  end

  it 'starts uwsgi' do
    expect(chef_run).to run_bash('start_uwsgi').with({
         cwd: '/home/app_user/sites/django_base/scripts',
         code: './djangoapp.py -u start',
         user: 'root'
     })
  end

  it 'runs init_users.py' do
    expect(chef_run).to run_bash('init_users').with({
         cwd: '/home/app_user/sites/django_base/source/django_base',
         code: '/home/app_user/.envs/django_base/bin/python ./initialize/init_users.py',
         user: 'root'
     })
  end

  it 'runs init_data.py' do
    expect(chef_run).to run_bash('init_data').with({
         cwd: '/home/app_user/sites/django_base/source/django_base',
         code: '/home/app_user/.envs/django_base/bin/python ./initialize/init_data.py',
         user: 'root'
     })
  end

  it 'restarts uwsgi' do
    expect(chef_run).to run_bash('restart_uwsgi').with({
         cwd: '/home/app_user/sites/django_base/scripts',
         code: './djangoapp.py -u restart',
         user: 'root'
     })
  end

  it 'runs server_up' do
    expect( chef_run ).to run_bash('server_up').with(
        cwd: '/home/web_user/sites/django_base/scripts',
        code: './webserver.py -s up',
        user: 'root'
    )
  end
end

describe 'standalone_app_server::start_app' do
  %w(14.04 16.04).each do |version|
    context "When app name is specified and celery is default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['standalone_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          if version == '14.04'
            node.set['standalone_app_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['standalone_app_server']['node_number'] = '001'
          end
        end.converge('web_server::nginx', described_recipe)
      end

      before do
        stub_command('pip list | grep virtualenv').and_return(false)
        stub_command('ls /home/web_user/sites/django_base/down/index.html').and_return(false)
        stub_command('ls /home/app_user/sites/django_base/source/django_base/initialize/init_data.py').and_return(true)
        stub_command('ls /home/app_user/sites/django_base/source/django_base/initialize/init_users.py').and_return(true)
      end

      common

      it 'does not start celery and beat' do
        expect(chef_run).to_not run_bash('start_celery').with({
                  cwd: '/home/app_user/sites/django_base/scripts',
                  code: './djangoapp.py -c start',
                  user: 'root'
              })
      end

      it 'does not restart celery and beat' do
        expect(chef_run).to_not run_bash('restart_celery').with({
            cwd: '/home/app_user/sites/django_base/scripts',
            code: './djangoapp.py -c restart',
            user: 'root'
        })
      end
    end
  end
end

describe 'standalone_app_server::start_app' do
  %w(14.04 16.04).each do |version|
    context "When app name is specified and celery is true, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['standalone_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['standalone_app_server']['start_app']['celery'] = true
          if version == '14.04'
            node.set['standalone_app_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['standalone_app_server']['node_number'] = '001'
          end
        end.converge('web_server::nginx', described_recipe)
      end

      before do
        stub_command('pip list | grep virtualenv').and_return(false)
        stub_command('ls /home/web_user/sites/django_base/down/index.html').and_return(false)
        stub_command('ls /home/app_user/sites/django_base/source/django_base/initialize/init_data.py').and_return(true)
        stub_command('ls /home/app_user/sites/django_base/source/django_base/initialize/init_users.py').and_return(true)
      end

      common

      it 'starts celery and beat' do
        expect(chef_run).to run_bash('start_celery').with({
                  cwd: '/home/app_user/sites/django_base/scripts',
                  code: './djangoapp.py -c start',
                  user: 'root'
              })
      end

      it 'restarts celery and beat' do
        expect(chef_run).to run_bash('restart_celery').with({
            cwd: '/home/app_user/sites/django_base/scripts',
            code: './djangoapp.py -c restart',
            user: 'root'
        })
      end
    end
  end
end
