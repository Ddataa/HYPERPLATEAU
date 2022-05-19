#!/bin/bash
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

#if we start autonomously instead of the standard call by wget on hosted setup.sh
export HOME=/home/$USER

export DEBIAN_FRONTEND=noninteractive

#are we on a raspberry pi here ?
MODEL=/sys/firmware/devicetree/base/model
if test -f "$MODEL"; then
    echo "#   -> What kind of RaspberryPi is that ?"
    if grep -q 'Raspberry.Pi.' "/sys/firmware/devicetree/base/model"; then
        spinner &
        spinner_pid=$!
        echo "#   !> We are running on a RaspberryPi"
        echo "#   ... Creating extra swap space"
        sudo dphys-swapfile swapoff &>/dev/null
        sudo bash -c "echo 'CONF_SWAPSIZE=2048' > /etc/dphys-swapfile"        
        sudo dphys-swapfile setup &>/dev/null
        sudo dphys-swapfile swapon &>/dev/null
        echo "#   ... Installing extra dependencies"
        sudo apt-get -q -q install -yy hostapd dnsmasq libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev &>/dev/null        
        sudo systemctl stop hostapd &>/dev/null
        sudo systemctl stop dnsmasq &>/dev/null
        sudo tee /etc/hostapd/hostapd.conf &>/dev/null << EOF;
interface=wlan0
driver=nl80211
ssid=hyperplateau
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=hyperplateau
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF
        sudo systemctl unmask hostapd &>/dev/null
        sudo systemctl enable hostapd &>/dev/null
        sudo tee /etc/dnsmasq.conf &>/dev/null << EOF;
interface=wlan0
bind-dynamic 
domain-needed
bogus-priv
dhcp-range=192.168.50.150,192.168.50.200,255.255.255.0,12h
EOF
        printf "%s\b" ""
        kill "$spinner_pid" &>/dev/null
    fi
fi

# install dependencies
echo '# - Installing core dependencies'
spinner &
spinner_pid=$!
sudo apt-get -q -q install -yy avahi-daemon fping make gcc python3 build-essential libxtst6 libxss1 gconf-gsettings-backend libpangocairo-1.0-0 libnss3 libnss3-tools libasound2 curl debian-keyring debian-archive-keyring apt-transport-https &>/dev/null
printf "%s\b" ""

# install nvm
echo '# - Installing nvm'
curl -sL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash &>/dev/null
printf "%s\b" ""

# install nodejs 12.18.3
echo '# - Installing nodejs v16.13.0'
source $HOME/.nvm/nvm.sh
source $HOME/.nvm/bash_completion
nvm install 16.13.0 &>/dev/null
nvm use 16.13.0 &>/dev/null
printf "%s\b" ""

# compile plateau
echo '# - Compiling PLATEAU'
echo '#   -> backend install'
export PATH=$HOME/.nvm/versions/node/v16.13.0/bin:$PATH
source $HOME/.profile
cd $HOME/HYPERPLATEAU
npm install &>/dev/null

echo '#   -> frontend install'
cd $HOME/HYPERPLATEAU/public
nvm install 12.18.3 &>/dev/null
nvm use 12.18.3 &>/dev/null
npm install &>/dev/null
nvm use 16.13.0 &>/dev/null

# echo '#   -> frontend build'
# sudo -u $USER bash -c "export PATH=$HOME/.nvm/versions/node/v16.13.0/bin:$PATH && source $HOME/.profile && cd $HOME/HYPERPLATEAU/public && npm run build > /dev/null 2> /dev/null"
# printf "%s\b" ""
# kill "$spinner_pid" &>/dev/null

# install hyperspace
echo "# - Installing Hyperspace"
cd $HOME/HYPERPLATEAU
npm i hyperspace -g &>/dev/null

# install hyperdrive service
echo "# - Installing Hyperdrive Service"
cd $HOME/HYPERPLATEAU
npm i @hyperspace/hyperdrive -g &>/dev/null

