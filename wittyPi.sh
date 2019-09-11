[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#
#-------------------------------------------------------------
#!/bin/bash
# file: wittyPi.sh
#
# Run this application to interactly configure your Witty Pi
#-------------------------------------------------------------


#----------------
# check for sudo 
#----------------

if [ "$(id -u)" != 0 ]; then
	echo 'ERROR: this script must be run as root (or via sudo)'
	exit 1
fi

echo ''
echo '================================================================================'
echo '|                                                                              |'
echo '|   Witty Pi - Realtime Clock + Power Management for Raspberry Pi              |'
echo '|                                                                              |'
echo '|                   < Version 2.56a >     by UUGear s.r.o.                     |'
echo '|                                                                              |'
echo '================================================================================'
echo ''

#--------------------------------------------
# include utilities script in same directory
#--------------------------------------------

my_dir="`dirname \"$0\"`"
my_dir="`( cd \"$my_dir\" && pwd )`"
if [ -z "$my_dir" ] ; then
	exit 1
fi
. $my_dir/utilities.sh


#---------------------
# Check for wiriingPi
#---------------------

hash gpio 2>/dev/null
if [ $? -ne 0 ]; then
	echo ''
	echo 'ERROR: wiringPi is not installed properly (missing "gpio" command). Quitting...'
	echo ''
	exit
fi


#---------------
# Check for RTC
#---------------

if ! is_rtc_connected ; then
	echo ''
	log 'ERROR: RTC board is not connected? Quitting...'
	echo ''
	exit
fi


#---------------------
# interactive actions
#---------------------
#---------------------------------
# Synchronise RTC and system time
#---------------------------------

synchronize_time()
{
	log '  Running syncTime.sh'
	. "$my_dir/syncTime.sh"
}


#-------------------------------------------------
# Schedule system startup (wake from sleep state)
#-------------------------------------------------

schedule_startup()
{
	local startup_time=$(get_local_date_time "$(get_startup_time)")
	local size=${#startup_time}

	if [ $size == '3' ]; then
		echo '  Auto startup time is not set yet.'
	else
		echo "  Auto startup time is currently set to \"$startup_time\""
	fi

	if [ -f "$my_dir/schedule.wpi" ]; then
		echo 'WARNING: manual schedule may disturb running schedule script'
	fi

	read -p 'When do you want system to restart? (dd HH:MM:SS, ?? as wildcard) ' when
	if [[ $when =~ ^[0-3\?][0-9\?][[:space:]][0-2\?][0-9\?]:[0-5\?][0-9\?]:[0-5\?][0-9\?]$ ]]; then

		IFS=' ' read -r date timestr <<< "$when"
		IFS=':' read -r hour minute second <<< "$timestr"
		wildcard='??'

		if [ $date != $wildcard ] && ([ $((10#$date>31)) == '1' ] || [ $((10#$date<1)) == '1' ]); then
			echo '  Day value should be 01~31.'
		elif [ $hour != $wildcard ] && [ $((10#$hour>23)) == '1' ]; then
			echo '  Hour value should be 00~23.'
		else
			local updated='0'
	
			if [ $hour == '??' ] && [ $date != '??' ]; then
				date='??'
				updated='1'
			fi

			if [ $minute == '??' ] && ([ $hour != '??' ] || [ $date != '??' ]); then
				hour='??'
				date='??'
				updated='1'
			fi

			if [ $second == '??' ]; then
				second='00'
				updated='1'
			fi

			if [ $updated == '1' ]; then
				when="$date $hour:$minute:$second"
				echo "... unsupported pattern, but I can do \"$when\" for you..."
			fi

			log " Setting startup time to \"$when\""
			when=$(get_utc_date_time $date $hour $minute $second)

			IFS=' ' read -r date timestr <<< "$when"
			IFS=':' read -r hour minute second <<< "$timestr"
			set_startup_time $date $hour $minute $second

			log '  Done :-)'
		fi
	else
		echo "ERROR: input not recognised"
	fi
}


#----------------------------------------------
# Schedule system shutdown (enter sleep state)
#----------------------------------------------

schedule_shutdown()
{
	local off_time=$(get_local_date_time "$(get_shutdown_time)")
	local size=${#off_time}

	if [ $size == '3' ]; then
		echo  ' Auto shutdown time is not set yet.'
	else
		echo -e " Auto shutdown time is currently set to \"$off_time\b\b\b\"  "
	fi

	if [ -f "$my_dir/schedule.wpi" ]; then
		echo '[WARNING] Your manual schedule may disturb the schedule script running!'
	fi

	read -p '  When do you want your Raspberry Pi to auto shutdown? (dd HH:MM, ?? as wildcard) ' when
	if [[ $when =~ ^[0-3\?][0-9\?][[:space:]][0-2\?][0-9\?]:[0-5\?][0-9\?]$ ]]; then
		IFS=' ' read -r date timestr <<< "$when"
		IFS=':' read -r hour minute <<< "$timestr"

		wildcard='??'

		if [ $date != $wildcard ] && ([ $((10#$date>31)) == '1' ] || [ $((10#$date<1)) == '1' ]); then
			echo 'Day value should be 01~31.'
		elif [ $hour != $wildcard ] && [ $((10#$hour>23)) == '1' ]; then
			echo 'Hour value should be 00~23.'
		else
			local updated='0'

			if [ $hour == '??' ] && [ $date != '??' ]; then
				date='??'
				updated='1'
			fi

			if [ $minute == '??' ] && ([ $hour != '??' ] || [ $date != '??' ]); then
				hour='??'
				date='??'
				updated='1'
			fi

			if [ $updated == '1' ]; then
				when="$date $hour:$minute"
				echo "...not supported pattern, but I can do \"$when\" for you..."
			fi

			log "  Seting shutdown time to \"$when\""

			when=$(get_utc_date_time $date $hour $minute '00')

			IFS=' ' read -r date timestr <<< "$when"
			IFS=':' read -r hour minute second <<< "$timestr"
			set_shutdown_time $date $hour $minute

			log '  Done :-)'
		fi
	else
		echo "ERROR: input not recognised"
	fi
}


#----------------------------------
# Choose scehdule script to be run
#----------------------------------

choose_schedule_script()
{
	local files=($my_dir/schedules/*.wpi)
	local count=${#files[@]}
	echo " $count schedule scripts in the \"schedules\" directory:"

	for (( i=0; i<$count; i++ ));
  	do
		echo "  [$(($i+1))] ${files[$i]##*/}"
	done

	read -p " Which schedule script do you want to use? (1~$count) " index
	if [[ $index =~ [0-9]+ ]] && [ $(($index >= 1)) == '1' ] && [ $(($index <= $count)) == '1' ] ; then
		local script=${files[$((index-1))]};
		log "  Copying \"${script##*/}\" to \"schedule.wpi\"..."
		cp ${script} "$my_dir/schedule.wpi"

		log ' Running script'
		. "$my_dir/runScript.sh" | tee -a "$my_dir/schedule.log"
		log '  Done :-)'
	else
		echo "ERROR \"$index\" is not a good choice, need number between 1 and $count"
	fi
}


#---------------------------------
# Clear (scheduled) start up time
#---------------------------------

reset_startup_time()
{
	log 'Clearing auto startup time' '-n'
	clear_startup_time
	log 'done :-)'
}


#---------------------------------
# Clear (scheduled) shutdown time
#---------------------------------

reset_shutdown_time()
{
	log 'Clearing auto shutdown time' '-n'
	clear_shutdown_time
	log ' done :-)'
}


#----------------------------------
# Delete (current) schedule script
#----------------------------------

delete_schedule_script()
{
	log 'Deleting "schedule.wpi"' '-n'
	if [ -f "$my_dir/schedule.wpi" ]; then
		rm "$my_dir/schedule.wpi"
		log 'done :-)'
	else
		log 'file does not exist'
	fi
}


#--------------------
# Force reset of RTC
#--------------------

reset_all()
{
	reset_startup_time
	reset_shutdown_time
	delete_schedule_script
}


#--------------------
# Data rest sub-menu
#--------------------

reset_data()
{
	echo ''
	echo 'Choose action:'
	echo ''
	echo '  [1] Clear scheduled startup time'
	echo '  [2] Clear scheduled shutdown time'
	echo '  [3] Stop using schedule script'
	echo '  [4] Perform all actions above'
	echo ''
	read -p "Which action to perform? (1~4) " action


	case $action in
		[1]* ) reset_startup_time;;
		[2]* ) reset_shutdown_time;;
		[3]* ) delete_schedule_script;;
		[4]* ) reset_all;;
		* ) echo 'Please choose from 1 to 4';;
	esac
}

#-----------
# Main menu
#-----------

while true; do

	#--------------------
	# output temperature
	#--------------------

	temperature='>>> Current temperature: '
	temperature+="$(get_temperature)"
	echo "$temperature"


	#--------------------
	# output system time
	#--------------------

	systime='>>> System time is: '
	systime+="$(get_sys_time)"
	echo "$systime"


	#-----------------
	# output RTC time
	#-----------------

	rtctime='>>> RTC time is:    '
	rtctime+="$(get_rtc_time)"
	echo "$rtctime"

	#------------------------
	# let user choose action
	#------------------------

	echo ''
	echo 'Choose action:'
	echo ''
	echo '  1. Write system time to RTC'
	echo '  2. Write RTC time to system'
	echo '  3. Synchronize time'
	echo -n '  4. Schedule next shutdown'

	shutdown_time=$(get_local_date_time "$(get_shutdown_time)")
	if [ ${#shutdown_time} == '3' ]; then
		echo ''
	else
		echo " [$shutdown_time]";
	fi

	echo -n '  5. Schedule next startup'
	startup_time=$(get_local_date_time "$(get_startup_time)")

	if [ ${#startup_time} == '3' ]; then
		echo ''
	else
		echo "  [$startup_time]";
	fi

	echo -n '  6. Choose schedule script'
	if [ -f "$my_dir/schedule.wpi" ]; then
		echo ' [in use]'
	else
		echo ''
	fi

	echo '  7. Reset RTC'
	echo '  8. Exit'
	echo ''

	read -p 'What do you want to do? (1~8) ' action

	case $action in
		[1]* ) system_to_rtc;;
		[2]* ) rtc_to_system;;
		[3]* ) synchronize_time;;
		[4]* ) schedule_shutdown;;
		[5]* ) schedule_startup;;
		[6]* ) choose_schedule_script;;
		[7]* ) reset_data;;
		[8]* ) exit;;
		 * ) echo 'Please choose from 1 to 8';;
	esac

	echo ''
	echo '================================================================================'
done

exit 0
