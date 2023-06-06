# https://github.com/casey/just
alias b := build

# build image
build:
  podman pull docker.io/library/ubuntu:20.04
  podman build -f Containerfile --build-arg username=${USERNAME} -t citrix

# Install to bwrap location
installforbwrap:
  rm -rf ${HOME}/.var/bwrap/citrixroot
  mkdir -p ${HOME}/.var/bwrap/citrixroot && podman export $(podman create localhost/citrix:latest) | tar -C ${HOME}/.var/bwrap/citrixroot -xf -
