#!/bin/bash
#
###############################################################################
# Configure raspbian server. Assumes raspian-light image installed
#
###############################################################################
# Check if running as root.
#

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

###############################################################################
# Update to the latest code if we need to.
#

apt update && apt upgrade -y

if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

###############################################################################
# Install needed software.
#

apt install -y neofetch chafa scrot vim-nox vim-addon-manager tmux git powerline powerline-gitstatus

###############################################################################
# Configure skel folder
#
cp /home/pi/.bash_logout /etc/skel
cp /home/pi/.bashrc /etc/skel
cp /home/pi/.profile /etc/skel
mkdir /etc/skel/.bashrc.d

cat >> /etc/skel/.bashrc <<'EOF'
if [ -d ./.bashrc.d ]; then
  for i in ./.bashrc.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
EOF

cat > /etc/skel/.bashrc.d/powerline.sh <<'EOF'
if [ -e /usr/share/powerline/bindings/bash/powerline.sh ]; then
  POWERLINE_BASH_CONTINUATION="1"
  POWERLINE_BASH_SELECT="1"
  . /usr/share/powerline/bindings/bash/powerline.sh
fi
EOF

cat > /etc/skel/.bashrc.d/neofetch.sh <<'EOF'
# run neofetch
if [ -x /usr/bin/neofetch ]; then
  /usr/bin/neofetch
fi
EOF

###############################################################################
# Create the user
#
adduser --gecos "Ctrl Esc" ctrlesc
usermod --append --groups adm,sudo,users ctrlesc

###############################################################################
# Configure a static IP address on the wired interface
#

# Get the name of the wired interface
INTERFACE=`ls /sys/class/net | grep en`
IP_ADDR="10.50.1.103/16"
DEFAULT_GW="10.50.254.254"
DNS_SERVERS="10.50.1.1 10.50.1.2"

# Configure a static profile on dhcpcd
cat >> /etc/dhcpcd.conf <<EOF

# Static IP configuration for wired interface
interface $INTERFACE
static ip_address=$IP_ADDR
static routers=$DEFAULT_GW
static domain_name_servers=$DNS_SERVERS
EOF


###############################################################################
# Disble the default pi user
usermod --lock --expiredate 1 pi

