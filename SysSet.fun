#! /bin/sh


# 24/10/2005
# New versions of the following function for OpenServer 6.0.0
#
# including :- VersionDetect,  
#
#
#

MAX_FUN_LOOP=10
################################################################################
#
#	VersionDetect
#		detects the version of OS you are using. I mean DUH!!
#
################################################################################
VersionDetect () {
# Simple at the moment - but any aditional Version detection can be added here.
	if [ `uname -s` = "SCO_SV" ]; then # this is open server 5!
	# well actually - OpenServer 6 says this too!
	# so..
		if [ `uname -v` = "6.0.0" ]; then
			echo "SYS5"
		else
			setcolor $ERROR_COL
			echo "This version of SysSet is for OpenServer 6.0.0 Only!"
			exit 0
		fi
	else
		uname -v
	fi
}

################################################################################
#
#	DetectHardware
#		uses OS specific versions of SYS V's hw
#		and creates a file in the script temp directory called	
#		HWdetected
#
#
################################################################################
DetectHardware () {
	OSVers=$1
	setcolor $OUTPUT_COL
	echo "Detecting Hardware"
	case $OSVers in
 	"SYS5" )
		hw > /$g_TEMP/hw.tmp 
		WHOLE_FILE=`cat /$g_TEMP/hw.tmp`
		ReadHw $WHOLE_FILE > /$g_TEMP/HWdetected
	;;
	esac
}

################################################################################
#
#	ReadHw <file containing hw ouptut>
#		Outputs hw contents in a nicer format
#
#	New version for OS6 - as hw's output is different
#	
################################################################################
ReadHw () {
	while [ $# -gt 0 ]
	do
		if [ $1 = "resmgr" ]; then
			echo
			echo -n "Resource:$4:"
			shift
			Vendor=`grep "$7" $g_TEMP/hw.tmp | awk -F "=" '{print $3}' | uniq`
			echo -n "Card Vendor:$Vendor"
		elif [ $1 = "device" ]; then
			echo -n ":DeviceId:$4"
			shift	
		elif [ $1 = "Class" ]; then
			Class=`echo "$4" | awk -F "=" '{print $1}'`
			Device=`grep "$4" $g_TEMP/hw.tmp | awk -F "=" '{print $3}' | uniq`
			echo -n ":Device:$Device:ClassCode:$Class"
			shift
		else
			shift
		fi
	done
	echo
}

GetDevice () {
case $1 in
"0x078000")
	echo "Other Communication Device"
	;;
"0x028000")
	echo "Other Network Card"
	;;
"0x010000"|"0x010400"|"0x0e0001")
	echo "SCSI Controller"
	;;
"0x020000")
	echo "Network Adapter"
	;;
"0x060000")
	echo "Host Bridge"
	;;
*)
	echo "Unknown Device"
	;;
esac
}

################################################################################
#
#	MakeListFile <list> [seperator] <file to create> [new seperator]
#
#	seperates a list into a file so that grep can be used
#
################################################################################
MakeListFile () {
list=$1
seperator="$2"
file=$3
newsep="$4"
if [ -z "$newsep" ]; then
	newsep='\n'
fi
if [ $file ]; then
	echo $list | tr "${seperator}" "$newsep" > ${file}
else
	echo $list > ${seperator}
fi
}
ListRemove () {
	_list=$1
	_file=$2
	MakeListFile $_list : /tmp/remlist
	for i in `cat /tmp/remlist`
	do
		grep -v $i ${_file} > /tmp/list.tmp
		cp /tmp/list.tmp $_file
	done
	cat /tmp/remlist >> ${_file}X # this means that when a reboot is met
									# on a full install - it does not do
									# the things it has already done!
}
################################################################################
#	
#	Check <check type> < other variables >
#
#    -check type- -other variables-
#    count	  (occurences of) in (filename) return 1 if result (value) 
#    element	  (element list with : seperators) return 1 if appears in (file)
#    custom	  (Custom package name) returns 1 if installed
#    config	  looks for (file) in global temp or (directory) and (edit)
#
################################################################################
Check () {
checktype=$1
if [ "$2" ]; then
case $checktype in
"count")
	_what="$2"
	_cfile="$3"
	_value="$4"
	[ ! -e "$_cfile" ] && { return 2; }
	_result=`grep -c "$_what" "$_cfile"`
	if [ $_result = $_value ]; then
		return 1
	else
		return 0
	fi
	;;
