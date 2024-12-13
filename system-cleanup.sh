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

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   print_color $RED "This script must be run as root (use sudo)."
   exit 1
fi

# Clear PageCache, dentries and inodes
print_color $BLUE "Clearing PageCache, dentries and inodes..."
sync; echo 3 > /proc/sys/vm/drop_caches
print_color $GREEN "Memory cache cleared."

# Clear swap space
print_color $BLUE "Clearing swap space..."
swapoff -a && swapon -a
print_color $GREEN "Swap space cleared."

# Clean apt cache
print_color $BLUE "Cleaning apt cache..."
apt-get clean -y
apt-get autoclean -y
print_color $GREEN "Apt cache cleaned."

# Remove old kernels
print_color $BLUE "Removing old kernels..."
apt-get autoremove --purge -y
print_color $GREEN "Old kernels removed."

# Clean journal logs
print_color $BLUE "Cleaning journal logs..."
journalctl --vacuum-time=3d
print_color $GREEN "Journal logs cleaned."

# Remove old logs
print_color $BLUE "Removing old logs..."
find /var/log -type f -name "*.log" -mtime +30 -delete
find /var/log -type f -name "*.gz" -mtime +30 -delete
print_color $GREEN "Old logs removed."

# Clean thumbnail cache
print_color $BLUE "Cleaning thumbnail cache..."
rm -rf ~/.cache/thumbnails/*
print_color $GREEN "Thumbnail cache cleaned."

# Remove temporary files
print_color $BLUE "Removing temporary files..."
rm -rf /tmp/*
print_color $GREEN "Temporary files removed."

# Clean trash
print_color $BLUE "Cleaning trash..."
rm -rf ~/.local/share/Trash/*
print_color $GREEN "Trash cleaned."

# Optimize SSD if present (use with caution)
if [ -f /etc/fstab ] && grep -q "discard" /etc/fstab; then
    print_color $BLUE "Optimizing SSD..."
    fstrim -v /
    print_color $GREEN "SSD optimized."
fi

# Update locate database
print_color $BLUE "Updating locate database..."
updatedb
print_color $GREEN "Locate database updated."

print_color $GREEN "System cleanup completed."
print_color $YELLOW "You may want to reboot your system to apply all changes."

# Display system information
print_color $BLUE "\nCurrent system status:"
free -h
df -h