# setup & start hyperspace
echo "# - Creating systemd service for hyperspace"
sudo touch /etc/systemd/system/hyperspace-$USER.service
sudo tee /etc/systemd/system/hyperspace-$USER.service &>/dev/null << EOF;
[Unit]
Description=start hyperspace

[Service]
Type=simple
RemainAfterExit=yes
User=$USER
Environment=PATH=/home/$USER/.nvm/versions/node/v16.13.0/bin:/home/$USER/.nvm/versions/node/v16.13.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/$USER/.nvm/versions/node/v16.13.0/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/bin
ExecStart=/home/$USER/.nvm/versions/node/v16.13.0/bin/hyperspace &

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload &>/dev/null

echo "# - Starting Hyperspace"
sudo systemctl start hyperspace-$USER.service &>/dev/null
sudo systemctl enable hyperspace-$USER.service &>/dev/null

# setup & start hyperdrive

# setup fuse
#echo "# - Setup Hyperdrive with FUSE"
#cd $HOME
#hyperdrive fuse-setup &>/dev/null

#echo "# - Creating systemd service for hyperdrive"
#sudo touch /etc/systemd/system/hyperdrive-$USER.service
#sudo tee /etc/systemd/system/hyperdrive-$USER.service &>/dev/null << EOF;
#[Unit]
#Requires=hyperspace-$USER.service
#Description=start hyperdrive

#[Service]
#Type=simple
#RemainAfterExit=yes
#User=$USER
#Environment=PATH=/home/$USER/.nvm/versions/node/v16.13.0/bin:/home/$USER/.nvm/versions/node/v16.13.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/$USER/.nvm/versions/node/v16.13.0/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/bin
#ExecStart=/home/$USER/.nvm/versions/node/v16.13.0/bin/hyperdrive start

#[Install]
#WantedBy=multi-user.target
#EOF

#sudo systemctl daemon-reload &>/dev/null

#echo "# - Starting Hyperdrive"
#sudo systemctl start hyperdrive-$USER.service &>/dev/null
#sudo systemctl enable hyperdrive-$USER.service &>/dev/null

printf "%s\b" ""
kill "$spinner_pid" &>/dev/null

if [ ! -d $HOME/.nvm/versions/node/v16.13.0/lib/node_modules/pm2 ]; then
    echo "# - Installing pm2"
    spinner &
    spinner_pid=$!
    # sudo -u $USER bash -c "export PATH=$HOME/.nvm/versions/node/v16.13.0/bin:$PATH && cd $HOME/HYPERPLATEAU && npm i -g pm2 > /dev/null 2> /dev/null"
    # bash -c "export PATH=$HOME/.nvm/versions/node/v16.13.0/bin:$PATH && cd $HOME/HYPERPLATEAU && npm i -g pm2 > /dev/null 2> /dev/null"    
    cd $HOME/HYPERPLATEAU
    npm i -g pm2 &>/dev/null
    echo '#   -> Installing PLATEAU systemd service'
    sudo env PATH=$PATH:/home/$USER/.nvm/versions/node/v16.13.0/bin /home/$USER/.nvm/versions/node/v16.13.0/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp /home/$USER &>/dev/null
    echo '#   -> Starting PLATEAU'
    # sudo -u $USER bash -c "export PATH=$HOME/.nvm/versions/node/v16.13.0/bin:$PATH && cd $HOME/HYPERPLATEAU && pm2 start index.js > /dev/null 2> /dev/null && pm2 save > /dev/null 2> /dev/null"
    # bash -c "export PATH=$HOME/.nvm/versions/node/v16.13.0/bin:$PATH && cd $HOME/HYPERPLATEAU && pm2 start index.js > /dev/null 2> /dev/null && pm2 save > /dev/null 2> /dev/null"
    cd $HOME/HYPERPLATEAU
    pm2 start index.js &>/dev/null
    pm2 save &>/dev/null
    source $HOME/.profile
    printf "%s\b" ""
    kill "$spinner_pid" &>/dev/null
