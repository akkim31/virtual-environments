#!/bin/sh
source ~/utils/utils.sh

echo "Installing Python Tooling"

echo "Brew Installing Python 3"
# Workaround to have both 3.8 & 3.9(which required by some brew formulas) in the system, but only 3.8 is linked
/usr/local/bin/brew install python@3.8
/usr/local/bin/brew install python@3.9
/usr/local/bin/brew unlink python@3.9
/usr/local/bin/brew unlink python@3.8
/usr/local/bin/brew link python@3.8

echo "Install pip for Python 2"
# Set permissions to install pip modules in the main packages directory
sudo chmod -R 777 /Library/Python/2.7
sudo chmod -R 777 /System/Library/Frameworks/Python.framework/Versions/2.7
# Create symlink for backwards compatibility
ln -s /usr/bin/python /usr/local/bin/python
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
# Workaround for High Sierra pip, since it installs into /usr/bin. On the modern macOSs pip installation directory is /usr/local/bin
if ! is_HighSierra; then
    python get-pip.py
else
    sudo chmod 777 /usr/bin
    python get-pip.py
    ln -s /usr/bin/pip /usr/local/bin/pip
    sudo chmod 755 /usr/bin
fi
