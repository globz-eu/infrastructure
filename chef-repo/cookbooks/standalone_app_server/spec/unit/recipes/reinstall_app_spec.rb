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
# Cookbook:: standalone_app_server
# Server Spec:: reinstall_app

describe 'standalone_app_server::reinstall_app' do
  context 'When standalone_app_server::uninstall_app is true, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04').converge(described_recipe)
    end
    let(:stop_uwsgi) { chef_run.bash('stop_uwsgi') }

    before do
      stub_command(/ls \/.*\/recovery.conf/).and_return(false)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'does not stop without notification nginx' do
      expect(chef_run).to_not run_bash('nginx_stop').with(
          code: 'service nginx restart',
          user: 'root'
      )
    end

    it 'stops uwsgi' do
      expect(chef_run).to run_bash('stop_uwsgi').with(
          code: 'echo q > /tmp/fifo0',
          user: 'root'
      )
    end

    it 'notifies stop_nginx to run' do
      expect(stop_uwsgi).to notify('bash[nginx_stop]').to(:run).immediately
    end

    it 'drops the app database' do
      expect(chef_run).to run_bash('drop_database').with(
          code: "sudo -u postgres psql -c 'DROP DATABASE django_base;'",
          user: 'root'
      )
    end

    it 're-creates the app database' do
      expect(chef_run).to run_bash('create_database').with(
          code: "sudo -u postgres psql -c 'CREATE DATABASE django_base;'",
          user: 'root'
      )
    end

    it 'grants default database privileges' do
      expect(chef_run).to run_bash('grant_default_db').with(
          code: "sudo -u postgres psql -d django_base -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO db_user;'",
          user: 'root'
      )
    end

    it 'grants default sequence privileges' do
      expect(chef_run).to run_bash('grant_default_seq').with(
          code: "sudo -u postgres psql -d django_base -c 'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO db_user;'",
          user: 'root'
      )
    end

    it 'creates configuration backup directory' do
      expect(chef_run).to create_directory('/home/app_user/sites/django_base/tmp').with(
                 owner: 'app_user',
                 group: 'app_user',
                 mode: '0750'
      )
    end

    it 'moves the configuration files' do
      expect(chef_run).to run_bash('backup_configuration').with(
                cwd: '/home/app_user/sites/django_base/source/django_base',
                code: 'cp ./configuration.py ../../tmp/',
                user: 'root'
      )
      expect(chef_run).to run_bash('backup_settings_admin').with(
                cwd: '/home/app_user/sites/django_base/source/django_base',
                code: 'cp ./django_base/settings_admin.py ../../tmp/',
                user: 'root'
      )
      expect(chef_run).to run_bash('backup_install_dependencies').with(
                cwd: '/home/app_user/sites/django_base/source',
                code: 'cp ./install_dependencies.py ../tmp/',
                user: 'root'
      )
      expect(chef_run).to run_bash('backup_uwsgi_ini').with(
                cwd: '/home/app_user/sites/django_base/source',
                code: 'cp ./django_base_uwsgi.ini ../tmp/',
                user: 'root'
      )
    end

    it 'removes app' do
      expect(chef_run).to run_bash('remove_app').with(
                cwd: '/home/app_user/sites/django_base/source',
                code: 'rm -Rf ./*',
                user: 'root'
      )
      expect(chef_run).to run_bash('remove_static').with(
                cwd: '/home/app_user/sites/django_base/static',
                code: 'rm -Rf ./*',
                user: 'root'
      )
      expect(chef_run).to run_bash('remove_media').with(
                cwd: '/home/app_user/sites/django_base/media',
                code: 'rm -Rf ./*',
                user: 'root'
      )
    end

    it 'clones the app from git' do
      expect(chef_run).to run_bash('git_clone_app').with(
                cwd: '/home/app_user/sites/django_base/source',
                code: 'git clone https://github.com/globz-eu/django_base.git',
                user: 'root'
      )
    end

    it 'rectifies ownership and permissions of app' do
      expect(chef_run).to run_execute('chown -R app_user:app_user /home/app_user/sites/django_base/source')
      expect(chef_run).to run_execute('find /home/app_user/sites/django_base/source -type f -exec chmod 0400 {} +')
      expect(chef_run).to run_execute('find /home/app_user/sites/django_base/source -type d -exec chmod 0500 {} +')
    end

    it 'copies configuration files back into place' do
      expect(chef_run).to run_bash('reset_configuration').with(
          cwd: '/home/app_user/sites/django_base/source/django_base',
          code: 'cp ../../tmp/configuration.py ./',
          user: 'root'
      )
      expect(chef_run).to run_bash('reset_settings_admin').with(
          cwd: '/home/app_user/sites/django_base/source/django_base',
          code: 'cp ../../tmp/settings_admin.py ./django_base/',
          user: 'root'
      )
      expect(chef_run).to run_bash('reset_install_dependencies').with(
          cwd: '/home/app_user/sites/django_base/source',
          code: 'cp ../tmp/install_dependencies.py ./',
          user: 'root'
      )
      expect(chef_run).to run_bash('reset_uwsgi_ini').with(
          cwd: '/home/app_user/sites/django_base/source',
          code: 'cp ../tmp/django_base_uwsgi.ini ./',
          user: 'root'
      )
    end

    it 'manages migrations' do
      expect(chef_run).to run_bash('re-migrate').with({
                 cwd: '/home/app_user/sites/django_base/source/django_base',
                 code: '/home/app_user/.envs/django_base/bin/python ./manage.py migrate --settings django_base.settings_admin',
                 user: 'root'
             })
    end

    it 'runs tests' do
      expect(chef_run).to run_bash('re-test_app').with({
                 cwd: '/home/app_user/sites/django_base/source/django_base',
                 code: '/home/app_user/.envs/django_base/bin/python ./manage.py test --settings django_base.settings_admin &> /var/log/django_base/test_results/test_$(date +"%d-%m-%y-%H%M%S").log',
                 user: 'root'
             })
    end

    it 'restarts uwsgi' do
      expect(chef_run).to run_bash('re-start_uwsgi').with({
                 cwd: '/home/app_user/sites/django_base/source',
                 code: 'uwsgi --ini ./django_base_uwsgi.ini ',
                 user: 'root'
             })
    end

    it 'restarts nginx' do
      expect(chef_run).to run_bash('re-start_nginx').with(
          code: 'service nginx start',
          user: 'root'
      )
    end
  end
end
