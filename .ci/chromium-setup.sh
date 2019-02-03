#! /bin/bash

set -e
# this script install chromium headless for a debian system used in CI.

apt-get update
apt-get install -y unzip libnss3-tools

# download chromedriver
CHROME_DRIVER_VERSION="2.35" #ChromeDriver 2.35 -> Supports Chrome v62-64 ( used from travis)

wget https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
mv chromedriver /usr/bin/chromedriver
chmod +x /usr/bin/chromedriver


# create needed pki for chrome 
mkdir -p /$USER/.pki/nssdb
certutil -d sql:/$USER/.pki/nssdb -N --empty-password

# TODO: check if velum provide a path for getting certificate later on. otherwhise chrome-headless might not work.
#if [ ! -f /etc/pki/trust/anchors/$SERVER.cert ]; then
#  wget http://$SERVER/pub/RHN-ORG-TRUSTED-SSL-CERT -O /etc/pki/trust/anchors/$SERVER.cert
#  update-ca-certificates
#  certutil -d sql:/root/.pki/nssdb -A -t TC -n "velum" -i  /etc/pki/trust/anchors/$SERVER.cert
#fi
