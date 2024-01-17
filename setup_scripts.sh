#!/bin/bash
#########################################################
# This script is intended to be run like this:
#
#   wget -qO - https://hyperplateau.ddataa.org | sudo bash
#
#########################################################
spinner() {
    tput civis
    local i sp n
    sp='|/-\'
    n=${#sp}
    printf ''
    while sleep 0.05; do
        printf "%s\b" "${sp:i++%n:1}"
    done
}

now="$(date '+%T')"

echo
echo '### HYPERPLATEAU SETUP ###'
echo '#'
printf "# starting script @%s\n" "$now"
echo '#'
# Are we running as root?
if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Did you leave out sudo?"
        exit 1
fi

# Setting up HOME as our user not as root
export HOME=/home/$SUDO_USER

# silent installation from apt
export DEBIAN_FRONTEND=noninteractive

echo '# - Updating & upgrading system packages'
spinner &
spinner_pid=$!
 
apt-get -q update &>/dev/null
apt-get -qy upgrade &>/dev/null

# Clone the PLATEAU repository if it doesn't exist.
if [ ! -d $HOME/HYPERPLATEAU ]; then
        if [ ! -f /usr/bin/git ]; then
                echo '# - Installing git'
                apt-get -qy install git &>/dev/null
        fi
        echo '# - Downloading HYPERPLATEAU'
        sudo -u $SUDO_USER bash -c "git clone https://github.com/Ddataa/HYPERPLATEAU.git -b develop-node $HOME/HYPERPLATEAU &>/dev/null"
fi

# Change directory to it.
cd $HOME/HYPERPLATEAU

# Finishing spinning
printf "%s\b" ""
tput cnorm
kill "$spinner_pid" &>/dev/null

# Start setup script.
sudo -u $SUDO_USER bash -c "$HOME/HYPERPLATEAU/setup/start.sh"

