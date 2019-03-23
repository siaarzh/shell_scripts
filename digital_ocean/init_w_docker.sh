#!/bin/bash

# Automated new droplet initialization script
# Based on:
# https://www.digitalocean.com/community/tutorials/automating-initial-server-setup-with-ubuntu-18-04
# https://www.get.docker.com
# 
# 

# + Update/Upgrade
# + Enable EPEL repository (needed for htop on CentOS)
# + Install utilities, apps
# + Disable unnecessary services (e.g. mail server on CentOS)
# + Replace chronyd with ntp (network time protocol) daemon
# + Enable firewall and open SSH port
# - Create swap file
# + Create a new sudo user
# + Install docker, docker-machine, docker-compose + give new user access
# + Disable password root SSH login


########################
### SCRIPT VARIABLES ###
########################

# Name of the user to create and grant sudo privileges
USERNAME=serzhan

# Whether to copy over the root user's `authorized_keys` file to the new sudo
# user.
COPY_AUTHORIZED_KEYS_FROM_ROOT=true

# Additional public keys to add to the new sudo user
# OTHER_PUBLIC_KEYS_TO_ADD=(
#     "ssh-rsa AAAAB..."
#     "ssh-rsa AAAAB..."
# )
OTHER_PUBLIC_KEYS_TO_ADD=(
    "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAuLboNPi0RfrT1A6H47c3KDOh8lxV+EV7mmoGZRrN0h/LRPHDgkIkl6W+As1KuzXcU8EcT3y1YfDBsNmVpBh9AYZHnIqAv6Xc5ibnw0g8Tol2LUcx/ZEsvaiGx2BayRm6cbiB8i5O7Eo6osh49xcUlVIb2L/cVuPcz94PrmSfcQAHsJKz98dUsjXrOg7STkc2Cl4KloOxbMqVJjEdhk46RKBDzpuCTGkWBEsMTRV8PeSZymuSIlCTT/VVB0EVBQZxrPPmkLdmvw6Jk3+miW7VXHtJ0sbO5Pn6SS3Xm7Qo1td8JbxrcZWBa4pGudGLZYXFoIt3OL6TabVzJcf1YkdPjQ== s_akhmetov"
)

# Set timezone
TIMEZONE=Asia/Almaty

# Get Host Public IP
HOST_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"

####################
### SCRIPT LOGIC ###
####################

# Determine OS platform
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO=$UNAME
unset UNAME

case "${DISTRO,,}" in
*"centos"*)
    # For CentOS:
    echo "Detected CentOS..."
    # Update centos
    yum check-update
    yum -y -q upgrade
    # Enable EPEL repository
    curl -L dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm -o epel-release-7-11.noarch.rpm
    rpm -ihv epel-release-7-11.noarch.rpm
    # Install utilities
    yum -y -q install nano vim-enhanced nmap telnet wget lsof bash-completion psmisc firewalld ntp htop git screen
    # Disable unnecessary services
    systemctl stop postfix
    systemctl disable postfix
    systemctl stop chronyd
    systemctl disable chronyd
    yum -y remove chronyd
    yum -y remove postfix
    # Cleanup
    yum -y autoremove
    yum -y clean all
    rm -rf /var/cache/yum
    
    # Firewall
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --reload
    # if you changed SSH port:
    # sudo firewall-cmd --permanent --remove-service=ssh
    # sudo firewall-cmd --permanent --add-port=4444/tcp
    
    # Network time
    timedatectl set-timezone ${TIMEZONE}
    systemctl start ntpd
    systemctl enable ntpd
    
    # # Create swap file (same size as system RAM). Note: not really recommended on SSD's
    # MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
    # dd if=/dev/zero of=/mnt/swapfile bs=1024 count=${MEMTOTAL}
    # chmod 600 /mnt/swapfile
    # mkswap /mnt/swapfile
    # swapon /mnt/swapfile
    # sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

    # Add sudo user and grant privileges
    useradd --create-home --shell "/bin/bash" --groups wheel "${USERNAME}"
    ;;
*"ubuntu"*)
    # For Ubuntu:
    echo "Detected Ubuntu..."
    
    # Update ubuntu
    apt-get update
    apt-get -y upgrade
	# Delete UFW
	apt-get purge -y ufw
    # Install utilities
    apt-get install -y -qq nmap firewalld curl
    # Cleanup
    apt-get -y autoremove
    
    # Add sudo user and grant privileges
    useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"
	
	# Turn on firewall and enable SSH
	systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --reload
    # if you changed SSH port:
    # sudo firewall-cmd --permanent --remove-service=ssh
    # sudo firewall-cmd --permanent --add-port=4444/tcp
	
    # Network time
	timedatectl set-timezone ${TIMEZONE}
	timedatectl set-ntp no
	apt-get install -y -qq ntp
    ;;
*)
    # All other systems
    echo "Your os is not supported. Stopping script."
    exit 1
    ;;
esac

# Check whether the root account has a real password set
encrypted_root_pw="$(grep root /etc/shadow | cut --delimiter=: --fields=2)"

if [ "${encrypted_root_pw}" != "*" ]; then
    # Transfer auto-generated root password to user if present
    # and lock the root account to password-based access
    echo "${USERNAME}:${encrypted_root_pw}" | chpasswd --encrypted
    passwd --lock root
else
    # Delete invalid password for user if using keys so that a new password
    # can be set without providing a previous value
    passwd --delete "${USERNAME}"
fi

# Expire the sudo user's password immediately to force a change
chage --lastday 0 "${USERNAME}"

# Create SSH directory for sudo user
home_directory="$(eval echo ~${USERNAME})"
mkdir --parents "${home_directory}/.ssh"

# Copy `authorized_keys` file from root if requested
if [ "${COPY_AUTHORIZED_KEYS_FROM_ROOT}" = true ]; then
    cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
fi

# Add additional provided public keys
for pub_key in "${OTHER_PUBLIC_KEYS_TO_ADD[@]}"; do
    echo "${pub_key}" >> "${home_directory}/.ssh/authorized_keys"
done

# Adjust SSH configuration ownership and permissions
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

# Disable root SSH login
sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)(.*)/PermitRootLogin no/' -i /etc/ssh/sshd_config
if sshd -t -q; then
    systemctl restart sshd
fi

######################
### INSTALL DOCKER ###
######################

curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh
rm -f get-docker.sh

# Add user to docker group, remember to re-login as that user to be part of group
usermod -aG docker ${USERNAME}
systemctl start docker
systemctl enable docker

# Docker machine
# Check for newest version: https://github.com/docker/machine/releases
curl -L https://github.com/docker/machine/releases/download/v0.16.1/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
install /tmp/docker-machine /usr/local/bin/docker-machine
# Clean up:
rm -f /tmp/docker-machine

# Docker compose
# Check for newest version: https://github.com/docker/compose/releases
curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

###############################
### OPEN DOCKER SWARM PORTS ###
###############################

# Make sure firewall is on
systemctl start firewalld
systemctl enable firewalld

# Open Docker Swarm Ports
firewall-cmd --add-port=2376/tcp --permanent
firewall-cmd --add-port=2377/tcp --permanent
firewall-cmd --add-port=7946/tcp --permanent
firewall-cmd --add-port=7946/udp --permanent
firewall-cmd --add-port=4789/udp --permanent

# Reload firewall and restart Docker
firewall-cmd --reload
systemctl restart docker

# Init Docker SWARM
docker swarm init --advertise-addr "${HOST_IP}"