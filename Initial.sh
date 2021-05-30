# ! /bin/sh
#
#
# Initial set up script.. for each element we will check whether
# it needs to be done.. and if so do it!
#
#

DIR=$root_dir/SYS5
[ -e $root_dir/SysSet.var ] && { . $root_dir/SysSet.var; }
[ -e $root_dir/SysSet.fun ] && { . $root_dir/SysSet.fun; }

if [ -e $DIR/Init.fun ]; then 
	. $DIR/Init.fun
else
	echo "Cannot find the Init.fun - aborting"
	exit 1
fi

BannTitle "INITIAL SETUP"
g_reboot=0


################################################################################
#
# SYSTEM DEFAULTS
#
# these are such small parts there is no point offering the option
# to turn them off or on.. repline has its own checking so no need to
# Check () either
#
################################################################################

# /etc/default/msdos
repline /etc/default/msdos "A=\/dev\/install" "A=\/dev\/fd0135ds18"

# /etc/default/lpd
repline /etc/default/lpd "BANNERS=1" "BANNERS=0"

################################################################################
#
# Calserver fix
#
################################################################################
Check element FULLINSTALL:initial:calserver $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	Check count "IQMFILE" /etc/rc2.d/P95calserver 3
	result=$?
	if [ $result = 1 ]; then
		setcolor $INFO_COL
		echo "Calserver Fix already performed.."
		SetCheckInf CALSERVER yes 
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Performing Calserver Language fix.."
		CalFix `uname -v`
		SetCheckInf CALSERVER yes 
	elif [ $result = 0 -a $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "Calserver Language fix has not been performed.."
		SetCheckInf CALSERVER no 
	fi
	ListRemove calserver $g_TEMP/elements.list
fi

################################################################################
#
# Environment Settings
#
################################################################################
Check element FULLINSTALL:initial:env $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	#
	# Set prompt in /.profile
	#
	Check count "PS1" /.profile 2
	result=$?
	if [ $result = 1 ]; then
		# 
		# set VIM env variable in /.profile
		#
		Check count "VIM" /.profile 2
		result=$?
		if [ $result = 0 ]; then
			echo "VIM=/usr/vim/share/vim" >> /.profile
			echo "export VIM" >> /.profile	
		fi
		setcolor $INFO_COL
		echo "/.profile already setup"
		SetCheckInf ENV yes 
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Setting up /.profile ."
		cp /.profile /.profile.safe
		cat $SysFiles/prompt_profile >> /.profile
		if [ ! -e /.INFO ]; then
			echo -n "########################################" > /.INFO
			echo "########################################" >> /.INFO
			echo "`date`" >> /.INFO
			echo "System installed using SysSet $SYS_VERSION" >> /.INFO
			echo -n "########################################" >> /.INFO
			echo "########################################" >> /.INFO
		fi
		SetCheckInf ENV yes 
	else
		setcolor $NOT_COL
		echo "/.profile NOT setup."
		SetCheckInf ENV no 
	fi

	#
	# Set up /etc/issue
	#
	Check count "MICROTEST" /etc/issue 0
	result=$?
	if [ $result = 0 ]; then
		setcolor $INFO_COL
		echo "/etc/issue already setup"
		SetCheckInf ENV yes 
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "/etc/issue NOT setup"
		SetCheckInf ENV no 
	else
		setcolor $OUTPUT_COL
		echo "Setting up /etc/issue file."
		cp /etc/issue /etc/issue.safe
		cp $SysFiles/issue /etc/issue
		cp /etc/issue /etc/telnet.issue
		chmod 777 /etc/issue
		SetCheckInf ENV yes 
	fi

	#
	# This alters /etc/rc to run SysSet on next boot
	# it is not a permanent change
	#
	Check count "SysSet" /etc/rc 0
	result=$?
	if [ $result = 0 ]; then
		setcolor $INFO_COL
		echo "/etc/rc already adjusted"
		SetCheckInf ENV yes 
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "/etc/rc NOT adjusted"
		SetCheckInf ENV no
	else
		setcolor $OUTPUT_COL
		echo "Adjusting /etc/rc"
		cp /etc/rc /etc/rc.safe
		cat $root_dir/Config/rc >> /etc/rc
		chmod 777 /etc/rc
		SetCheckInf ENV yes
	fi

	ListRemove env $g_TEMP/elements.list
fi


################################################################################
#
#	RAIDUTILS
#
################################################################################
Check element FULLINSTALL:initial:raidutils $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	# only need this if it's an adaptec raid controller
	SCSI_adapter=`CheckRaid`
	if [ $SCSI_adapter = "dpti" ]; then
		if [ -e /usr/dpt/raidutil.mnu ]; then
			setcolor $INFO_COL
			echo "Raid utilities already installed."
			SetCheckInf RAID yes
		elif [ $RunMode = CHK ]; then
			setcolor $NOT_COL
			echo "Raid utilities not installed."
			SetCheckInf RAID no
		else
			setcolor $OUTPUT_COL
			echo "Installing Raid utilities."
			# TO DO
			UnpackFiles adaptec	
			[ $? = 1 ] && { exit 0; }
			sh $ProgFiles/adaptec/install/INSTALL << end_inst
y
end_inst
			
		fi
	else
		setcolor $NOT_COL
		echo "You do not have an Adaptec Raid controller"
	fi
	ListRemove raidutils $g_TEMP/elements.list
fi




################################################################################
#
# Create clean up files 
#
################################################################################

echo /etc/conf/pack.d/fd/space.org > $g_TEMP/f2clean.log
echo /etc/conf/pack.d/fd/space.c.old >> $g_TEMP/f2clean.log
echo /etc/default/boot.old >> $g_TEMP/f2clean.log
echo /etc/default/msdos.old >> $g_TEMP/f2clean.log
echo /etc/default/lpd.old >> $g_TEMP/f2clean.log
echo /etc/default/lang.old >> $g_TEMP/f2clean.log
echo /etc/rc2.d/p95calserver.old >> $g_TEMP/f2clean.log
echo /etc/conf/pack.d/kernel/space.safe >> $g_TEMP/f2clean.log
echo /etc/conf/pack.d/kernel/space.old >> $g_TEMP/f2clean.log
echo /.profile.safe >> $g_TEMP/f2clean.log
echo /etc/issue.safe >> $g_TEMP/f2clean.log

ListRemove initial $g_TEMP/elements.list

#echo "Initial setup complete."
if [ $g_reboot = 1 ]; then
	exit 3
else
	exit 0
fi
