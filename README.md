# NVIDIA's AI Workbench

NVIDIA's AI Workbench is a complete development environment that simplifies the development experience and makes it easy to manage and scale workloads across local and remote servers. 

## Overview 

AI workbench runs workloads in containers. These containers can be ones that you create, NVIDIA NIMs, or from other sources. The AI Workbench installation will mange the container environment for you. We recommend `podman` for various reasons but `docker` works great too.


# Pre-Requisites 

You will need an SSH key for this process to work. If you don't already have one, you can create it with the following command:
`ssh-keygen -t rsa -b 4096 -C "your_email@example.com"`



# Installation  

There are two distinct installation processes that need to be considered: local and remote. You can think of your local installation as the client and your remote installation(s) as your server(s). You can connect to multiple remote instances from one local client. Unless you have a powerful local computer, we recommend keeping your local instance lightweight and using it for basic things, with all of your heavy lifting happening on your remote instances.

## Local Install 
The local installation tends to be pretty straightforward, [follow the local instlalation instructions here](https://docs.nvidia.com/ai-workbench/user-guide/latest/installation/overview.html). 

## Remote Install 
There are many GPU providers available. The first goal of this project is to make it easier for you to use those resource by simplifying the remote installation process. Because remote environments vary widely, the installation also varies widely.  

Once you have your remote server setup, execute the following:   
`git clone https://github.com/brainwavecollective/nvidia-ai-workbench.git`  
`#add your SSH Key to: ~/nvidia-ai-workbench/my_public_key.pub`  
`./nvidia-ai-workbench/install.sh`   



# FYI - Results
| Provider | Status | Notes |
|----------|--------|-------|
| Runpod | Does not work | We like the provider generally but can't access host b/c we're isolated in a container |
| Lambda Labs | Confirmed |  |
| Massed Compute | Confirmed | RTX A6000 [Spot], Base Ubuntu Desktop 22.04 |