fi

# echo '# - Installing Certificates'
# spinner &
# spinner_pid=$!
# wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-amd64
# mv mkcert-v1.4.3-linux-amd64 /usr/bin/mkcert
# chmod +x /usr/bin/mkcert
# sudo -u $USER bash -c "mkcert -install"
# sudo -u $USER bash -c "mkcert plateau.local localhost 127.0.0.1 ::1"
# sudo -u $USER bash -c "mkdir .certs && mv *.pem .certs"

# on ping around to use unique hostname plateau(n).local 
## TODO 'while' instead of 'if' for infinite quantity of local plateau
IP="plateau.local"
fping -c1 -t300 $IP 2>/dev/null 1>/dev/null
if [ "$?" = 0 ]
then
    echo "# -! host plateau.local already exist in LAN"
    IP="plateau0.local"
    fping -c1 -t300 $IP 2>/dev/null 1>/dev/null
    if [ "$?" = 0 ]
    then
        echo "# -! host plateau0.local already exist in LAN"
        IP="plateau1.local"
    fi
fi
echo "# -> setup hostname with $IP"
PLATEAU_LOCAL=$IP

echo "# - Installing Caddy web server"
spinner &
spinner_pid=$!
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc > /dev/null 2> /dev/null
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list > /dev/null 2> /dev/null
sudo apt-get update &>/dev/null
sudo apt-get -qy install caddy &>/dev/null

echo "#   -> Configuration reverse proxy with header policy https://$PLATEAU_LOCAL to 127.0.0.1:8080"
sudo touch /etc/caddy/Caddyfile
sudo tee /etc/caddy/Caddyfile &>/dev/null << EOF;
(logging) {
    log {
        output file /var/log/caddy/access.log
        format json {
            time_format iso8601
        }
    }
}

(header) {
        header {
                Strict-Transport-Security "max-age=31536000; includeSubDomains; reload"
                X-Content-Type-Options "nosniff"
                X-XSS-Protection "1; mode=block;"
                X-Robots-Tag "none;"
                X-Frame-Options "SAMEORIGIN"
                X-Permitted-Cross-Domain-Policies "none"
                X-Download-Options "noopen"
                Referrer-Policy "strict-origin-when-cross-origin"
                Cache-Control "public, max-age=15, must-revalidate"
                Content-Security-Policy "upgrade-insecure-requests"
                Permissions-Policy "accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'self'; camera 'none'; encrypted-media 'none'; fullscreen 'self'; geolocation 'none'; gyroscope 'none'; magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture *; speaker 'none'; sync-xhr 'none'; usb 'none'; vr 'none'"
                Server "No."
        }
}

$PLATEAU_LOCAL {
        import logging
        import header
        reverse_proxy 127.0.0.1:8080
}
EOF

sudo usermod -a -G sudo caddy &>/dev/null
sudo caddy trust &>/dev/null

echo "#   -> Restarting caddy service"
sudo systemctl -q restart caddy
printf "%s\b" ""
kill "$spinner_pid" &>/dev/null

if [ ! -n "$(grep $PLATEAU_LOCAL /etc/hosts)" ]; then
    echo "#  - Configuring $PLATEAU_LOCAL address in /etc/hosts"
    echo "127.0.0.1 $PLATEAU_LOCAL" | sudo tee -a /etc/hosts &>/dev/null
fi

echo "# - Changing hostname to $PLATEAU_LOCAL"
sudo hostnamectl set-hostname $PLATEAU_LOCAL
sudo systemctl -q restart avahi-daemon

tput cnorm

now="$(date '+%T')"

echo "#"
printf "# stopping script @%s\n" "$now"
echo "#"
echo "### PLATEAU IS READY :) ###"
echo