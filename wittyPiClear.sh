[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#
#--------------------------------------
#!/bin/bash
# file: wittyPiClear.sh
#
# CLear shutdown/startup 
# Note that wittyPi daemon must be
# running
#
# (C) M.A. O'Neill, Tumbling Dice 2019
#--------------------------------------


#-----------------------
# Check if root UID 
#-----------------------

if [ "$(id -u)" != 0 ]; then
	echo 'ERROR: script must be run with effective root UID'
	exit 1
fi


#-----------------------------------------------
# Include utilities script in current directory
#-----------------------------------------------

current_dir="`dirname \"$0\"`"
current_dir="`( cd \"$current_dir\" && pwd )`"
if [ -z "$current_dir" ] ; then
	exit 1
fi

. $current_dir/utilities.sh


#---------------------------------
# Check for wiringPi installation
#---------------------------------

hash gpio 2>/dev/null
if [ $? -ne 0 ]; then
	echo ''
	echo 'ERROR: wiringPi not installed properly (missing "gpio" command). Quitting'
	echo ''
	exit
fi


#-------------------------
# Check for wittyPi board
#-------------------------

if ! is_rtc_connected ; then
	echo ''
	log 'ERROR: Witty Pi board is not connected? Quitting'
	echo ''

	exit
fi


#---------------------------------
# Clear startup and shutdown times 
#----------------------------------

clear_startup_time
clear_shutdown_time

echo ""
echo "startup and shutdown times cleared"
echo ""

exit 0

