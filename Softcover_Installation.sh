#!/bin/bash
# Install rbenv
# Update repo
echo Updating apt cache
sudo apt update

# Install Ruby
echo Installing Ruby 1.9.3
sudo apt-get install ruby-full
sudo apt-get install ruby1.9.1-dev

# Install Gem
echo Installting Ruby-Gems
cd /tmp \ &&
    wget https://rubygems.org/rubygems/rubygems-2.6.10.tgz && \
        tar -xvf rubygems-2.6.10.tgz && \
	cd rubygems-2* && \
	sudo ruby setup.rb && \
	rm -rf rubygems-2.6.10*

# Install Dependencies
sudo apt install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev nodejs

# Install Softcover
echo Installing Softcover
sleep 2;
sudo gem install softcover
