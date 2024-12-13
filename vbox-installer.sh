#!/bin/bash

# Function to print colored messages
function print_color {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}\033[0m"
}

# Color definitions
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'

# Update package lists
print_color $BLUE "Updating package lists..."
if sudo apt update -qq 2>/dev/null; then
    print_color $GREEN "Package lists updated successfully."
else
    print_color $RED "Failed to update package lists."
    exit 1
fi

# Fix dpkg interruptions if any
if sudo dpkg --configure -a 2>&1 | grep -q 'dpkg was interrupted'; then
    print_color $YELLOW "Fixing dpkg interruptions..."
    sudo dpkg --configure -a
    print_color $GREEN "dpkg issues resolved."
fi

# Install dependencies
print_color $BLUE "Installing dependencies..."
if sudo apt install -y linux-headers-$(uname -r) build-essential dkms -qq; then
    print_color $GREEN "Dependencies installed successfully."
else
    print_color $RED "Failed to install dependencies."
    exit 1
fi

# Add VirtualBox repository
print_color $BLUE "Adding VirtualBox repository..."
if ! grep -q "^deb.*virtualbox" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    sudo apt update -qq
    print_color $GREEN "VirtualBox repository added successfully."
else
    print_color $YELLOW "VirtualBox repository already exists."
fi

# Install VirtualBox
print_color $BLUE "Installing VirtualBox..."
if sudo apt install -y virtualbox-6.1 -qq; then
    print_color $GREEN "VirtualBox installed successfully."
else
    print_color $RED "Failed to install VirtualBox."
    exit 1
fi

# Install VirtualBox Extension Pack
print_color $BLUE "Installing VirtualBox Extension Pack..."
version=$(vboxmanage -v)
extpack_version=$(echo $version | cut -d 'r' -f 1)
wget -q "https://download.virtualbox.org/virtualbox/${extpack_version}/Oracle_VM_VirtualBox_Extension_Pack-${extpack_version}.vbox-extpack" -O extension_pack.vbox-extpack
if sudo VBoxManage extpack install --replace extension_pack.vbox-extpack --accept-license=33d7284dc4a0ece381196fda3cfe2ed0e1e8e7ed7f27b9a9ebc4ee22e24bd23c; then
    print_color $GREEN "VirtualBox Extension Pack installed successfully."
else
    print_color $RED "Failed to install VirtualBox Extension Pack."
fi

# Clean up
rm extension_pack.vbox-extpack

# Add user to vboxusers group
print_color $BLUE "Adding user to vboxusers group..."
if sudo usermod -aG vboxusers $USER; then
    print_color $GREEN "User added to vboxusers group successfully."
else
    print_color $RED "Failed to add user to vboxusers group."
fi

# Fix common VirtualBox issues
print_color $BLUE "Fixing common VirtualBox issues..."

# Rebuild VirtualBox kernel modules
sudo /sbin/vboxconfig

# Enable VirtualBox kernel module
sudo modprobe vboxdrv

print_color $GREEN "VirtualBox installation and setup completed."
print_color $YELLOW "Please log out and log back in for group changes to take effect."
print_color $YELLOW "You may need to reboot your system for all changes to be applied."
