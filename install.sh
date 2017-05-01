#!/bin/bash
# clone server, install deps, run
cd /opt && \
yum install -y ruby-devel rubygem-bundler git docker gcc && \
systemctl start docker && \
git clone --depth=1 https://gitlab.com/spaz/docker-remote-saver.git && \
cd docker-remote-saver/ && \    
bundle install && \
bundle exec rspec && \
nohup ruby server.rb &
