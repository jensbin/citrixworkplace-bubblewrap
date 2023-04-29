podman pull docker.io/library/ubuntu:20.04
podman build -f Containerfile --build-arg username=${USERNAME} -t citrix
