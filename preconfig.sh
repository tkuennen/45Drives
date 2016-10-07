#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

status(){
rpm -qa | grep -q $1 || echo "$1 failed to install" >> /tmp/clustercfg/install.log
}

wd=/tmp/clustercfg
if [ ! -d $wd ];then
	mkdir -p $wd
fi
if [ ! -e $wd/install.log ];then
	touch $wd/install.log
else
	rm -f $wd/install.log
	touch $wd/install.log
fi
	
repo=http://www.45drives.com/downloads
zfsrepo=http://download.zfsonlinux.org/epel/zfs-release
epel=https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm

## Install wget & Development tools for current kernel 
rpm -qa | grep -qw kernel-devel-$(uname -r) || yum install kernel-devel $1

## Install EPEL repository
rpm -qa | grep -qw epel || yum install $epel 

## Install gluster repo,main,client,and server packages
rpm -qa | grep -q centos-release-gluster || yum install centos-release-gluster $1
rpm -qa | grep -qw glusterfs-3 || yum install glusterfs $1
rpm -qa | grep -qw glusterfs-fuse || yum install glusterfs-fuse $1
rpm -qa | grep -qw glusterfs-server || yum install glusterfs-server $1

## Install zfs
rpm -qa | grep -qw zfs-release || yum install $zfsrepo$(rpm -E %dist).noarch.rpm $1
gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux 
rpm -qa | grep -qw zfs-dkms || yum install zfs $1
if [ ! -d /etc/rc.modules ];then
	touch /etc/rc.modules
fi
zmod=$(cat /etc/rc.modules | grep "modprobe zfs" | awk 'NR==1')
if [ "$zmod" != "modprobe zfs" ];then
	echo "modprobe zfs" >> /etc/rc.modules
fi
if [ ! -x /etc/rc.modules ];then
	chmod +x /etc/rc.modules
fi

## Install gtools & alias files
if [ -e $wd/gtools.tar.gz ];then
	rm -f $wd/gtools.tar.gz
fi
curl -s -o $wd/gtools.tar.gz $repo/gtools.tar.gz 
tar -zxf $wd/gtools.tar.gz -C $wd
installdir=/setup
if [ ! -d $installdir ];then
        mkdir $installdir
fi
if [ ! -d /etc/zfs ];then
        mkdir /etc/zfs
fi
echo -e "\nExtracting Cluster Configuation Tools to /setup"
cp -r $wd/gtools_v1.1/* $installdir/
cp -r $wd/alias/* /etc/zfs/

## Download and install r750 driver
r750=$(dmesg | grep r750 | awk 'NR==3{print $3}')
if [ -z $r750 ];then
	curl -s -o /$(pwd)/r750_v1.2.7_linux.tar.gz $repo/R750_v1.2.7_linux.tar.gz
	tar -zxf /$(pwd)/r750_v1.2.7_linux.tar.gz -C /$(pwd)/
	./r750-linux-src-v1.2.7-16_08_23.bin
fi

echo -e "All Done...\nVerifying Install..."
status kernel-devel-$(uname -r)
status epel
status centos-release-gluster
status glusterfs-3
status glusterfs-fuse
status glusterfs-server
status zfs-release
status zfs-dkms
state=$(cat $wd/install.log | wc -l)
case $state in
0)
	echo -e "${GREEN}SUCCESS${NC}"
	echo "Reboot before continuing setup"
	;;
*)
	echo -e "${RED}FAILURE${NC}"
	echo -e "Problems during installation: $state"
	cat $wd/install.log
	echo -e "Rerun this script or manually try to install missing packages individually\nNOTE if installing the ZFS packages use \"yum install zfs\" rather than \"yum install zfs-dkms\""
	;;
esac
rm -f $wd/install.log
