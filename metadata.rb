name 'volgactf-ru'
description 'Installs and configures volgactf.ru'
version '1.2.5'

recipe 'volgactf-ru', 'Installs and configures volgactf.ru'
depends 'latest-git', '~> 1.1.6'
depends 'latest-nodejs', '~> 1.2.5'
depends 'modern_nginx', '~> 1.2.5'
depends 'ssh_known_hosts', '~> 2.0.0'
depends 'ssh_user', '~> 0.1.1'
depends 'resolver', '~> 1.3.0'
depends 'git2', '~> 1.0.0'
depends 'rbenv', '1.7.1'