"element")  # 2:list of elements 3:file [4:Do X check]
	_list="$2"
	doit=0
	dontdoit=0
	if [ $3 ]; then
		_file=$3
		_filex="${_file}X"
		MakeListFile ${_list} : $g_TEMP/chk.list 
		if [ $4 ]; then
			for i in `cat $g_TEMP/chk.list`
			do
				if [ -e "${_filex}" ]; then
					Check count $i ${_filex} 0
					dontresult=$?
					if [ $dontresult = 0 ]; then
						dontdoit=1
					fi
				fi
			done
		fi
		for i in `cat $g_TEMP/chk.list`
		do
			Check count $i ${_file} 0
			doresult=$?
			if [ $doresult = 0 ]; then
				doit=1
			fi
		done
		if [ $doit = 1 -a $dontdoit = 0 ]; then
			return 1
		else
			return 0
		fi
				
	else
		setcolor $ERROR_COL
		echo "Check () incorrect aborting"
		exit 0
	fi
	;;	
"custom")
	_package=$2
	result=`custom -l -p $2 | grep -c "Fatal"`
	if [ $result = 1 ]; then
		# May not be installed - or custom may already be running
		if [ `custom -l -p $2 | grep -c "already running"` -gt 0 ]; then
			return 3
		fi
		# Not Installed so return 0
		return 0
	elif [ `custom -l -p $2 | grep -c "Multiple"` -gt 0 ]; then
		# Maybe installed may not!!!
		return 2
	else
		return 1
	fi
	;;
"config")
	setcolor $INST_COL 
	echo "The script is now detecting whether you have already created"  
	echo "$2 file.  If it finds one in \"/tmp\" or \"$g_TEMP\" "
	echo "then you will be asked if you wish to use it."
	echo "If you say no, it will vi up the default file from the CD."
	echo "If you say Check, it will vi up the existing file for you to check."
	echo
	setcolor -n
	_cffile=$2
	_dir=$3
	_edit=$4
	for i in "$g_TEMP" "${_dir}"
	do
		if [ -e $i/$_cffile ]; then
			setcolor $INST_COL
			ans=3
			while [ $ans = 3 ]
			do
			   	echo "There is already a ${_cffile} file in $i - do you wish to use this."
				echo
				GetAns "Yes(default),No or Check ?" y:Y:YES:yes:Yes n:N:NO:no:No c:C:Check:CHECK:check
				ans=$?
				if [ $ans = 2 ]; then	# NO!
					if [ $i = "$g_TEMP" -a ! -e ${_dir}/${_cffile} ]; then
						setcolor $OUTPUT_COL
						echo "Copying default file from $root_dir"
						cp $ConFiles/${_cffile} $g_TEMP/${_cffile}
						chmod 777 $g_TEMP/${_cffile}
						[ $_edit ] && { vi $g_TEMP/${_cffile} 2> `tty`; }
						return 0
					elif [ $i = "$_dir" -a "$_edit" ]; then
						setcolor $OUTPUT_COL
						echo "Copying default file from $root_dir"
						cp $ConFiles/${_cffile} $g_TEMP/${_cffile}
						chmod 777 $g_TEMP/${_cffile}
						[ $_edit ] && { vi $g_TEMP/${_cffile} 2> `tty`; }
						return 0
					fi
				elif [ $ans = 3 ]; then # CHECK
					vi $i/${_cffile} 2> `tty` # check over the file 
				else # YES!
				[ ! $i = "$g_TEMP" ] && { cp $i/${_cffile} $g_TEMP/${_cffile}; }
					chmod 777 $g_TEMP/${_cffile}
					return 0
				fi
			done # always loop if we are checking.
		elif [ ! -e ${g_TEMP}/${_cffile} -a ! -e ${_dir}/${_cffile} -a "$_edit" ]; then
			# File does not exist in either directory and we want to edit 
			setcolor $OUTPUT_COL
			echo "There is no ${_cffile} file - now editing"
			cp $ConFiles/${_cffile} $g_TEMP/${_cffile}
			chmod 777 $g_TEMP/${_cffile}
			vi $g_TEMP/${_cffile} 2> `tty` 
			return 0
		else
			setcolor $ERROR_COL
			echo "There has been a problem finding a config file"
			return 1
		fi
	done # for loop for g_TEMP, _dir
	return 0
	;;
	*)
		setcolor $ERROR_COL
		echo "Check () performed an illegal operation"
		echo "$checktype : unsupported type."
		return 3
	;;
