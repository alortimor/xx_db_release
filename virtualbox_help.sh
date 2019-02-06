# ensure that the linux username is included in the sudoers file
$ cd /etc
$ sudo vi sudoers

# add a line similar to root, but with linux username

root	 ALL=(ALL:ALL) ALL
username ALL=(ALL:ALL) ALL
# specific sudo privileges can be set as well

# or alternatively, as root, use the following command:
$ usermod -aG sudo username

pl@pl1:~$ ifconfig
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::47ff:ed21:3b98:5f4  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:ad:63:ee  txqueuelen 1000  (Ethernet)
        RX packets 1470  bytes 1888341 (1.8 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 863  bytes 63060 (63.0 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

PC-1	enp0s8	192.168.1.1/24
enp0s3	DHCP
PC-2	enp0s8	192.168.2.1/24
enp0s3	DHCP
PC-3	enp0s8	192.168.3.1/24
enp0s3	DHCP
Router1	enp0s8	192.168.1.254/24
enp0s9	192.168.100.1/24
enp0s10	192.168.101.2/24
enp0s3	DHCP
Router2	enp0s8	192.168.2.254/24
enp0s9	192.168.100.2/24
enp0s10	192.168.102.2/24
enp0s3	DHCP
Router3	enp0s8	192.168.3.254/24
enp0s9	192.168.101.1/24
enp0s10	192.168.102.1/24
enp0s3	DHCP

# to start and stop ssh from command line
$ sudo /etc/init.d/ssh start
$ sudo /etc/init.d/ssh stop

# If the daemon isn't running, then run the following to install ssh
$ mkdir ~/.ssh
$ chmod 700 ~/.ssh
$ sudo apt-get install openssh-server
$ sudo apt-get install ssh
$ sudo /etc/init.d/ssh start

# thereafter
# to ensure that ssh is started at bootup, run the following:
$ sudo update-rc.d ssh defaults

# to ensure that an adapter is available with a fixed ip, include
# the following in  /etc/network/interfaces
$ sudo vi /etc/network/interfaces
## append the following 4 lines to the bottom of the interfaces file 
# do not modify or remove any of the other lines in the file.
auto enp0s8
iface enp0s8 inet static
   address 192.168.1.1
   netmask 255.255.255.0
up route add -net 192.168.0.0/16 gw 192.168.1.254 dev enp0s8

# to restart and networking services after any changes
$ sudo /etc/init.d/networking restart

# guest additions. Guest additions allow for:
# 1. copy and paste between host and vm
# 2. shared folder
# 3. seamless mouse pointer movement

# Installing guest additions:
# from Devices menu, select "Install Gues Additions CD Image..."
# at the command line, run;
$ sudo apt-get update
$ sudo apt-get install dkms
$ sudo usermod -G vboxsf -a username


