# NVIDIA's AI Workbench

NVIDIA's AI Workbench is a complete development environment that simplifies the development experience and makes it easy to manage workloads between local and remote servers. 

## Overview 

AI workbench runs workloads in containers. These containers can be ones that you create, NVIDIA NIMs, or from other sources. The AI Workbench installation will mange the container environment for you. We recommend `podman` for various reasons but `docker` works great too.

# Installation  

There are two distinct installation processes that need to be considered: local and remote. You can think of your local installation as the client and your remote installation(s) as your server(s). You can connect to multiple remote instances from one local client.

## Local Install 
The local installation tends to be pretty straightforward, [follow the local instlalation instructions here](https://docs.nvidia.com/ai-workbench/user-guide/latest/installation/overview.html). 

## Remote Install 
The first goal of this project is to simplify the remote installation. Because remote environments vary widely, the installation also varies widely.  This example follows LambdaLabs 

For example, it is not possible to install AI Workbench on runpod.io becaues of the method that th

Remote installation gets a little trickier, because The bulk of this effort 


## TBD stuff for Daniel

ssh-keygen -t rsa -b 4096 -C "your_email@example.com"


`git clone https://github.com/brainwavecollective/nvidia-ai-workbench.git`
`#add your SSH Key to: ~/nvidia-ai-workbench/my_public_key.pub`
`./nvidia-ai-workbench/install.sh`


# Providers
Runpod - NOGO cool and all but runs in a container  
Lamdbda Labs - confirmed 
Massed Compute - confirmed
	RTX A6000 [Spot]
	Base Ubuntu Desktop 22.04