esac
else
	setcolor $ERROR_COL
	echo "Check () performed an illegal operation"
	echo "No operand in $2"
	exit 0
fi
}

# repline2 <command line>
# $1 = filename    $2 = look for what   $3 = replace with what
#
repline () {
check=`grep "$3" $1`	# Look for the line
	[ ! "$check" ] && {	# Nothing returned
		cp $1 $1.old	# Backup existing one

		echo "s:"$2"$:"$3":" > $g_TEMP/sedcom
		sed -f $g_TEMP/sedcom <$1.old >$1	# make change
	}
}

################################################################################
#
#
#	CalFix <version>
#
#
################################################################################
CalFix () {
	_version=$1

	cp /etc/rc2.d/P95calserver /etc/rc2.d/p95calserver.old

	case $_version in
		"5.0.6" )
			cp $SysFiles/506calserverfix /etc/rc2.d/P95calserver
			;;
		"5.0.5" )
			cp $SysFiles/calserverfix /etc/rc2.d/P95calserver
			;;
		"5.0.7" )
			cp $SysFiles/506calserverfix /etc/rc2.d/P95calserver
			;;
		"6.0.0" )
			cp $SysFiles/600calserverfix /etc/rc2.d/P95calserver	
			;;
	esac

	rm /usr/lib/sco/oadb/caldata/*

	cp /etc/default/lang /etc/default/lang.old
	cp $SysFiles/langfix /etc/default/lang

	cd /
	CALDATA=/usr/lib/sco/oadb/caldata; export CALDATA
	DBKEY=6373; export DBKEY
	/usr/lib/scosh/utilbin/calbuild
	isverify -I
}

################################################################################
#
#
#	CustomInst <type> <package> <name> <here?> <here options>
#
#	-type-	-package-	-name-
#	patch	<package name>	<patch name> - will look in relevant folder
#	software <package name> <path to image>	
#
#	if here activated here options must be a list of things divided by ,
#   if here = force then it will ALWAYS install software.
#	
################################################################################
CustomInst () {
_type=$1
if [ $2 ]; then
	_pkg=$2
	_name=$3
	case $_type in
	"patch" )
		_pname="$_name Patch"
		_chk=$_name
		_name="$root_dir/$OSVers/Patches/$_name"
		_here=$4
		_here_options=$5
		[ -z "$_here" ] && { _here=undef; }
	
		;;
	"software" )
		_pname=$_pkg
		_chk=""
		_here=$5
		_here_options=$6
		[ -z "$_here" ] && { _here=undef; }
		;;
	*)
		setcolor $ERROR_COL
		echo "Illegal call to CustomInst().\nUnknown type"
		exit 1
		;;
	esac
if [ $_name ]; then
		Check custom $_pkg
		result=$?
	if [ $result = 1 -a ! $_here = "force" ]; then 
		setcolor $INFO_COL
	   	echo "$_pname already installed."
		[ ! -z "$_chk" ] && SetCheckInf "$_chk" yes
		return 0
	elif [ $result = 2 -a $RunMode = CHK ]; then
		setcolor $INFO_COL
		echo "There are more than one Patches on this system with this Package name."
		setcolor $NOT_COL
		echo "$_pname may or may not be installed, please run custom to verify."	
		[ ! -z "$_chk" ] && SetCheckInf "$_chk" multiple
		return 0
	elif [ $result = 0 -a $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "$_pname NOT installed."
		[ ! -z "$_chk" ] && SetCheckInf "$_chk" no
		return 0
	elif [ $result = 3 ]; then
		setcolor $ERROR_COL
		echo "Custom may be running on another screen, or you are unable to use it."
		setcolor $INST_COL
		echo "Please check and try again."
		return 1
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Installing $_pname."
	elif [ $result = 2 ]; then
		setcolor $INFO_COL
		echo "There are more than one Patches on this system with this Package name."
		setcolor $OUTPUT_COL
		echo "Installing $_pname."
	fi
# Everything that does not want to install has exit 0'd
	if [ $_here_options ]; then
		MakeHere "custom -p $_pkg -i -z $_name >>$g_TEMP/$_type.log 2>&1" $_here_options
	else
		custom -p $_pkg -i -z $_name >>$g_TEMP/$_type.log 2>&1 
	fi
	g_reboot=1
	[ ! -z "$_chk" ] && SetCheckInf "$_chk" yes
fi  # for if [ $_name ]
fi # for if [ $2 ]
}


################################################################################
#
#	MakeHere <command line> <here_options>
#
################################################################################
MakeHere () {
_command=$1
_here_options=$2
if [ $_here_options ]; then
	echo "$_command << here_end" > $g_TEMP/here.sh
	MakeListFile $_here_options , $g_TEMP/here.opt
	cat $g_TEMP/here.opt >> $g_TEMP/here.sh
	echo "here_end" >> $g_TEMP/here.sh
	sh $g_TEMP/here.sh
else
	setcolor $ERROR_COL
	echo "Incorrect use of MakeHere () aborting"
	exit 0
fi
}

################################################################################
#
#	AskYesNo
#
################################################################################
AskYesNo () {
while true
do
	setcolor $INST_COL
	echo -n "[Y]es/[N]o: "
	read ans
	case $ans in
	"Y"|"y"|[Yy][Ee][Ss])
		return 1
		;;
	"N"|"n"|[Nn][Oo])
		return 0
		;;
	esac	
done
}

#############################################################
#							    #
# GetAns <prompt> <response 1> <response 2> ... <response n #
#							    #
#############################################################
GetAns () {
	_prompt=$1
	shift
	_command_line=$@
	_total_args=$#
	_counter=1
	if [ -e /tmp/fcounter ]; then
		. /tmp/fcounter
		FCOUNT=`expr $FCOUNT + 1`
		if [ $FCOUNT -gt $MAX_FUN_LOOP ]; then
			rm /tmp/fcounter
			setcolor $ERROR_COL
			echo "Error in GetAns function: Too many repetitions"
			exit 1
		else
			echo "FCOUNT=$FCOUNT" > /tmp/fcounter
		fi
	else
		echo "FCOUNT=1" > /tmp/fcounter
	fi
	if [ "$_command_line" ]; then		
		echo -n "\033[A                                             "
			setcolor $INST_COL
		echo -n "\r${_prompt} "
		read _ans
		_ans=`echo $_ans | tr " " "_"`
		if [ -z "$_ans" ]; then
			rm /tmp/fcounter
			return 0
		else
			while [ $# -gt 0 ]
			do
				for j in `echo $1 | tr ":" " "`
				do
					if [ $_ans = $j ]; then
						rm /tmp/fcounter
						return $_counter
					fi
				done
				_counter=`expr $_counter + 1`
				shift
			done
		fi
		GetAns "$_prompt" $_command_line
		return $?
	else
		setcolor $ERROR_COL
		echo "GetAns must have at least one response value"
		rm /tmp/fcounter
		exit 1
	fi
}
################################################################################
#
#
################################################################################
CreateHelpfile () {

	cp $SysFiles/syssetup.hlp $g_TEMP/syssetup.hlp
	MakeListFile $SOFTWARE : $g_TEMP/Softwareelements " "
	MakeListFile $HARDWARE : $g_TEMP/Hardwareelements " "
	MakeListFile $PATCHES : $g_TEMP/Patcheselements " "
	MakeListFile $INITIAL_ELEMENTS : $g_TEMP/Initialelements " "
	> $g_TEMP/elements.hlp
	for i in Software Hardware Patches Initial 
	do
		echo "`setcolor yellow`$i`setcolor hi_white`" | awk '{printf "\n%-20s\n", $1}' >> $g_TEMP/elements.hlp
		for j in `cat $g_TEMP/${i}elements`
		do
			echo $j | awk '{printf "%-20s", $1}' >> $g_TEMP/elements.hlp
		done
		rm $g_TEMP/${i}elements
	done
	cat $g_TEMP/elements.hlp >> $g_TEMP/syssetup.hlp
	rm $g_TEMP/elements.hlp
}

BannTitle () {
	Title=$1
	TitleLength=`expr length "$Title"`
	BannerLength=0
	Banner=">"
	ScreenWidth=79
	LeftDash=`expr \( $ScreenWidth / 2 \)  - \( $TitleLength / 2 \) - 2`
	setcolor yellow black
	while [ $LeftDash -gt $BannerLength ]	
	do
		Banner="$Banner-"
		BannerLength=`expr $BannerLength + 1`
	done
	Banner="$Banner[`setcolor cyan`$Title`setcolor yellow`]"
	BannerLength=`expr $BannerLength + 2 + $TitleLength`
	while [ $BannerLength -lt `expr $ScreenWidth - 2` ]
	do
		Banner="$Banner-"
		BannerLength=`expr $BannerLength + 1`
	done
	Banner="$Banner<"
	echo $Banner
	setcolor -n
}
			


################################################################################
#
#	UnpackFiles DirName
#	
#	Unpacks files from prog.tar, to $ProgFiles/$DirName
#
################################################################################
UnpackFiles () {
	DirName=$1
	if [ -z "$DirName" ]; then
		setcolor $ERROR_COL
		echo "Error: UnpackFiles () called with no parameters"
		return 1		
	fi
		
	if [ ! -d $ProgFiles/$DirName ]; then
		setcolor $OUTPUT_COL
		echo "Extracting $DirName from prog.tar"
		tar xvfn $root_dir/prog.tar $ProgFiles/$DirName > $g_TEMP/unpack.log 2>&1
		tar_return=$?
		if [ $tar_return -ne 0 ]; then
			# We have had a problem un tarring the files
			setcolor $ERROR_COL
			echo "Error: extracting $DirName from prog.tar."
			setcolor $INST_COL
			echo "Try copying prog.tar.Z from CD to $g_TEMP and then manually"
			echo "cd $g_TEMP and type :\nuncompress prog.tar.Z\ntar xvfn prog.tar $ProgFiles/$DirName"
			echo "Then re-run SysSet"
			return 1		
		fi	
	fi
}


SetCheckInf () 
{
	_Param="$1"
	_Value="$2"
	if [ ! -e $g_TEMP/check.inf ]; then
		echo "#! /bin/sh\n# check.inf" > $g_TEMP/check.inf
	fi
	grep -v "$_Param" $g_TEMP/check.inf > /tmp/check.tmp
	echo "$_Param=$_Value" >> /tmp/check.tmp
	cp /tmp/check.tmp $g_TEMP/check.inf
}

################################################################################
#  CpuSpeed () - returns the cpu speed as found in hw under %clock
################################################################################
CpuSpeed ()
{
	if [ `uname -v` = "5.0.6" ]; then
		cpu_speed=`hw | grep "%clock " | awk -F "/" '{print $2}'`
		cpu_speed=`echo $cpu_speed | awk -F "Hz" '{print $1}'`
		echo $cpu_speed	
	elif [ `uname -v` = "5.0.7" ]; then
		cpu_speed=`hw | grep "%clock " | awk -F "/" '{print $2}'`
		cpu_speed=`echo $cpu_speed | awk -F "Ghz" '{print $1}'`
		front=`echo $cpu_speed | awk -F "." '{print $1}'`
		back=`echo $cpu_speed | awk -F "." '{print $2}'`
		cpu_speed="$front$back"
		echo $cpu_speed
	else
		echo UNKNOWN
	fi
}

################################################################################
#  CheckRaid () - checks drive 0's scsi controller - is it raid ?
################################################################################
CheckRaid () {
	if [ -e /etc/conf/cf.d/mscsi ]; then
		grep Sdsk /etc/conf/cf.d/mscsi > /tmp/hds
		Hds=`cat /tmp/hds`
		adapter=`ReadMsci $Hds`
		[ -z "$adapter" ] && { adapter="UNKNOWN"; }
		echo $adapter
	else
		echo "nomscsi"
	fi
}
ReadMsci () {
    while [ $# -gt 0 ]
    do
		if [ "$2" = "Sdsk" ]; then
			if [ "$3" = "0" -a "$4" = "0" ]; then
				adapter=$1
       			break
     	 	fi
	    fi
   		shift
    done
    echo $adapter
}
