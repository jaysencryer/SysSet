# ! /bin/sh
#
# Patches V1
#
# 31/7/2002 :- changed test path for java install
# SysSet v2.9 comp

[ -e $root_dir/SysSet.var ] && { . $root_dir/SysSet.var; }
[ -e $root_dir/SysSet.fun ] && { . $root_dir/SysSet.fun; }

#do_mylex=0
BannTitle "PATCHES"
> $g_TEMP/patch.log

if [ ! $RunMode = CHK ]; then
	Check element FULLINSTALL:patches $g_TEMP/elements.list X
	element=$?
	if [ $element = 1 ]; then
		if [ ! -e $g_TEMP/HWdetected ]; then
			DetectHardware $OSVers
		fi
	fi
fi

PatchVers=`uname -v`
case $PatchVers in
"6.0.0")
	#osr600mp1
	Check element FULLINSTALL:patches:osr600mp1 $g_TEMP/elements.list X
	element=$?
	if [ $element = 1 ]; then
		CustomInst patch SCO:MP1600 osr600mp1 "i,i"
		[ $? = 1 ] && { exit 1; }
		ListRemove osr600mp1 $g_TEMP/elements.list
	fi
	#oss702a
	Check element FULLINSTALL:patches:oss702a $g_TEMP/elements.list X
	element=$?
	if [ $element = 1 ]; then
		CustomInst patch SCO:OSS702A oss702a
		[ $? = 1 ] && { exit 1; }
		ListRemove oss702a $g_TEMP/elements.list
	fi
	;;
*)
	setcolor $ERROR_COL
	echo "`uname -v` not a supported version of OS, Patches not installed"
	;;
esac


ListRemove patches $g_TEMP/elements.list
if [ $g_reboot = 1 ]; then
	exit 3
else
	exit 0
fi
