#!/bin/sh
pip install --upgrade pygments
cd ruby
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
ruby install
cd ..
