# Cookbook Name:: standalone_app_server
# Chef Spec:: update

require 'spec_helper'

def common
  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
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

  it 'runs server_down' do
    expect( chef_run ).to run_bash('server_down').with(
        cwd: '/home/web_user/sites/django_base/scripts',
        code: './webserver.py -s down',
        user: 'root'
    )
  end

  it 'runs stop_uwsgi' do
    expect( chef_run ).to run_bash('stop_uwsgi').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -u stop',
        user: 'root'
    )
  end

  it 'runs stop_celery' do
    expect( chef_run ).to run_bash('stop_celery').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -c stop',
        user: 'root'
    )
  end

  it 'runs restore_static' do
    expect( chef_run ).to run_bash('restore_static').with(
        cwd: '/home/web_user/sites/django_base/scripts',
        code: './webserver.py -r',
        user: 'root'
    )
  end

  it 'runs remove_app' do
    expect( chef_run ).to run_bash('remove_app').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -x',
        user: 'root'
    )
  end

  it 'runs reinstall_app' do
    expect( chef_run ).to run_bash('reinstall_app').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -imt',
        user: 'root'
    )
  end

  it 'runs start_uwsgi' do
    expect( chef_run ).to run_bash('start_uwsgi').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -u start',
        user: 'root'
    )
  end

  it 'runs start_celery' do
    expect( chef_run ).to run_bash('start_celery').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -c start',
        user: 'root'
    )
  end

  it 'runs init_users.py' do
    expect(chef_run).to run_bash('update_init_users').with(
        cwd: '/home/app_user/sites/django_base/source/django_base',
        code: '/home/app_user/.envs/django_base/bin/python ./initialize/init_users.py',
        user: 'root'
    )
  end

  it 'runs init_data.py' do
    expect(chef_run).to run_bash('update_init_data').with({
         cwd: '/home/app_user/sites/django_base/source/django_base',
         code: '/home/app_user/.envs/django_base/bin/python ./initialize/init_data.py',
         user: 'root'
     })
  end

  it 'runs restart_celery' do
    expect( chef_run ).to run_bash('restart_celery').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -c restart',
        user: 'root'
    )
  end

  it 'runs restart_uwsgi' do
    expect( chef_run ).to run_bash('restart_uwsgi').with(
        cwd: '/home/app_user/sites/django_base/scripts',
        code: './djangoapp.py -u restart',
        user: 'root'
    )
  end

  it 'runs server_up' do
    expect( chef_run ).to run_bash('server_up').with(
        cwd: '/home/web_user/sites/django_base/scripts',
        code: './webserver.py -s up',
        user: 'root'
    )
  end
end

describe 'standalone_app_server::update' do
  %w(14.04 16.04).each do |version|
    context "When celery is true, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
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

      it 'resets the database' do
        expect( chef_run ).to run_bash('db_reset').with(
            cwd: '/home/db_user/sites/django_base/scripts',
            code: './dbserver.py -r',
            user: 'root'
        )
      end
    end
  end
end

describe 'standalone_app_server::update' do
  %w(14.04 16.04).each do |version|
    context "When celery is true and purge_db is false, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['standalone_app_server']['start_app']['celery'] = true
          node.set['standalone_app_server']['update']['purge_db'] = false
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

      it 'does not reset the database' do
        expect( chef_run ).to_not run_bash('db_reset').with(
            cwd: '/home/db_user/sites/django_base/scripts',
            code: './dbserver.py -r',
            user: 'root'
        )
      end
    end
  end
end
