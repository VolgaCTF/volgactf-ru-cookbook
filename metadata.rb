name 'volgactf-ru'
description 'Installs and configures volgactf.ru'
version '1.4.0'

recipe 'volgactf-ru', 'Installs and configures volgactf.ru'
depends 'nodejs', '~> 4.0.0'
depends 'chef_nginx', '~> 6.1.1'
depends 'tls', '~> 3.0.0'
depends 'instance', '~> 1.0.0'
