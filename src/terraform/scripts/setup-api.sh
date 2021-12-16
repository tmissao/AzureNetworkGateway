#! /bin/bash -e

apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt install docker-ce -y

docker run --rm -p 3000:3000 tmissao/hello-nodejs:984d65a0-a8c2-4909-ab7c-2949031fd369