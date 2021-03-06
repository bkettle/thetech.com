name 'thetech-dev'
maintainer 'Jiahao Li'
maintainer_email 'jiahaoli@mit.edu'
license 'All Rights Reserved'
description 'Provisions a development environment of The MIT Tech\'s website'
long_description 'Provisions a development environment of The MIT Tech\'s website'
version '0.1.0'
chef_version '>= 12.14' if respond_to?(:chef_version)

depends 'poise-ruby'
depends 'poise-ruby-build'
depends 'postgresql'
depends 'redisio'
depends 'java'
depends 'elasticsearch'
