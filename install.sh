#!/bin/bash

# ... [Previous parts of the script remain unchanged] ...

# Set up SSH for the new user
log "Setting up SSH for $INSTALL_USER"
ssh_setup_output=$($SUDO -u "$INSTALL_USER" bash << EOF
set -e
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat my_public_key.pub >> ~/.ssh/authorized_keys
echo "SSH setup completed for $INSTALL_USER"
EOF
)
ssh_setup_exit_code=$?

if [ $ssh_setup_exit_code -eq 0 ]; then
    log "$ssh_setup_output"
else
    log "ERROR: SSH setup failed for $INSTALL_USER with exit code $ssh_setup_exit_code"
    log "Error output: $ssh_setup_output"
    exit 1
fi

# Install NVIDIA AI Workbench
INSTALL_DIR="/home/$INSTALL_USER/.nvwb/bin"
log "Creating installation directory: $INSTALL_DIR"
$SUDO -u "$INSTALL_USER" mkdir -p "$INSTALL_DIR"

nvwb_cli_install_output=$($SUDO -u "$INSTALL_USER" bash << EOF
set -e
curl -L https://workbench.download.nvidia.com/stable/workbench-cli/\$(curl -L -s https://workbench.download.nvidia.com/stable/workbench-cli/LATEST)/nvwb-cli-\$(uname)-\$(uname -m) --output "$INSTALL_DIR/nvwb-cli"
chmod +x "$INSTALL_DIR/nvwb-cli"
echo "NVIDIA AI Workbench CLI downloaded and made executable"
EOF
)
nvwb_cli_install_exit_code=$?

if [ $nvwb_cli_install_exit_code -eq 0 ]; then
    log "$nvwb_cli_install_output"
else
    log "ERROR: NVIDIA AI Workbench CLI installation failed with exit code $nvwb_cli_install_exit_code"
    log "Error output: $nvwb_cli_install_output"
    exit 1
fi

# ... [Rest of the script remains unchanged] ...