name 'volgactf-ru'
description 'Installs and configures volgactf.ru'
version '1.7.0'

recipe 'volgactf-ru', 'Installs and configures volgactf.ru'
depends 'nodejs'
depends 'nginx'
depends 'tls', '~> 3.1.0'
depends 'instance', '~> 2.0.0'
