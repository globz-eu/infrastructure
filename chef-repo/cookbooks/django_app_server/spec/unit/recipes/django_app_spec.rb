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
# Cookbook Name:: django_app_server
# Server Spec:: django_app

require 'spec_helper'

describe 'django_app_server::django_app' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      before do
        stub_command('ls /home/app_user/sites/django_base/source/django_base').and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs the git package' do
        expect( chef_run ).to install_package('git')
      end

      it 'creates the /home/app_user/sites directory' do
        expect(chef_run).to create_directory('/home/app_user/sites').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0550',
        )
      end

      it 'does not create the /home/app_user/sites/django_base directory' do
        expect(chef_run).to_not create_directory('/home/app_user/sites/django_base').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0550',
        )
      end

      it 'does not create the /home/app_user/sites/django_base/source directory' do
        expect(chef_run).to_not create_directory('/home/app_user/sites/django_base/source').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0500',
        )
      end

      it 'does not clone the django app' do
        expect( chef_run ).to_not run_bash('git_clone_app')
      end

      it 'changes ownership of the django app to app_user:app_user' do
        expect(chef_run).to_not run_execute('chown -R app_user:app_user /home/app_user/sites/django_base/source')
      end

      it 'changes permissions for all files in django app to 0400' do
        expect(chef_run).to_not run_execute('find /home/app_user/sites/django_base/source -type f -exec chmod 0400 {} +')
      end

      it 'changes permissions for all directories in django app to 0500' do
        expect(chef_run).to_not run_execute('find /home/app_user/sites/django_base/source -type d -exec chmod 0500 {} +')
      end
    end
  end
end

