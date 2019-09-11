[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#
#--------------------------------------
#!/bin/bash
# file: wittyPiRTC.sh
#
# Show (RTC) date-time
#
# (C) M.A. O'Neill. Tumbling Dice 2019
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
  echo 'ERROR: script must be run with effective root UID'
  exit 1
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


#---------------------------
# Get time from wittyPi RTC
#---------------------------

echo ""
echo ""

now=$(get_rtc_time)
echo "Time now: " $now


#--------------------------------
# Get startup and shutdown times
#--------------------------------

echo ""
echo "--------------------------------------------"


#----------
# Shutdown
#----------

shutdown_time=$(get_local_date_time "$(get_shutdown_time)" )
day_in_month=$(echo $shutdown_time | cut -d' ' -f 1)
time_of_day=$(echo "$shutdown_time" | cut -d' ' -f 2)

day_name=$(date | awk '{print $1}')

dateChanged
if [ "$?" -eq 255 ] ; then
	month_name=$(date | awk '{print $2}')
else
	month_name=$(date | awk '{print $3}')
fi

tzone=$(date | awk '{print $5}')
year=$(date | awk '{print $6}')

if [ "$shutdown_time" != " ::" ]; then
	echo "shutdown time: $day_name $day_in_month $month_name $year $time_of_day $tzone"
else
	echo "shutdown time: notset"
fi


#---------
# Startup
#---------

shutdown_day_in_month=$day_in_month
startup_time=$(get_local_date_time "$(get_startup_time)" ) 
day_in_month=$(echo $startup_time | cut -d' ' -f 1)
time_of_day=$(echo "$startup_time" | cut -d' ' -f 2)


if [ "$startup_time" != " ::" ]; then
	offset=$(("$day_in_month" - "$shutdown_day_in_month"))
	day_name=$(date --date="+ $offset day" | awk '{print $1}')


	dateChanged
	if [ "$?" -eq 255 ] ; then
		month_name=$(date | awk '{print $2}')
	else
		month_name=$(date | awk '{print $3}')
	fi

	tzone=$(date | awk '{print $5}')
	year=$(date | awk '{print $6}')

	echo "startup  time: $day_name $day_in_month $month_name $year $time_of_day $tzone"
else
	echo "startup  time: notset"
fi

echo "--------------------------------------------"
echo ""

exit 0

