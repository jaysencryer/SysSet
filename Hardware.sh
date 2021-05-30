# ! /bin/sh
#
#	Hardware V1
#
#
# V2.6	:- The aim is to sort out all existing complaints which are as
#			follows:
#			config files too complicated
#			errors flash up screen
# V2.59	:-	Added option to install Specialix drivers whether you have a
#			card or not.
#
# SysSet v2.9 comp

# SysSet v3.003 added lsil drivers
#
DIR=$root_dir/$OSVers
[ -e $root_dir/SysSet.var ] && { . $root_dir/SysSet.var; }
[ -e $root_dir/SysSet.fun ] && { . $root_dir/SysSet.fun; }
BannTitle "HARDWARE"
if [ -e $DIR/Hardware.fun ]; then
	. $DIR/Hardware.fun
else
	setcolor $ERROR_COL
	echo "Cannot find Hardware.fun - aborting"
	exit 1
fi
DetectHardware $OSVers
if [ ! $RunMode = CHK ]; then
	Check config hardware.cfg /tmp edit
	if [ -s $g_TEMP/hardware.cfg ]; then
		setcolor $INFO_COL
		echo "Using hardware.cfg."
		. $g_TEMP/hardware.cfg
	else
		setcolor $INFO_COL
		echo "Not using hardware.cfg file."
	fi
fi

################################################################################
#
# ups software
#
################################################################################
Check element FULLINSTALL:hardware:ups $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	if [ -d /usr/lib/powerchute ]; then
		setcolor $INFO_COL
		echo "UPS software already installed."
		SetCheckInf UPS yes
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "UPS software NOT installed."
		SetCheckInf UPS no
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Installing UPS software."
		if [ $hw_UPSPORT ]; then
			InstUPS $hw_UPSPORT
		else
			InstUPS /dev/tty2a
		fi
		SetCheckInf UPS yes
	fi
	ListRemove ups $g_TEMP/elements.list
fi

################################################################################
#
# expansion cards!!
#
################################################################################

################################################################################
#
#  Network cards
#
################################################################################
Check element FULLINSTALL:hardware:expansion:network $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
netcards=`grep -c "Network Adapter" $g_TEMP/HWdetected`
if [ `ifconfig -a | grep "net" | grep -cv "inet"` -lt $netcards ]; then
		if [ ! $RunMode = CHK ]; then
			setcolor $OUTPUT_COL
			echo "Installing Network Card."
			HowManyCards # Dont be fooled - this installs the Network Card!
			# It checks how many there are and then checks to see which are 
			# installed.
			g_reboot=1
			if [ $hw_Masknet0 = "255.255.254.0" ]; then
				cat $SysFiles/hosts >> /etc/hosts
			fi
			SetCheckInf NETWORK yes
		elif [ $RunMode = CHK ]; then
			setcolor $INFO_COL
			echo "You have $netcards Network Adapters in your machine."
			net_inst=`ifconfig -a | grep "net" | grep -cv "inet"`
			echo "$net_inst of these are installed."
			SetCheckInf NETWORK "yes $net_inst of $netcards"
		else
			setcolor $NOT_COL
			echo "Network card NOT installed."
			SetCheckInf NETWORK no
		fi
else
		setcolor $INFO_COL
		echo "Network Card already installed."
		SetCheckInf NETWORK yes
fi
	ListRemove network $g_TEMP/elements.list
fi


ListRemove expansion $g_TEMP/elements.list

Check element testreboot $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	g_reboot=1
	ListRemove testreboot $g_TEMP/elements.list
fi

################################################################################
# Extra Hardware code : use the following template to write your own 
# hardware code
# remember to add element names to SysSet.var HARDWARE in the Elements section
################################################################################
# Check element FULLINSTALL:hardware:#[Add here any other element names]
# element=$?
# if [ $element = 1 ]; then
#	# This means that the part will be run 
#	# Enter detection code here in this form
#	# Check to see if its set up
#	If [ it is ]; then
#		echo "ELEMENT already setup"
#	elif [ ! $RunMode = CHK ]; then # Not just checking 
#		echo "Installing ELEMENT"
#		# Installation code or call to function ( preferred )
#	elif [ $RunMode = CHK ]; then # We are just checking
#		echo "ELEMENT not installed"
#	fi
# fi
ListRemove hardware $g_TEMP/elements.list
if [ $g_reboot = 1 ]; then
	exit 3
else
	exit 0
fi
