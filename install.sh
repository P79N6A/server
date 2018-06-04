#!/bin/sh

# install this
cd ruby
ruby install

# install dependencies
pip install --upgrade pygments
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
