#!/bin/bash
sudo apt update
echo Installing Docker...
# Install Docker on Ubuntu 14.04.4 x64
# Ref https://docs.docker.com/engine/installation/linux/ubuntulinux/
# No interactive for now.
export DEBIAN_FRONTEND=noninteractive
# Update your APT package index.
sudo apt-get -y update
# Update package information, ensure that APT works with the https method, and that CA certificates are installed.
sudo apt-get -y install apt-transport-https ca-certificates
# Add the new GPG key.
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
# Add docker.list
sudo echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list
# Update your APT package index.
sudo apt-get -y update
# Verify that APT is pulling from the right repository.
sudo apt-cache policy docker-engine
# Install the recommended package.
sudo apt-get -y install linux-image-extra-$(uname -r)
# Install Docker.
sudo apt-get -y install docker-engine
# Start the docker daemon.
sudo service docker start
# Validate docker version
docker -v
#Add user to docker group
sudo usermod -aG docker $USER

echo Installing Docker-Compose...
#!/bin/bash
# Update apt repo
sudo apt update

# Install python pip
sudo apt install python-pip -y

# Install Docker Compose
sudo pip install docker-compose

echo Installing apache2-utils...
echo
sudo apt-get -y install apache2-utils

echo Creating registry scaffolding...
echo
if [ -d ~/docker-registry ]
then
    echo docker-registry directory exists!
    echo
else
    echo Creating docker-registry directory...
    echo
    mkdir ~/docker-registry && \
        cd $_ && mkdir data && \
        mkdir nginx
fi

if [ -f ~/docker-registry/docker-compose.yml ]
then
    echo docker-compose file is already there!
    echo
else
    echo Creating Nginx configuration...
    echo
    echo "nginx:
  image: \"nginx:1.9\"
  ports:
    - 5043:443
  links:
    - registry:registry
  volumes:
    - ./nginx/:/etc/nginx/conf.d:ro
registry:
  image: registry:2
  ports:
    - 127.0.0.1:5000:5000
  environment:
    REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
  volumes:
    - ./data:/data" > docker-compose.yml
fi

if [ -f ~/docker-registry/nginx/registry.conf ]
then
    echo Nginx configuration existis!
    echo
else
    echo "upstream docker-registry {
  server registry:5000;
}

server {
  listen 443;
  server_name myregistrydomain.com;

  # SSL
  # ssl on;
  # ssl_certificate /etc/nginx/conf.d/domain.crt;
  # ssl_certificate_key /etc/nginx/conf.d/domain.key;

  # disable any limits to avoid HTTP 413 for large image uploads
  client_max_body_size 0;

  # required to avoid HTTP 411: see Issue #1486 (https://github.com/docker/docker/issues/1486)
  chunked_transfer_encoding on;

  location /v2/ {
    # Do not allow connections from docker 1.5 and earlier
    # docker pre-1.6.0 did not properly set the user agent on ping, catch \"Go *\" user agents
    if (\$http_user_agent ~ \"^(docker\\/1\\.(3|4|5(?!\\.[0-9]-dev))|Go ).*$\" ) {
      return 404;
    }

    # To add basic authentication to v2 use auth_basic setting plus add_header
    # auth_basic \"registry.localhost\";
    # auth_basic_user_file /etc/nginx/conf.d/registry.password;
    # add_header 'Docker-Distribution-Api-Version' 'registry/2.0' always;

    proxy_pass                          http://docker-registry;
    proxy_set_header  Host              \$http_host;   # required for docker client's sake
    proxy_set_header  X-Real-IP         \$remote_addr; # pass on real client's IP
    proxy_set_header  X-Forwarded-For   \$proxy_add_x_forwarded_for;
    proxy_set_header  X-Forwarded-Proto \$scheme;
    proxy_read_timeout                  900;
  }
}" > ~/docker-registry/nginx/registry.conf
fi

cd ~/docker-registry/nginx
echo -n "Enter Username and press [ENTER]: "
read ruser

if [ -f registry.password ] && grep $ruser registry.password
then
    echo Uses Exists
else
    echo Creating First User
    htpasswd -c registry.password $ruser
fi

if grep '# auth_basic' ~/docker-registry/nginx/registry.conf
then
    sed -i 's/# auth_basic/auth_basic/g' ~/docker-registry/nginx/registry.conf
    sed -i 's/# add_header/add_header/g' ~/docker-registry/nginx/registry.conf
    cd ~/docker-registry
else
    echo registry.conf already configured!
fi


if grep '# ssl' ~/docker-registry/nginx/registry.conf
then
    sed -i 's/# ssl/ssl/g' ~/docker-registry/nginx/registry.conf
    echo -n "Enter your domain name: "
    read domain
    echo
    sed -i "s/myregistrydomain.com/$domain/g" ~/docker-registry/nginx/registry.conf
else
    echo
fi

echo Creating certificate for Docker Registry

if [ -f ~/docker-registry/nginx/domain.crt ]
then
    echo Certificate Exists!
    echo
    cd ~/docker-registry
else
    cd ~/docker-registry/nginx
    openssl genrsa -out devdockerCA.key 2048
    openssl req -x509 -new -nodes -key devdockerCA.key -days 10000 -out devdockerCA.crt
    openssl genrsa -out domain.key 2048
    echo
    echo When OpenSSL prompts you to enter the "Common Name" make sure to type in the domain or IP of your server!
    sleep 2
    openssl req -new -key domain.key -out dev-docker-registry.com.csr
    openssl x509 -req -in dev-docker-registry.com.csr -CA devdockerCA.crt -CAkey devdockerCA.key -CAcreateserial -out domain.crt -days 10000
    sudo rm -rf /usr/local/share/ca-certificates/docker-dev-cert
    sudo mkdir /usr/local/share/ca-certificates/docker-dev-cert
    sudo cp devdockerCA.crt /usr/local/share/ca-certificates/docker-dev-cert
    sudo update-ca-certificates
    sudo service docker restart
    sed 's/5043/443/g' ~/docker-registry/docker-compose.yml
    cd ~/docker-registry
fi

if [ -d /docker-registry ]
then
   echo Docker registry is already in root!
else
   cd ~/docker-registry
   sudo mv ~/docker-registry /docker-registry
   sudo chown -R root: /docker-registry
   sudo echo "description \"Docker Registry\"

start on runlevel [2345]
stop on runlevel [016]

respawn
respawn limit 10 5

chdir /docker-registry

exec /usr/local/bin/docker-compose up" > /etc/init/docker-registry.conf
fi

echo Bringing Up Docker Registry!
echo
sudo service docker-registry start
echo
sudo docker ps
sudo docker-compose up -d
