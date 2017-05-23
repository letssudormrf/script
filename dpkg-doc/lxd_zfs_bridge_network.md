LXD, ZFS and bridged networking on Ubuntu 16.04 LTS+
------

### For ubuntu 16.04 LTS to installing the lxd container.

    sudo apt-get install snapd zfsutils-linux bridge-utils

### Install the LXD snap

    sudo apt remove --purge lxd lxd-client
    sudo snap install lxd
    sudo lxd init
    
    Name of the storage backend to use (dir or zfs) [default=zfs]: 
    Create a new ZFS pool (yes/no) [default=yes]? 
    Name of the new ZFS pool [default=lxd]: 
    Would you like to use an existing block device (yes/no) [default=no]? 
    Size in GB of the new loop device (1GB minimum) [default=43]: 
    Would you like LXD to be available over the network (yes/no) [default=no]? 
    Would you like stale cached images to be updated automatically (yes/no) [default=yes]? 
    Would you like to create a new network bridge (yes/no) [default=yes] no? 
    LXD has been successfully configured.

### Setting up the bridge

    sudo vim /etc/network/interfaces

    # The loopback network interface
    auto lo
    iface lo inet loopback

    # The primary network interface
    auto br0
    iface br0 inet dhcp
	    bridge_ports eth0

    iface eth0 inet manual 

### Edit the default profile for setting the containter eth0 to bridge br0

    lxc network attach-profile br0 default eth0

### Edit the default profile for cannelling the containter eth0 to bridge lxdbr0

    lxc network detach-profile lxdbr0 default eth0

### Increasing file and inode limits

    sudo vim /etc/sysctl.conf
 
    fs.inotify.max_queued_events = 1048576
    fs.inotify.max_user_instances = 1048576
    fs.inotify.max_user_watches = 1048576

    sudo vim /etc/security/limits.conf
    
    * soft nofile 100000
    * hard nofile 100000

### Configure the access permission for the network

    lxc config set core.https_address [::]
    lxc config set core.trust_password some-secret-string

