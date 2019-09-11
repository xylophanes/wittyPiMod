#!/bin/bash
#
#-------------------------------------------------
# file: syncTime.sh
#
# This script syncronizes system and RTC time
#-------------------------------------------------

#-----------------------
# check if sudo is used
#-----------------------

if [ "$(id -u)" != 0 ]; then
	echo 'ERROR: this script must be run with effective root UUID'
	exit 1
fi


#--------------------------------
# delay if first argument exists
#--------------------------------

if [ ! -z "$1" ]; then
	sleep $1
fi


#--------------------------------------------
# include utilities script in same directory
#--------------------------------------------

my_dir="`dirname \"$0\"`"
my_dir="`( cd \"$my_dir\" && pwd )`"
if [ -z "$my_dir" ] ; then
	exit 1
fi
. $my_dir/utilities.sh


#-------------------------
# is RTC board connected?
#-------------------------

log 'Synchronizing RTC and system time'


#--------------
# get RTC time
#--------------

rtctime="$(get_rtc_time)"
echo RTC time is $rtctime


#----------------------------------------------
# if RTC time is OK, write RTC time to system 
#----------------------------------------------

if [[ $rtctime != *"1999"* ]] && [[ $rtctime != *"2000"* ]]; then
	rtc_to_system
fi


#---------------------------------------
# wait a moment for Internet connection
#---------------------------------------

sleep 10

if $(has_internet) ; then

	#--------------------------
	# new time from NTP server
	#--------------------------

	log 'Internet detected, apply NTP time to system and Witty Pi'
	force_ntp_update
	system_to_rtc
else

	#-----------------
	# get system year
	#-----------------

	sysyear="$(date +%Y)"
	if [[ $rtctime == *"1999"* ]] || [[ $rtctime == *"2000"* ]]; then


		#-----------------------------------------
		# This is the first time RTC has been set
		#-----------------------------------------

		log 'RTC time has not been set previously'
		if [[ $sysyear != *"1969"* ]] && [[ $sysyear != *"1970"* ]]; then


			#---------------------
			# System time is good
			#---------------------

			system_to_rtc
		else
			log 'Neither system nor Witty Pi has correct time'
		fi
  	fi
fi
