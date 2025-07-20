#!/bin/bash
# This script is designed to configure a new machine with necessary settings and checks.
# It will check the distribution type and perform initial setup tasks.
# Ensure the script is run with root privileges

DISTRO=""
CREATED_USER=""

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use 'sudo' or switch to the root user."
    exit 1
fi

echo "Starting configuration for new machine..."
sleep 1.5
check_distro() {
    echo "Checking the distribution type..."
    sleep 1.5
    if [ -f /etc/debian_version ]; then
        echo "This is a Debian-based system."
        DISTRO="debian"
    elif [ -f /etc/redhat-release ]; then
        echo "This is a Red Hat-based system."
        DISTRO="redhat"
    elif [ -f /etc/arch-release ]; then
        echo "This is an Arch-based system."
        DISTRO="arch"
    else
        echo "Unknown distribution type."
        echo "Please run this script on a Debian, Red Hat, or Arch-based system."
    fi
}

update_system() {
    echo "Updating the system..."
    sleep 1.5
    if [ "$DISTRO" = "debian" ]; then
        apt update && apt upgrade -y
    elif [ "$DISTRO" = "redhat" ]; then
        dnf update -y
        dnf install epel-release
    elif [ "$DISTRO" = "arch" ]; then
        pacman -Syu --noconfirm
    else
        echo "Unsupported distribution for system update."
    fi
}

install_packages() {
    echo "Installing necessary packages..."
    sleep 1.5
    if [ "$DISTRO" = "debian" ]; then
        apt install -y openssh-server
    elif [ "$DISTRO" = "redhat" ]; then
        dnf install -y openssh-server
    elif [ "$DISTRO" = "arch" ]; then
        pacman -S --noconfirm openssh-server
    else
        echo "Unsupported distribution for package installation."
    fi
}

start_sshd() {
    echo "Starting SSH daemon..."
    sleep 1.5
    if [ "$DISTRO" = "debian" ]; then
        systemctl start sshd
        systemctl enable sshd
    elif [ "$DISTRO" = "redhat" ]; then
        systemctl start sshd
        systemctl enable sshd
    elif [ "$DISTRO" = "arch" ]; then
        systemctl start sshd
        systemctl enable sshd
    else
        echo "Unsupported distribution for starting SSH daemon."
    fi
}



create_ssh_allowed_users_group() {
    echo "Creating 'ssh_allowed_users' group..."
    sleep 1.5
    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "redhat" ] || [ "$DISTRO" = "arch" ]; then
        groupadd ssh_allowed_users || { echo "Failed to create group ssh_allowed_users"; return 1; }
        echo "Group 'ssh_allowed_users' created successfully."
    else
        echo "Unsupported distribution for group creation."
        return 1
    fi
}

create_user() {
    read -sp "Enter the password for the ansible user: " password
    newuser="ansible"
    # Validate input
    if [ -z "$newuser" ] || [ -z "$password" ]; then
        echo "Error: Username and password are required."
        return 1
    fi

    # Check if user already exists
    if id "$newuser" >/dev/null 2>&1; then
        echo "Error: User $newuser already exists."
        return 1
    fi

    echo "Creating a new user $newuser..."
    sleep 1.5

    # Create user based on DISTRO variable
    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "arch" ]; then
        sudo useradd -m -s /bin/bash "$newuser" || { echo "Failed to create user $newuser"; return 1; }
        sudo chpasswd <<< "$newuser:$password" || { echo "Failed to set password for $newuser"; return 1; }
        sudo usermod -aG sudo, ssh_allowed_users "$newuser" || { echo "Failed to add $newuser to sudo group"; return 1; }
        sudo echo "ansible  ALL=(ALL)  NOPASSWD: ALL" >> /etc/sudoers || { echo "Failed to add ansible user to sudoers"; return 1; }
    elif [ "$DISTRO" = "redhat" ]; then
        sudo useradd -m -s /bin/bash "$newuser" || { echo "Failed to create user $newuser"; return 1; }
        sudo chpasswd <<< "$newuser:$password" || { echo "Failed to set password for $newuser"; return 1; }
        sudo usermod -aG wheel, ssh_allowed_users "$newuser" || { echo "Failed to add $newuser to wheel group"; return 1; }
        sudo echo "ansible  ALL=(ALL)  NOPASSWD: ALL" >> /etc/sudoers || { echo "Failed to add ansible user to sudoers"; return 1; }
    else
        echo "Unsupported distribution for user creation: $DISTRO"
        return 1
    fi

    echo "User $newuser created successfully."
}

create_ssh_user_config_file() {
    echo "Creating SSH user configuration file..."
    sleep 1.5
    touch /etc/ssh/sshd_config.d/ssh_user.conf || { echo "Failed to create SSH user configuration file"; return 1; }
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config.d/ssh_user.conf || { echo "Failed to write to SSH user configuration file"; return 1; }
    echo "AllowGroups ssh_allowed_users" >> /etc/ssh/sshd_config.d/ssh_user.conf || { echo "Failed to write to SSH user configuration file"; return 1; }
}



function init() {
    check_distro
    update_system
    install_packages
    start_sshd
    create_ssh_allowed_users_group
    create_user
    create_ssh_user_config_file
    echo "Configuration completed successfully."
}

init

