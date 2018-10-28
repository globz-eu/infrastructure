# Cookbook Name:: django_app_server
# Recipe:: python
#
# Installs python3.4 or python3.5 runtime

if node['platform_version'].include?('14.04')
  # install python3.4 runtime
  python_runtime '3.4'

  bash 'install_virtualenv' do
    code 'pip install virtualenv'
    user 'root'
    not_if 'pip list | grep virtualenv', :user => 'root'
  end
end

if node['platform_version'].include?('16.04')
  # install python3.5 runtime
  package %w(python3.5-dev python3-pip python3-venv)
end

bash 'update_pip' do
  code 'pip3 install --upgrade pip'
  user 'root'
end
