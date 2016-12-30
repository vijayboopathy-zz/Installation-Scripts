# Installation scrip for installing Ansible
#
# Update apt cache
sudo apt update

# Install Software-properties-common
sudo apt-get install software-properties-common -y

# Add Ansible repository
sudo apt-add-repository ppa:ansible/ansible -y

# Update apt cache again
sudo apt update

# Install Ansible
sudo apt-get install ansible -y
