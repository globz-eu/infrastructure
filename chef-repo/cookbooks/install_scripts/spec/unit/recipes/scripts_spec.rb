# Cookbook Name:: install_scripts
# Chef Spec:: scripts

require 'spec_helper'

describe 'install_scripts::scripts' do
  ['14.04', '16.04'].each do |version|
    context "When app name, user and scripts are specified, on an Ubuntu #{version} platform" do
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['install_scripts']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['install_scripts']['users'] = [
            {
              user: 'app_user',
              password: '$6$3lI29czRRrey9x4$1OF/0nPqqKXUTTNk1zTvMJBbuAdn7ZmjB1OokHFbhlwBRLTZZGgYsLe1gRZE9sC8LhNfvouIl4/8BovOpMR440',
              groups: ['www-data'],
              scripts: 'app'
            },
            {
              user: 'web_user',
              password: '$6$2gyFi.Z4G5U$mixtbKdAjZJJbt9Uatd0gaFf80XvSVKYSjXz01.Cb0Qztsy74Z/Os92bcGu1OoaoI.Btsx0Z5X3x.xm7svejP1',
              scripts: 'web'
            },
            {
              user: 'db_user',
              password: '$6$J2qPIW16o3S6MvW0$3XCyfHwXLj9QKnyhvAhzUocSxdKvoqfpV3ygAuepvEaslfMsEs5F0eeDFDQmMS4tNTuFfe4ZulTyJy2LPl0a21',
              scripts: 'db'
            }
          ]
        end.converge(described_recipe)
      end

      @users = [
        {
          user: 'app_user',
          group: 'www-data',
          mode: '0550',
          scripts: ['djangoapp.py']
        },
        {
          user: 'web_user',
          group: 'web_user',
          mode: '0500',
          scripts: %w(webserver.py djangoapp.py)
        },
        {
          user: 'db_user',
          group: 'db_user',
          mode: '0500',
          scripts: ['dbserver.py']
        }
      ]

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs pip3' do
        expect(chef_run).to install_package('python3-pip')
      end

      it 'updates pip' do
        expect(chef_run).to run_bash('update_pip').with(
            code: 'pip3 install --upgrade pip',
            user: 'root'
        )
      end

      it 'creates the /var/log/django_base directory' do
        expect(chef_run).to create_directory('/var/log/django_base').with(
            owner: 'root',
            group: 'loggers',
            mode: '0775',
        )
      end

      @users.each do |u|
        it 'creates the /home/user/sites directory' do
            expect(chef_run).to create_directory("/home/#{u[:user]}/sites").with(
                owner: u[:user],
                group: u[:group],
                mode: u[:mode],
            )
        end

        it 'creates the /home/user/sites/django_base directory' do
          expect(chef_run).to create_directory("/home/#{u[:user]}/sites/django_base").with(
              owner: u[:user],
              group: u[:group],
              mode: u[:mode],
          )
        end

        it 'creates the /home/user/sites/django_base/scripts directory' do
          expect(chef_run).to create_directory("/home/#{u[:user]}/sites/django_base/scripts").with(
              owner: u[:user],
              group: u[:user],
              mode: '0500',
          )
        end

        it 'creates the /home/user/sites/django_base/scripts/utilities directory' do
          expect(chef_run).to create_directory("/home/#{u[:user]}/sites/django_base/scripts/utilities").with(
              owner: u[:user],
              group: u[:user],
              mode: '0500',
          )
        end

        it 'installs the scripts' do
          u[:scripts].each do |s|
            expect( chef_run ).to create_cookbook_file("/home/#{u[:user]}/sites/django_base/scripts/#{s}").with(
                source: "scripts/#{s}",
                owner: u[:user],
                group: u[:user],
                mode: '0500'
            )
          end
        end

        it 'installs the scripts utilities' do
          expect( chef_run ).to create_cookbook_file("/home/#{u[:user]}/sites/django_base/scripts/utilities/commandfileutils.py").with(
              source: 'scripts/utilities/commandfileutils.py',
              owner: u[:user],
              group: u[:user],
              mode: '0400'
          )
        end

        it 'installs the scripts requirements file' do
          expect( chef_run ).to create_cookbook_file("/home/#{u[:user]}/sites/django_base/scripts/requirements.txt").with(
              source: 'scripts/requirements.txt',
              owner: u[:user],
              group: u[:user],
              mode: '0400'
          )
        end
      end

      it 'installs scripts requirements' do
        expect(chef_run).to run_bash('install_scripts_requirements').with(
            cwd: '/home/app_user/sites/django_base/scripts',
            code: 'pip3 install -r requirements.txt',
            user: 'root'
        )
      end
    end
  end
end
