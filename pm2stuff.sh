#! /bin/sh
# pm2stuff.sh

# V1 - this installs mtools, lynx and the shutdown login.
#
# 31/7/2002 - changed position of sdown to $g_TEMP/Files/sdown

# SysSet v2.9 comp

[ -e $root_dir/SysSet.var ] && { . $root_dir/SysSet.var; }
[ -e $root_dir/SysSet.fun ] && { . $root_dir/SysSet.fun; }
BannTitle "EXTRAS"
Check element FULLINSTALL:extra:mtools:pm2 $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	Check custom SKUNK98:Mtools
	is_installed=$?
	if [ $is_installed = 1 ]; then
		setcolor $INFO_COL
		echo "Mtools utility already installed." 
		SetCheckInf MTOOLS yes
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Installing Mtools."
		UnpackFiles mtools
		CustomInst software SKUNK98:Mtools $ProgFiles/mtools
		g_reboot=1
		SetCheckInf MTOOLS yes
	elif [ $is_installed = 3 ]; then
		setcolor $ERROR_COL
		echo "Custom may be running on another screen, or you are unable to use it."
		setcolor $INST_COL
		echo "Please check and try again."
		exit 1
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "Mtools utility NOT installed."
		SetCheckInf MTOOLS no
	fi
	ListRemove mtools $g_TEMP/elements.list
fi


Check element FULLINSTALL:extra:lynx:pm2 $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	Check custom SKUNK98:Lynx
	is_installed=$?
	if [ $is_installed = 1 ]; then
		setcolor $INFO_COL
		echo "Lynx utility already installed." 
		SetCheckInf LYNX yes
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Installing Lynx."
		UnpackFiles Lynx
		CustomInst software SKUNK98:Lynx $ProgFiles/Lynx
		g_reboot=1
		SetCheckInf LYNX yes
	elif [ $is_installed = 3 ]; then
		setcolor $ERROR_COL
		echo "Custom may be running on another screen, or you are unable to use it."
		setcolor $INST_COL
		echo "Please check and try again."
		exit 1
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "Lynx NOT installed."
		SetCheckInf LYNX no
	fi
	ListRemove lynx $g_TEMP/elements.list
fi

Check element FULLINSTALL:extra:shutdown:pm2 $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	if [ -f /etc/sdown ]; then
		setcolor $INFO_COL
		echo "Shutdown login already configured."
		SetCheckInf SHUTDOWN yes
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Creating shutdown login account and programs."
		cp $SysFiles/sdown /etc/sdown
		chmod 777 /etc/sdown
		echo "shutdown:x:0:0:Shut this computer down:/etc:/etc/sdown" >> /etc/passwd
		authck -a -y >> $g_LOGFILE
		authck -a -y >> $g_LOGFILE
		authck -a -y >> $g_LOGFILE
		passwd -d shutdown >> $g_LOGFILE
		SetCheckInf SHUTDOWN yes
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "Shutdown login is not configured."
		SetCheckInf SHUTDOWN no
	fi	
	ListRemove shutdown $g_TEMP/elements.list
fi


Check element FULLINSTALL:pm2:xmlget $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	if [ -f /usr/bin/xmlget ]; then
		setcolor $INFO_COL
		echo "xmlget already installed"
		SetCheckInf XMLGET yes
	elif [ $RunMode = "CHK" ]; then
		setcolor $NOT_COL
		echo "xmlget NOT installed"
		SetCheckInf XMLGET no
	else
		setcolor $OUTPUT_COL
		echo "Installing xmlget program"
		cp $SysFiles/xmlget /usr/bin/xmlget
		chmod 777 /usr/bin/xmlget
		chown bin:bin /usr/bin/xmlget
		SetCheckInf XMLGET yes
	fi
fi	


if [ $g_reboot = 1 ]; then
	exit 3
else
	exit 0
fi
