#!/bin/bash

# Set some vars
INSTALL_USER=nvidia-wb-client

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Function to check Ubuntu version
check_ubuntu_version() {
    version=$(lsb_release -rs)
    if [ "$version" != "22.04" ] && [ "$version" != "24.04" ]; then
        echo "Error: This script only supports Ubuntu 22.04 and 24.04"
        exit 1
	else 
		echo "AOK: Ubuntu looks good"
    fi
}

# Function to check RAM
check_ram() {
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 16 ]; then
        echo "Error: Minimum 16 GB of RAM required. Current RAM: ${total_ram} GB"
        exit 1
	else 
		echo "AOK: Ubuntu looks good"
    fi
}

# Function to check disk space
check_disk_space() {
    available_space=$(df -BM / | awk 'NR==2 {print $4}' | sed 's/M//')
    
    if [ "$available_space" -lt 1024 ]; then
        echo "Error: Minimum 1 GB of disk space required for basic installation. Available space: ${available_space} MB"
        exit 1
    elif [ "$available_space" -lt 30720 ]; then  # 30 * 1024
        echo "Warning: AI Workbench requires at least 30 GB of disk space for containers. Available space: ${available_space} MB"
    elif [ "$available_space" -lt 40960 ]; then  # 40 * 1024
        echo "Warning: AI Workbench recommends at least 40 GB of disk space. Available space: ${available_space} MB"
    fi
}

# Main script starts here
check_ubuntu_version
check_ram
check_disk_space

# Update and install necessary packages
$SUDO apt update
$SUDO apt install -y sudo pciutils

# Create user and add to sudo group
if ! id "$INSTALL_USER" &>/dev/null; then
    $SUDO useradd -m -s /bin/bash "$INSTALL_USER"
    $SUDO usermod -aG sudo "$INSTALL_USER"
fi

# Set up SSH for the new user
$SUDO -u "$INSTALL_USER" bash << EOF
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat my_public_key.pub >> ~/.ssh/authorized_keys
EOF

# Install NVIDIA AI Workbench
INSTALL_DIR="/home/$INSTALL_USER/.nvwb/bin"
$SUDO -u "$INSTALL_USER" mkdir -p "$INSTALL_DIR"

$SUDO -u "$INSTALL_USER" bash << EOF
curl -L https://workbench.download.nvidia.com/stable/workbench-cli/\$(curl -L -s https://workbench.download.nvidia.com/stable/workbench-cli/LATEST)/nvwb-cli-\$(uname)-\$(uname -m) --output "$INSTALL_DIR/nvwb-cli"
chmod +x "$INSTALL_DIR/nvwb-cli"
EOF

#get the uid and the gid (to be used for the install script)
# Get the uid and gid for the INSTALL_USER (to be used for the install script)
USER_UID=$(id -u "$INSTALL_USER")
USER_GID=$(id -g "$INSTALL_USER")
$SUDO -E "$INSTALL_DIR/nvwb-cli" install -h $USER_UID $USER_GID $etc...getcommand

echo "NVIDIA AI Workbench installation completed."
