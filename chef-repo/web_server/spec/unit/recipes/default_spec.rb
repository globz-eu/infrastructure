#
# Cookbook Name:: web_server
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'web_server::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe)}

  it 'installs the nginx package' do
    expect(chef_run).to install_package( 'nginx' )
  end

  it 'starts the nginx service' do
    expect(chef_run).to start_service( 'nginx' )
  end

  it 'enables the nginx service' do
    expect(chef_run).to enable_service( 'nginx' )
  end

end
