#!/bin/bash 

# this is a cheap zfs deployment stub. 

#########################################################################################################################
# Install and configure ZFS
dnf install -y https://zfsonlinux.org/epel/zfs-release-2-3$(rpm --eval "%{dist}").noarch.rpm
dnf config-manager --disable zfs
dnf config-manager --enable zfs-kmod
dnf install -y zfs
modprobe -v zfs

# Create pool from SATA SSD drives.
zpool create -o ashift=12 -f datapool raidz2 pci-0000:00:17.0-ata-{1..8}

# Set defaults for pool.
zfs set compression=zstd datapool
zfs set atime=off datapool
zfs set xattr=sa datapool
zfs set acltype=posixacl datapool

# Create filesystems.
# HOME
zfs create -o mountpoint=/home datapool/home

# Exported filesystems.
zfs create datapool/exports
zfs create datapool/exports/local
zfs create -o mountpoint=/local/scratch datapool/exports/local/scratch
zfs create -o mountpoint=/local/data datapool/exports/local/data

# Let people have access to the local space.
chmod 1777 /local/data /local/scratch

# NFS server exports. To be expanded to allow sharing between workstations.
cat > /etc/exports << EOF
/datapool/exports  127.0.0.1/8(fsid=1,rw,crossmnt,no_subtree_check,no_root_squash)
EOF

# Services
systemctl enable nfs-server
systemctl restart nfs-server


# Set mountpoints until an NFS version of this is available.
zfs set mountpoint=/hpc/sbgrid datapool/exports/software/sbgrid/x86_64
zfs set mountpoint=/hpc/apps datapool/exports/software/apps/x86_64
zfs set mountpoint=/hpc/user_apps datapool/exports/software/user_apps/x86_64
zfs set mountpoint=/hpc/modules datapool/exports/software/modules

systemctl daemon-reload
systemctl restart remote-fs.target local-fs.target