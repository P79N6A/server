#!/bin/sh
conf=~/web/.conf
mkdir -p $conf
rsync -av config/ $conf
pip install --upgrade pygments
cd ruby
ruby install
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
