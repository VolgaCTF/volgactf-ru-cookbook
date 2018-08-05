name 'volgactf-ru'
description 'Installs and configures volgactf.ru'
version '1.6.1'

recipe 'volgactf-ru', 'Installs and configures volgactf.ru'
depends 'nodejs'
depends 'nginx'
depends 'tls', '~> 3.0.3'
depends 'instance', '~> 2.0.0'
