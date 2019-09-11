[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#
#--------------------------------------
#!/bin/bash
# file: wittyPiOn.sh
#
# Start up system at specified time
# Note that wittyPi daemon must be
# running
#
# (C) M.A. O'Neill, Tumbling Dice 2019
#--------------------------------------


#-----------------------------------------------
# Include utilities script in current directory
#-----------------------------------------------

current_dir="`dirname \"$0\"`"
current_dir="`( cd \"$current_dir\" && pwd )`"
if [ -z "$current_dir" ] ; then
  exit 1
fi

. $current_dir/utilities.sh


#-----------------------
# Check if root UID 
#-----------------------

if [ "$(id -u)" != 0 ]; then
  log "ERROR: script must be run with effective root UID"
  exit 1
fi


#------------------------------------
# Check for valid date-time argument
#------------------------------------

if [ "$1" = "" ]; then
	echo ""
	echo "ERROR: date not specified"
	echo ""

	exit -1
else 

	#-------
	# Today
	#-------

	if [ "$1" = "today" ] ; then
		day_name=$(date | awk '{print $1}')

		dateChanged
		if [ "$?" -eq 255 ] ; then
			month_day=$(date | awk '{print $3}')
			month_name=$(date | awk '{print $2}')
		else
			month_day=$(date | awk '{print $2}')
			month_name=$(date | awk '{print $3}')
		fi

		tzone=$(date | awk '{print $5}')
		year=$(date | awk '{print $6}')


	#----------
	# Tomorrow
	#----------

	elif [ "$1" = "tomorrow" ] ; then
		day_name=$(date --date='+1 day' | awk '{print $1}')


		dateChanged
		if [ "$?" -eq 255 ] ; then
			month_day=$(date --date='+1 day' | awk '{print $3}')
			month_name=$(date --date='+1 day' | awk '{print $2}')
		else
			month_day=$(date --date='+1 day' | awk '{print $2}')
			month_name=$(date --date='+1 day' | awk '{print $3}')
		fi

		tzone=$(date --date='+1 day' | awk '{print $5}')
		year=$(date --date='+1 day' | awk '{print $6}')


	#---------------------------------
	# Must be a number (day in month)
	#---------------------------------

	elif [ $1 -lt 31 -a $1 -ge 1 ] ; then


		#---------------------------------------
		# Check number of days in current month
		#---------------------------------------

		lastDay=$(date -d "$(date +%Y-%m-01) -1 day" +"%d %b %Y" | awk '{print $1}')
		if [ $1 gt $lastDay ] ; then

			echo ""
			echo "ERROR: invalid date (must be day in current month)"
			echo ""

			exit -1
		fi

		day_name=$(date --date='$1' | awk '{print $1}')


		dateChanged
		if [ "$?" -eq 255 ] ; then
			month_day=$(date --date='$1' | awk '{print $3}')
			month_name=$(date --date='$1' | awk '{print $2}')
		else
			month_day=$(date --date='$1' | awk '{print $2}')
			month_name=$(date --date='$1' | awk '{print $3}')
		fi

		tzone=$(date --date='$1' | awk '{print $5}')
		year=$(date --date='$1' | awk '{print $6}')


	#--------------
	# Date invalid
	#--------------

	else

		echo ""
		echo "ERROR: invalid date (must be day in current month)"
		echo ""

		exit -1
	fi
fi

if [ "$2" = "" ]; then
	echo ""
	echo "ERROR: time not specified"
	echo ""

	exit -1
fi

if [ "$2" = "" ]; then
	echo ""
	echo "ERROR: time not specified"
	echo ""

	exit -1
fi

local_hour=$(echo $2 | cut -d':' -f 1)
if [ $local_hour -gt 23 -a $local_hour -lt 0 ] ; then
	echo ""
	echo "ERROR: hour must be integer between 0 and 23"
	echo ""

	exit -1
fi

local_minute=$(echo $2 | cut -d':' -f 2)
if [ $local_hour -gt 59 -a $local_hour -lt 0 ] ; then
	echo ""
	echo "ERROR: minute must be integer between 0 and 59"
	echo ""

	exit -1
fi


#------------------------------
# Is startup time in the past?
#------------------------------

dateChanged
if [ "$?" -eq 255 ] ; then
	now_day=$(date | awk '{print $3}')
else
	now_day=$(date | awk '{print $2}')
fi

now_hour=$(date | awk '{print $4}' | cut -d':' -f1 )
now_minute=$(date | awk '{print $4}' | cut -d':' -f2 )

if [ $local_hour -lt $now_hour -a $month_day -le $now_day ] ; then

	echo ""
	echo "ERROR: startup time is in the past (hour)"
	echo ""

	exit -1
elif [ $local_hour -eq $now_hour -a $month_day -le $now_day ] ; then

	if [ $local_minute -lt $now_minute ] ; then

		echo ""
		echo "ERROR: startup time is in the past (minute)"
		echo ""

		exit -1
	fi
fi



#---------------------------------
# Check for wiringPi installation
#---------------------------------

hash gpio 2>/dev/null
if [ $? -ne 0 ]; then
  echo ''
  echo 'ERROR: wiringPi is not installed properly (missing "gpio" command). Quitting...'
  echo ''
  exit
fi


#-------------------------
# Check for wittyPi board
#-------------------------

if ! is_rtc_connected ; then
  echo ''
  log 'ERROR: Witty Pi board is not connected? Quitting...'
  echo ''
  exit
fi


#--------------------------
# Convert localtime to UTC
#--------------------------

when=$(get_utc_date_time $month_day $local_hour $local_minute '00')
IFS=' ' read -r utc_date timestr <<< "$when"
IFS=':' read -r utc_hour utc_minute utc_second <<< "$timestr"


#-------------------------
# Set system startup time
#-------------------------

set_startup_time $utc_date $utc_hour $utc_minute $utc_second 


echo ""
echo "system startup on $day_name $month_day $month_name $year $local_hour:$local_minute $tzone"
echo ""

exit 0
