# ! /bin/sh
# samba.sh
# SysSet vOS6

[ -e $root_dir/SysSet.var ] && { . $root_dir/SysSet.var; }
[ -e $root_dir/SysSet.fun ] && { . $root_dir/SysSet.fun; }
BannTitle "SAMBA"
Check element FULLINSTALL:extra:samba:SAMBA $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	if [ -e /usr/lib/samba/lib/netlogon ]; then
		setcolor $INFO_COL
		echo "Samba already installed." 
		SetCheckInf SAMBA yes	
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Installing Samba."
		mkdev samba << end_samba
1


Y
Y
N
N
end_samba
		setcolor $OUTPUT_COL
		echo "Configuring password for samba root"
		smbpasswd -a root
		echo "Checking and creating Samba directories"
		[ ! -e /usr/lib/samba/lib ] && { mkdir /usr/lib/samba/lib; }
		[ ! -e /usr/lib/samba/lib/netlogon ] && { mkdir /usr/lib/samba/lib/netlogon; } 
		cp $SysFiles/netlogon.bat /usr/lib/samba/lib/netlogon
		[ ! -e /usr/samba-prof- ] && { mkdir /usr/samba-prof-; }
		cp $SysFiles/smb.conf /etc/samba
		cp $SysFiles/S99samba /etc/rc2.d
		
		SetCheckInf SAMBA yes	
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "Samba NOT installed."
		SetCheckInf SAMBA no	
	fi
	ListRemove samba:SAMBA $g_TEMP/elements.list
fi

if [ $g_reboot = 1 ]; then
	exit 3
else
	exit 0
fi
