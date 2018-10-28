# Cookbook Name:: django_app_server
# Spec:: python

require 'spec_helper'

def common
  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end

  it 'updates pip3' do
    expect(chef_run).to run_bash('update_pip').with(
        code: 'pip3 install --upgrade pip',
        user: 'root'
    )
  end
end

describe 'django_app_server::python' do
  context 'When all attributes are default, on an Ubuntu 14.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04')
      runner.converge(described_recipe)
    end

    before do
      stub_command('pip list | grep virtualenv').and_return(false)
    end

    common

    it 'creates a python 3.4 runtime' do
      expect(chef_run).to install_python_runtime('3.4')
    end

    it 'installs virtualenv' do
      expect(chef_run).to run_bash('install_virtualenv').with(

      )
    end
  end
end

describe 'django_app_server::python' do
  context 'When all attributes are default, on an Ubuntu 16.04 platform' do
    include ChefVault::TestFixtures.rspec_shared_context(true)
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04').converge(described_recipe)
    end

    common

    it 'installs python3.5-dev and python3-pip' do
      expect(chef_run).to install_package(['python3.5-dev', 'python3-pip', 'python3-venv'])
    end
  end
end
