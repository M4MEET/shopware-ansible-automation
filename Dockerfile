# Use Ubuntu 24 as the base image
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package manager and install dependencies
RUN apt-get update && \
    apt-get install -y software-properties-common curl wget git sudo && \
    apt-get clean

# Install Ansible
RUN apt-add-repository ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y ansible

# Create a working directory
WORKDIR /workspace

# Copy any files from your host to the container (optional)
# COPY . /workspace

# Set /workspace as the default directory on container startup
CMD ["/bin/bash"]

