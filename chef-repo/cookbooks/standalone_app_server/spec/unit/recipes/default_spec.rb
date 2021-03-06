# Cookbook Name:: standalone_app_server
# Spec:: default

require 'spec_helper'

describe 'standalone_app_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When app name is specified, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['web_server']['git']['app_repo'] = 'https://github.com/globz-eu/django_base.git'
          node.set['db_server']['postgresql']['db_name'] = 'django_base'
          if version == '14.04'
            node.set['standalone_app_server']['node_number'] = '000'
          elsif version == '16.04'
            node.set['standalone_app_server']['node_number'] = '001'
          end
        end.converge(described_recipe)
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
        stub_command("pip3 list | grep uWSGI").and_return(false)
        stub_command("sudo -u postgres psql -c '\\du' | grep db_user").and_return(false)
        stub_command("ls /home/app_user/sites/django_base/scripts").and_return(false)
        stub_command("pip list | grep virtualenv").and_return(false)
        stub_command("ls /home/web_user/sites/django_base/down/index.html").and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the correct recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt::default')
        expect(chef_run).to include_recipe('install_scripts::user')
        expect(chef_run).to include_recipe('db_server::default')
        expect(chef_run).to include_recipe('django_app_server::default')
        expect(chef_run).to include_recipe('web_server::default')
      end
    end
  end
end
