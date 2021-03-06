name 'web_server'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
description 'Installs/Configures web_server'
long_description 'Installs/Configures web_server'
version '0.2.5'

depends 'basic_node', '~> 0.2.2'
depends 'chef-vault', '~> 1.3.3'
depends 'apt', '~> 4.0.1'
depends 'test-helper'
depends 'firewall', '~> 2.5.2'
depends 'install_scripts', '~> 0.1.17'
depends 'django_app_server', '~> 0.2.8'
