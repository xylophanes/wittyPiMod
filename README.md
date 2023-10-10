Installation
------------

1. copy contents of this directory to /opt/wittyPi:

   mkdir /opt/wittyPi
   cp wittyPi/* /opt/wittyPi

2. Copy init.sh to /etc/init.d:

   cp int.sh /etc/init.d/wittypi (note rename!!)
   systemctl enable wittypi

Wittypi board should be connected and functioning when system is rebooted.
