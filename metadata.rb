name 'volgactf-ru'
description 'Installs and configures volgactf.ru'
version '1.8.0'

recipe 'volgactf-ru', 'Installs and configures volgactf.ru'
depends 'nodejs'
depends 'ngx', '>= 2.1.0'
depends 'tls', '>= 3.2.0'
depends 'instance', '~> 2.0.0'
