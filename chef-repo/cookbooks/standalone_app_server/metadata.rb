name 'standalone_app_server'
maintainer 'Stefan Dieterle'
maintainer_email 'golgoths@yahoo.fr'
license 'GNU General Public License'
description 'Installs/Configures standalone_app_server'
long_description 'Installs/Configures standalone_app_server'
version '0.2.12'

depends 'basic_node', '~> 0.2.2'
depends 'django_app_server', '~> 0.2.10'
depends 'chef-vault', '~> 1.3.3'
depends 'apt', '~> 4.0.1'
depends 'test-helper'
depends 'firewall', '~> 2.5.2'
depends 'postgresql', '~> 4.0.6'
depends 'database', '~> 5.1.2'
depends 'db_server', '~> 0.2.2'
depends 'web_server', '~> 0.2.2'
depends 'install_scripts', '~> 0.1.17'
