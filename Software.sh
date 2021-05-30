# ! /bin/sh
#
#	Software V1
#
#
# OpenServer 6 version  21/10/2005
# SysSet v3.030
#

[ -e $root_dir/SysSet.var ] && { . $root_dir/SysSet.var; }
[ -e $root_dir/SysSet.fun ] && { . $root_dir/SysSet.fun; }
BannTitle "SOFTWARE"
if [ -e $root_dir/SYS5/Software.fun ]; then
	. $root_dir/SYS5/Software.fun
else
	setcolor $ERROR_COL
	echo "Error, cannot find Software.fun - aborting"
	exit 1
fi
if [ ! $RunMode = CHK ]; then
	Check config software.cfg /tmp edit
	if [ -s $g_TEMP/software.cfg ]; then
		. $g_TEMP/software.cfg
	else
	setcolor $ERROR_COL
		echo "There is an error with software.cfg file - aborting"
		exit 1
	fi
fi
# Sophos
Check element FULLINSTALL:software:sophos $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	if [ -f /usr/sophos/.version ]; then
		soph_verex=`cat /usr/sophos/.version`
		else
		soph_verex=0
	fi
	soph_vernew=`cat $root_dir/Sophos/version`
	if [ -d /usr/sophos -a $soph_verex -ge $soph_vernew ]; then	
		setcolor $INFO_COL
		echo "Sophos v.$soph_verex already installed."
		SetCheckInf SOPHOS yes
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "Sophos v.$soph_vernew NOT installed."
		SetCheckInf SOPHOS no
	elif [ ! $RunMode = CHK ]; then
		if [ $RunMode = INT ]; then
			GetAns "Do you wish to install Sophos v.$soph_vernew" y:Y:yes:YES n:N:no:NO	
			answer=$?
			else
				if [ $sophos_setup = yes ]; then
					answer=1 # force it for Auto
				else
					answer=0
				fi
		fi
		if [ $answer = 1 ]; then
			setcolor $OUTPUT_COL
			echo "Installing Sophos v.`cat $root_dir/Sophos/version`"
			groupadd -g 2000 sweep >> $g_TEMP/software.log
			useradd -c "Sophos Anti-Virus Sweep No Login" -d /usr/sophos -g sweep -s /bin/false -x "{administrativeLockApplied {1}}" sweep >> $g_TEMP/software.log
			passwd -d sweep >> $g_TEMP/software.log
			cd $root_dir/Sophos
			find . -depth -print | cpio -pudv / >> $g_TEMP/software.log 
			sh /tmp/execute >> $g_TEMP/software.log 2>&1
			SetCheckInf SOPHOS yes
		else
			setcolor $NOT_COL
			echo "Not Installing Sophos v.`cat $rootdir/Sophos/version`" 
			SetCheckInf SOPHOS no
		fi
	fi
	ListRemove sophos $g_TEMP/elements.list
fi
################################################################################
# Extra Software code : use the following template to write your own 
# hardware code
# remember to add element names to SysSet.var SOFTWARE in the Elements section
################################################################################
# Check element FULLINSTALL:software:#[Add here any other element names]
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

ListRemove software $g_TEMP/elements.list

if [ $g_reboot = 1 ]; then
	exit 3
else
	exit 0
fi
