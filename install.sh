#!/bin/sh
# pip install --upgrade pygments
# gem install bundler

# conf=~/web/.conf
# mkdir -p $conf
# rsync -av config/ $conf

cd ruby
ruby install
bundle config build.nokogiri --use-system-libraries
bundle install
