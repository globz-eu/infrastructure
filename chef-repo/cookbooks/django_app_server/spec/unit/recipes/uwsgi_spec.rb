# Cookbook Name:: django_app_server
# Spec:: uwsgi

require 'spec_helper'

describe 'django_app_server::uwsgi' do
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
        stub_command('pip3 list | grep uWSGI').and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'installs the uwsgi python package' do
        expect(chef_run).to run_bash('uwsgi').with(
                   code: 'pip3 install uwsgi',
                   user: 'root'
        )
      end

      it 'creates the /var/log/uwsgi directory' do
        expect(chef_run).to create_directory('/var/log/uwsgi').with(
            owner: 'root',
            group: 'root',
            mode: '0755',
        )
      end
    end
  end
end