describe 'django_app_server::django_app' do
  ['14.04', '16.04'].each do |version|
    context "When app name and git repo are specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|
          node.set['django_app_server']['django_app']['app_name'] = 'django_base'
          node.set['django_app_server']['git']['git_repo'] = 'https://github.com/globz-eu/django_base.git'
        end.converge(described_recipe)
      end

      before do
        stub_command('ls /home/app_user/sites/django_base/source/django_base').and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs the git package' do
        expect( chef_run ).to install_package('git')
      end

      it 'creates the /home/app_user/sites directory' do
        expect(chef_run).to create_directory('/home/app_user/sites').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0550',
        )
      end

      it 'creates the /home/app_user/sites/django_base directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base').with(
            owner: 'app_user',
            group: 'www-data',
            mode: '0550',
        )
      end

      it 'creates the /home/app_user/sites/django_base/source directory' do
        expect(chef_run).to create_directory('/home/app_user/sites/django_base/source').with(
            owner: 'app_user',
            group: 'app_user',
            mode: '0500',
        )
      end

      it 'clones the django app' do
        expect( chef_run ).to run_bash('git_clone_app').with(
            cwd: '/home/app_user/sites/django_base/source',
            code: 'git clone https://github.com/globz-eu/django_base.git',
            user: 'root'
        )
      end

      it 'changes ownership of the django app to app_user:app_user' do
        expect(chef_run).to run_execute('chown -R app_user:app_user /home/app_user/sites/django_base/source')
      end

      it 'changes permissions for all files in django app to 0400' do
        expect(chef_run).to run_execute('find /home/app_user/sites/django_base/source -type f -exec chmod 0400 {} +')
      end

      it 'changes permissions for all directories in django app to 0500' do
        expect(chef_run).to run_execute('find /home/app_user/sites/django_base/source -type d -exec chmod 0500 {} +')
      end

      # it 'creates the directory structure for the app static files' do
      #   expect(chef_run).to create_directory('/home/app_user/sites/django_base/static').with(
      #       owner: 'app_user',
      #       group: 'www-data',
      #       mode: '0750',
      #   )
      #   expect(chef_run).to create_directory('/home/app_user/sites/django_base/media').with(
      #       owner: 'app_user',
      #       group: 'www-data',
      #       mode: '0750',
      #   )
      # end
      #
      # it 'creates the directory structure for the unix socket' do
      #   expect(chef_run).to create_directory('/home/app_user/sites/django_base/sockets').with(
      #       owner: 'app_user',
      #       group: 'www-data',
      #       mode: '0750',
      #   )
      # end
      #
      # it 'adds the app path to the python path' do
      #   expect(chef_run).to create_template('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth').with(
      #       owner: 'app_user',
      #       group: 'app_user',
      #       mode: '0400',
      #       source: 'app_name.pth.erb',
      #       variables: {
      #           app_path: '/home/app_user/sites/django_base/source/django_base',
      #       })
      # end
      #
      # it 'adds the configuration file' do
      #   expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base/configuration.py').with(
      #       owner: 'app_user',
      #       group: 'app_user',
      #       mode: '0400',
      #       source: 'configuration.py.erb',
      #       variables: {
      #           secret_key: 'n)#o5pw7kelvr982iol48tz--n#q!*8681k3sv0^*q#-lddwv!',
      #           debug: 'False',
      #           allowed_host: 'localhost',
      #           engine: 'django.db.backends.postgresql_psycopg2',
      #           app_name: 'django_base',
      #           db_user: 'db_user',
      #           db_user_password: 'db_user_password',
      #           db_host: 'localhost'
      #       })
      #   expect(chef_run).to render_file('/home/app_user/sites/django_base/source/django_base/configuration.py')
      # end
      #
      # it 'adds the admin settings file' do
      #   expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base/django_base/settings_admin.py').with(
      #       owner: 'app_user',
      #       group: 'app_user',
      #       mode: '0400',
      #       source: 'settings_admin.py.erb',
      #       variables: {
      #           app_name: 'django_base',
      #           db_admin_user: 'postgres',
      #           db_admin_password: 'postgres_password',
      #       })
      #     expect(chef_run).to render_file('/home/app_user/.envs/django_base/lib/python3.4/django_base.pth')
      # end
      #
      #
      #
      # it 'adds the python script for installing system dependencies' do
      #   expect(chef_run).to create_template('/home/app_user/sites/django_base/source/install_dependencies.py').with(
      #       owner: 'app_user',
      #       group: 'app_user',
      #       mode: '0500',
      #       source: 'install_dependencies.py.erb',
      #       variables: {
      #           dep_file_path: '/home/app_user/sites/django_base/source/django_base/system_dependencies.txt'
      #       })
      #   expect(chef_run).to render_file('/home/app_user/sites/django_base/source/install_dependencies.py')
      # end
      #
      # it 'runs the install_dependencies script' do
      #   expect(chef_run).to run_bash('install_dependencies').with({
      #       cwd: '/home/app_user/sites/django_base/source',
      #       code: './install_dependencies.py',
      #       user: 'root'
      #       })
      # end
      #
      # it 'installs python packages from requirements.txt' do
      #   expect(chef_run).to run_bash('install_requirements').with({
      #       cwd: '/home/app_user/sites/django_base/source/django_base',
      #       code: '/home/app_user/.envs/django_base/bin/pip3 install -r ./requirements.txt',
      #       user: 'root'
      #       })
      # end

      # it 'creates the venv file structure' do
      #   expect(chef_run).to create_directory('/home/app_user/.envs').with({
      #       owner: 'app_user',
      #       group: 'app_user',
      #       mode: '0500'
      #                                                                     })
      #   expect(chef_run).to create_directory('/home/app_user/.envs/django_base').with({
      #       owner: 'app_user',
      #       group: 'app_user',
      #       mode: '0500'
      #                                                                     })
      # end
      #
      # it 'creates a venv' do
      #   expect(chef_run).to create_python_virtualenv('/home/app_user/.envs/django_base').with({
      #       python: '/usr/bin/python3.4'
      #                                                                                        })
      # end
      #
      # it 'installs python3-numpy' do
      #   expect(chef_run).to install_package('python3-numpy')
      # end
      #
      # it 'installs the numpy python package' do
      #   expect(chef_run).to install_python_package('numpy').with({version: '1.11.0'})
      # end
      #
      # it 'changes ownership of the venv to app_user:app_user' do
      #   expect(chef_run).to run_execute('chown -R app_user:app_user /home/app_user/.envs/django_base')
      # end

      # it 'adds the django_base_uwsgi.ini file' do
      #   params = [
      #       /^# django_base_uwsgi.ini file$/,
      #       %r(^chdir\s+=\s+/home/app_user/sites/django_base/source/django_base$),
      #       /^module\s+=\s+django_base\.wsgi$/,
      #       %r(^home\s+=\s+/home/app_user/\.envs/django_base$),
      #       /^uid\s+=\s+app_user$/,
      #       /^gid\s+=\s+www-data$/,
      #       /^processes\s+=\s+2$/,
      #       %r(^socket = /home/app_user/sites/django_base/sockets/django_base\.sock$),
      #       /^chmod-socket\s+=\s+660$/,
      #       %r(^daemonize\s+=\s+/var/log/uwsgi/django_base\.log$),
      #       %r(^master-fifo\s+=\s+/tmp/fifo0$)
      #   ]
      #   expect(chef_run).to create_template('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with(
      #       owner: 'app_user',
      #       group: 'app_user',
      #       mode: '0400',
      #       source: 'app_name_uwsgi.ini.erb',
      #       variables: {
      #           app_name: 'django_base',
      #           app_user: 'app_user',
      #           web_user: 'www-data',
      #           processes: '2',
      #           socket: '/home/app_user/sites/django_base/sockets/django_base.sock',
      #           chmod_socket: 'chmod-socket = 660',
      #           log_file: '/var/log/uwsgi/django_base.log',
      #           pid_file: '/tmp/django_base-uwsgi-master.pid'
      #       })
      #   params.each do |p|
      #     expect(chef_run).to render_file('/home/app_user/sites/django_base/source/django_base_uwsgi.ini').with_content(p)
      #   end
      #
      # end
    end
  end
end