name 'volgactf-ru'
description 'Installs and configures volgactf.ru'
version '1.3.0'

recipe 'volgactf-ru', 'Installs and configures volgactf.ru'
depends 'latest-nodejs', '~> 1.2.7'
depends 'modern_nginx', '~> 1.3.0'
depends 'ssh_known_hosts', '~> 2.0.0'
depends 'git2', '~> 1.0.0'
depends 'ssh-private-keys', '~> 1.0.0'
depends 'tls', '~> 2.0.0'
