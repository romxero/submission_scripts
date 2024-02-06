Bootstrap: docker
From: ubuntu:16.04

%post

#we need https://github.com/muquit/grabc
#we want to use https://github.com/autokey/autokey

apt-get -ymq update
apt-get -y install firefox python3 python3-pip wget curl git python3-dbus python3-pyinotify \
python3-xlib wmctrl python3-packaging autokey-gtk grabc

##grab dependencies
#cd /tmp
#wget https://github.com/autokey/autokey/releases/download/v0.96.0/autokey-common_0.96.0_all.deb
#wget https://github.com/autokey/autokey/releases/download/v0.96.0/autokey-gtk_0.96.0_all.deb
#wget https://github.com/muquit/grabc/releases/download/v1.0.2/grabc_1.0.2-1_amd64.deb

#dpkg -i autokey-common_0.96.0_all.deb
#dpkg -i autokey-gtk_0.96.0_all.deb
#dpkg -i grabc_1.0.2-1_amd64.deb

%environment


%runscript

