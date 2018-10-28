# Cookbook Name:: db_server
# Spec:: default

require 'spec_helper'

describe 'db_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version).converge(described_recipe)
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt::default')
        expect(chef_run).to include_recipe('install_scripts::user')
        expect(chef_run).to include_recipe('db_server::postgresql')
        expect(chef_run).to include_recipe('db_server::redis')
      end
    end
  end
end

describe 'db_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When node['db_server']['postgresql']['db_name'] = django_base, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['db_server']['git']['app_repo'] = 'https://github.com/gloz-eu/django_base.git'
        end.converge(described_recipe)
      end

      before do
        stub_command(/ls \/.*\/recovery.conf/).and_return(false)
        stub_command("sudo -u postgres psql -c '\\l' | grep django_base").and_return(false)
        stub_command("sudo -u postgres psql -c '\\du' | grep db_user").and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt::default')
        expect(chef_run).to include_recipe('install_scripts::user')
        expect(chef_run).to include_recipe('install_scripts::scripts')
        expect(chef_run).to include_recipe('db_server::postgresql')
        expect(chef_run).to include_recipe('db_server::redis')
      end
    end
  end
end
