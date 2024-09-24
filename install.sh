#!/bin/bash

# Set some vars
INSTALL_USER=nvwb-server

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
	echo "Running as root"
else
	echo "not running as root, sudo permissions required"
    SUDO="sudo"
fi

# Function to check Ubuntu version
check_ubuntu_version() {

    # Check if the OS is Ubuntu
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            echo "ERROR: AI Workbench can only be installed on Ubuntu. Your OS is $ID."
            exit 1
        fi
    else
        echo "ERROR: AI Workbench can only be installed on Ubuntu. Cannot determine the operating system."
        exit 1
    fi

    # Check Ubuntu version
    version=$(lsb_release -rs)
    if [ "$version" != "22.04" ] && [ "$version" != "24.04" ]; then
        echo "ERROR: AI Workbench can only be installed on Ubuntu 22.04 and 24.04, your version is: $version"
        exit 1
    else 
        echo "INFO: Ubuntu version $version looks good"
    fi
}

# Function to check RAM
check_ram() {
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 16 ]; then
        echo "ERROR: Minimum 16 GB of RAM required. Current RAM: ${total_ram} GB"
        exit 1
    else 
        echo "INFO: RAM looks good"
    fi
}

# Function to check disk space
check_disk_space() {
    available_space=$(df -BM / | awk 'NR==2 {print $4}' | sed 's/M//')
    
    if [ "$available_space" -lt 1024 ]; then
        echo "ERROR: Minimum 1 GB of disk space required for basic installation. Available space: ${available_space} MB"
        exit 1
    elif [ "$available_space" -lt 30720 ]; then  # 30 * 1024
        echo "WARNING: AI Workbench requires at least 30 GB of disk space for containers. Available space: ${available_space} MB"
    elif [ "$available_space" -lt 40960 ]; then  # 40 * 1024
        echo "WARNING: AI Workbench recommends 40 GB of disk space. Available space: ${available_space} MB"
    fi
}

check_virtual() {
	virt_env=$(systemd-detect-virt)

	if [ "$virt_env" = "none" ]; then
		echo "INFO: This system is not virtualized."
	elif [ "$virt_env" = "docker" ]; then
		echo "ERROR: Uh oh, you're already inside of a docker container. It may be possible for you to install AI Workbench on this system, but it's unlikely, and you won't be able to use this script."
		exit 1
	elif [ "$virt_env" = "lxc" ]; then
		echo "INFO: This system is running in a $virt_env container."
	else
		echo "INFO: This system is running in a $virt_env virtual machine."
	fi
}

# Main script starts here
check_ubuntu_version
check_ram
check_disk_space
check_virtual  

# Update and install necessary packages
$SUDO apt update
$SUDO apt install -y pciutils $SUDO

# Check if Docker is installed, and if so, will need to do more work to add Docker-related commands
if command -v docker &> /dev/null; then
    echo "Docker is installed. Configuring NVIDIA Container Toolkit..."
    $SUDO nvidia-ctk runtime configure --runtime=docker
    $SUDO apt install -y nvidia-container-toolkit
    $SUDO systemctl restart docker
else
    echo "Docker is not installed. Skipping NVIDIA Container Toolkit configuration."
fi

# Create user and add to sudo group
if ! id "$INSTALL_USER" &>/dev/null; then
    $SUDO useradd -m -s /bin/bash "$INSTALL_USER"
    $SUDO usermod -aG sudo "$INSTALL_USER"
    # Add user to docker group if Docker is installed
    if command -v docker &> /dev/null; then
        $SUDO usermod -aG docker "$INSTALL_USER"
        echo "Added $INSTALL_USER to docker group"
    fi
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

# Get the uid and gid for the INSTALL_USER (to be used for the install script)
USER_UID=$(id -u "$INSTALL_USER")
USER_GID=$(id -g "$INSTALL_USER")

echo "Installing NVIDIA AI Workbench..."
$SUDO -E "$INSTALL_DIR/nvwb-cli" install --accept --drivers --noninteractive --docker --gid $USER_GID --uid $USER_UID

echo "NVIDIA AI Workbench installation completed."