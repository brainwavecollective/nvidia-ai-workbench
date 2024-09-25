#!/bin/bash

set -e

# Set some vars
INSTALL_USER=nvwb-server
ORIGINAL_USER=$(whoami)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# Set up SUDO variable
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] (User: $(whoami)) $1"
}

# Function to check Ubuntu version
check_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            log "ERROR: AI Workbench can only be installed on Ubuntu. Your OS is $ID."
            exit 1
        fi
    else
        log "ERROR: AI Workbench can only be installed on Ubuntu. Cannot determine the operating system."
        exit 1
    fi

    version=$(lsb_release -rs)
    if [ "$version" != "22.04" ] && [ "$version" != "24.04" ]; then
        log "ERROR: AI Workbench can only be installed on Ubuntu 22.04 and 24.04, your version is: $version"
        exit 1
    else 
        log "INFO: Ubuntu version $version looks good"
    fi
}

# Function to check RAM
check_ram() {
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 16 ]; then
        log "ERROR: Minimum 16 GB of RAM required. Current RAM: ${total_ram} GB"
        exit 1
    else 
        log "INFO: RAM looks good"
    fi
}

# Function to check disk space
check_disk_space() {
    available_space=$(df -BM / | awk 'NR==2 {print $4}' | sed 's/M//')
    
    if [ "$available_space" -lt 1024 ]; then
        log "ERROR: Minimum 1 GB of disk space required for basic installation. Available space: ${available_space} MB"
        exit 1
    elif [ "$available_space" -lt 30720 ]; then
        log "WARNING: AI Workbench requires at least 30 GB of disk space for containers. Available space: ${available_space} MB"
    elif [ "$available_space" -lt 40960 ]; then
        log "WARNING: AI Workbench recommends 40 GB of disk space. Available space: ${available_space} MB"
    fi
}

check_virtual() {
    virt_env=$(systemd-detect-virt)

    if [ "$virt_env" = "none" ]; then
        log "INFO: This system is not virtualized."
    elif [ "$virt_env" = "docker" ]; then
        log "ERROR: Uh oh, you're already inside of a docker container. It may be possible for you to install AI Workbench on this system, but it's unlikely, and you won't be able to use this script."
        exit 1
    elif [ "$virt_env" = "lxc" ]; then
        log "INFO: This system is running in a $virt_env container."
    else
        log "INFO: This system is running in a $virt_env virtual machine."
    fi
}

# Main script starts here
log "Checking installation requirements..."
check_ubuntu_version
check_ram
check_disk_space
check_virtual  
log "... installation requirements check complete."

log "Updating and installing necessary packages..."
$SUDO apt update
$SUDO apt install -y pciutils sudo
log "... packages installed successfully"

# Check if Docker is installed
if command -v docker &> /dev/null; then
    log "Docker is installed. Configuring NVIDIA Container Toolkit..."
    $SUDO nvidia-ctk runtime configure --runtime=docker
    $SUDO apt install -y nvidia-container-toolkit
    $SUDO systemctl restart docker
    log "NVIDIA Container Toolkit configured"
else
    log "Docker is not installed. Skipping NVIDIA Container Toolkit configuration."
fi

# Create user and add to sudo group
if ! id "$INSTALL_USER" &>/dev/null; then
    log "Creating user $INSTALL_USER"
    $SUDO useradd -m -s /bin/bash "$INSTALL_USER"
    $SUDO usermod -aG sudo "$INSTALL_USER"
    if command -v docker &> /dev/null; then
        $SUDO usermod -aG docker "$INSTALL_USER"
        log "Added $INSTALL_USER to docker group"
    fi
    log "User $INSTALL_USER created and configured"
else
    log "User $INSTALL_USER already exists"
fi

# Set up SSH for the new user
log "Setting up SSH for $INSTALL_USER"
$SUDO mkdir -p /home/$INSTALL_USER/.ssh
$SUDO chmod 755 /home/$INSTALL_USER  # Ensure the home directory is accessible
$SUDO chmod 644 "$SCRIPT_DIR/my_public_key.pub" # Ensure the public key can be added to authorized keys

# Switch to the new user for the rest of the SSH setup
$SUDO su - $INSTALL_USER << EOF
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat $SCRIPT_DIR/my_public_key.pub >> ~/.ssh/authorized_keys
EOF

log "SSH setup completed for $INSTALL_USER"

# Switch to the INSTALL_USER for the rest of the script
log "Switching to user $INSTALL_USER for the remainder of the installation"
$SUDO su - $INSTALL_USER << EOF

# Function for logging (redefined for the new user context)
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] (User: $(whoami)) $1"
}

# Install NVIDIA AI Workbench
INSTALL_DIR="/home/$INSTALL_USER/.nvwb/bin"
log "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

log "Downloading NVIDIA AI Workbench CLI"
curl -L https://workbench.download.nvidia.com/stable/workbench-cli/\$(curl -L -s https://workbench.download.nvidia.com/stable/workbench-cli/LATEST)/nvwb-cli-\$(uname)-\$(uname -m) --output "$INSTALL_DIR/nvwb-cli"
chmod +x "$INSTALL_DIR/nvwb-cli"
log "NVIDIA AI Workbench CLI downloaded and made executable"
log "CLI file details: $(ls -l "$INSTALL_DIR/nvwb-cli")"

# Verify the installation directory and CLI exist
log "Verifying installation"
if [ -d "$INSTALL_DIR" ] && [ -x "$INSTALL_DIR/nvwb-cli" ]; then
    log "Installation directory and CLI verified"
else
    log "ERROR: Installation directory or CLI not found or not executable"
    log "Directory contents: $(ls -la "$INSTALL_DIR")"
    exit 1
fi

# Get the uid and gid for the INSTALL_USER
USER_UID=$(id -u)
USER_GID=$(id -g)

log "Installing NVIDIA AI Workbench..."
"$INSTALL_DIR/nvwb-cli" install --accept --drivers --noninteractive --docker --gid $USER_GID --uid $USER_UID

log "Verifying workbench service..."
if "$INSTALL_DIR/nvwb-cli" status | grep -q "Workbench is running"; then
    log "Workbench service is running correctly"
else
    log "ERROR: Workbench service is not running as expected"
    exit 1
fi

log "Installation process completed. You can now connect to this instance from your local AI Workbench client."
log "Use your SSH key and configure access to this instance with the user: $INSTALL_USER"

# Final check for critical directories and files
log "Performing final checks..."
critical_paths=(
    "/home/$INSTALL_USER/.nvwb"
    "/home/$INSTALL_USER/.nvwb/bin"
    "/home/$INSTALL_USER/.nvwb/bin/nvwb-cli"
    "/home/$INSTALL_USER/.nvwb/bin/wb-svc"
)

for path in "\${critical_paths[@]}"; do
    if [ -e "$path" ]; then
        log "Verified: $path exists"
    else
        log "WARNING: $path does not exist"
    fi
done

log "Script execution completed"
EOF

log "Installation script finished"