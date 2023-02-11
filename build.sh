podman pull docker.io/library/debian:bullseye
podman build -f Containerfile --build-arg username=${USERNAME} -t citrix
