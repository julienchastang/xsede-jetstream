#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

usage="$(basename "$0") [-h] --
script to setup Docker. Run as root. Think before your type:\n
    -h  show this help text\n"

while [[ $# > 0 ]]
do
    key="$1"
    case $key in
        -h|--help)
            echo -e $usage
            exit
            ;;
    esac
    shift # past argument or value
done

DOCKER_USER=$(id -u -n)

systemctl stop docker

yum -y remove docker docker-common docker-selinux docker-engine-selinux \
  docker-engine docker-ce && rm -rf /var/lib/docker && yum -y update && yum -y \
  install git unzip wget nfs-kernel-server nfs-common

curl -sSL get.docker.com | sh
usermod -aG docker ${DOCKER_USER}

curl -L https://github.com/docker/compose/releases/download/1.26.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

systemctl enable docker.service
systemctl start docker.service

reboot now
