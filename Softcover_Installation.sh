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

# Install Softcover
echo Installing Softcover
sleep 2;
sudo gem install softcover
