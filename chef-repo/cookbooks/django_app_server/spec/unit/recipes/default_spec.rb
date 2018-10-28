# Cookbook Name:: django_app_server
# Spec:: default

require 'spec_helper'

describe 'django_app_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version)
        runner.converge(described_recipe)
      end

      before do
        stub_command('pip list | grep virtualenv').and_return(false)
        stub_command("pip3 list | grep uWSGI").and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt::default')
        expect(chef_run).to include_recipe('install_scripts::user')
        expect(chef_run).to include_recipe('django_app_server::python')
        expect(chef_run).to include_recipe('django_app_server::uwsgi')
        expect(chef_run).to include_recipe('django_app_server::django_app')
      end
    end
  end
end

describe 'django_app_server::default' do
  ['14.04', '16.04'].each do |version|
    context "When all attributes are default, on an Ubuntu #{version} platform" do
      include ChefVault::TestFixtures.rspec_shared_context(true)
      let(:chef_run) do
        ChefSpec::SoloRunner.new(platform: 'ubuntu', version: version) do |node|
          node.set['django_app_server']['git']['app_repo'] = 'https://github.com/gloz-eu/django_base.git'
        end.converge(described_recipe)
      end

      before do
        stub_command('pip list | grep virtualenv').and_return(false)
        stub_command("pip3 list | grep uWSGI").and_return(false)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes the expected recipes' do
        expect(chef_run).to include_recipe('chef-vault')
        expect(chef_run).to include_recipe('apt::default')
        expect(chef_run).to include_recipe('install_scripts::user')
        expect(chef_run).to include_recipe('install_scripts::scripts')
        expect(chef_run).to include_recipe('django_app_server::python')
        expect(chef_run).to include_recipe('django_app_server::uwsgi')
        expect(chef_run).to include_recipe('django_app_server::django_app')
      end
    end
  end
end
