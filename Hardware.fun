#! /bin/sh
#
# Hardware.fun V1
#
# 31/7/2002 :- altered InstUPS to be less ambiguous
#				altered InstNetCard to bomb out with proper error message
#				if config file not complete.
#
# 13/10/2004 :- v3.000b updated gigabit driver 
TestFun () {
	echo "Banana"
	return 1
}

################################################################################
#
#	InstTape
#
################################################################################
InstTape () {
_tapesize=$1
_tapesetup=$2
case $RunMode in
"AUTO")
	if [ $_tapesetup ]; then
		case $_tapesetup in
		"standard")
		_adapt_options=",0,0,2,0"
		;;
		"non_standard")
		if [ ! -z "$tp_adap" ]; then 	
			_adapt_options="$tp_adap,$tp_adapid,$tp_bus,$tp_id,0"
		else
			setcolor $ERROR_COL
			echo "You have specified non-standard setup but not entered any adapter setup info"
			exit 1
		fi
		;;
		*)
			echo "Tape not setup as I do not understand the tapesetup request!"
			exit 1
		;;
		esac
		if [ $_tapesize = 20000000 ]; then
			_here_opts="1,1,$_adapt_options,y,HP,2,2,4,,q,q,q,n"
		elif [ $_tapesize = 40000000 ]; then
			_here_opts="1,1,$_adapt_options,y,HP,2,2,1,,q,q,q,n"
		elif [ $_tapesize = 100000000 ]; then
			_here_opts="1,1,$_adapt_options,y,HP,3,2,1,,q,q,q,n"
		else
			_here_opts="1,1,$_adapt_options,y,,,,4,,q,q,q,n"
		fi
		MakeHere "mkdev tape >>$g_TEMP/hardware.log 2>&1" $_here_opts

		cp /etc/default/tar /etc/default/tar.old
		grep -v "archive8" /etc/default/tar > /tmp/tarno8
		echo "archive8=/dev/rct0        20      $_tapesize y" >> /tmp/tarno8
		cp /tmp/tarno8 /etc/default/tar
	else
		echo "There is no tapesetup information available"
		echo "aborting tape setup information"
		exit 1
	fi
	;;
"INT")
	mkdev tape
	echo "1 - 4 GB Dat\n2 - 12 GB Dat\n3 - 20 GB Dat\n4 - 40 GB Dat (DLT)\n5 - 100 GB Viper\n(Default) 40 GB Dat\n"
	GetAns "Please select tape size" 1 2 3 4 5
	answer=$?
	case $answer in
	1)
		_tapesize=4000000
		;;
	2)
		_tapesize=12000000
		;;
	4)
		_tapesize=40000000
		;;
	5)
		_tapesize=100000000
		;;
	*)
		_tapesize=40000000
		;;
	esac
	cp /etc/default/tar /etc/default/tar.old
	grep -v "archive8" /etc/default/tar > /tmp/tarno8
	echo "archive8=/dev/rct0        20      $_tapesize y" >> /tmp/tarno8
	cp /tmp/tarno8 /etc/default/tar
	;;
esac
}

################################################################################
#
#	InstUPS <port device>
#
################################################################################
InstUPS () {
_port=$1
if [ $_port ]; then
	case $RunMode in
	"AUTO")
		echo "Please unplug UPS from com port"
		UnpackFiles UPS
		[ $? = 1 ] && { exit 0; }		
		cd $ProgFiles/UPS
		MakeHere "./INSTALL >>$g_TEMP/hardware.log 2>&1" 1,,n,3,2,y,6,n,,2,,y,E
		if [ -e /usr/lib/powerchute/powerchute.ini ]; then
			repline /usr/lib/powerchute/powerchute.ini " PortName = /dev/tty2a" " PortName = $_port"
		fi
		;;
	"INT")
		UnpackFiles UPS
		[ $? = 1 ] && { exit 0; }		
		cd $ProgFiles/UPS
		./INSTALL
		;;
	esac
else
	echo "Error - not setting up UPS software"
	return 1
fi
}
################################################################################
#
#	HowManyCards
#
#		works out number network adapters in machine using HWdetected file
#		The runs RunNetInst if there are multiple cards ( this seperates the
#		different fields ).  InstNetCard is called if there is just one card
#		
################################################################################
HowManyCards () {
	_number_cards=`grep -c "Network Adapter" $g_TEMP/HWdetected`
	_adapter=`grep "Network Adapter" $g_TEMP/HWdetected | awk -F : '{print $14}'`
	_device=`grep "Network Adapter" $g_TEMP/HWdetected | awk -F : '{print $4}'`
	_id=`grep "Network Adapter" $g_TEMP/HWdetected | awk -F : '{print $8}'`

	if [ $_number_cards -gt 1 ]; then
		RunNetInst $_number_cards "$_adapter" "$_device" "$_id" 
	elif [ $_number_cards = 1 ]; then
		InstNetCard	0 $_adapter $_device $_id
	elif [ $_number_cards = 0 ]; then
		echo "You have no Network cards in your machine"
		return 1
	fi
		
}
################################################################################
#
#	RunNetInst <number of cards> <adapter types> <devices> <id (is it gig?)>
#
#		seperates the multiple adapter strings and devices
#		and calls InstNetCard for each card
#
################################################################################
RunNetInst () {
		_number_cards=$1
		# at this point $# should be _number_cards * 2 + 1
		_total=$#
		_target=`expr $_number_cards \* 2 + 1`	
		if [ _total -ne _target ]; then
			# We have an error here!!!
			echo "RunNetInst () aborted: wrong number arguments"
			exit 1
		else
				_count=1
				while [ $_number_cards -gt 0 ]
					do
					# note - this works in this way 
					# essentially we are passing GetField 1 ADAP1 ADAP2 ADAP3
					_adapter=`GetField $_count $2`
					_device=`GetField $_count $3`
					_id=`GetField $_count $4`
					_num=`expr $_count - 1`
					_count=`expr $_count + 1`
					_number_cards=`expr $_number_cards - 1`
					echo "Installing Network card: $_adapter on net$_num" >> $g_TEMP/hardware.log
					InstNetCard $_num $_adapter $_device $_id
					done
		fi
}	
################################################################################
#
#	GetField n <argument list>
#	returns	the nth argument from the list (which should be seperated by spaces)
#
################################################################################
GetField () {
	_field=$1
		shift
		while [ $_field -gt 1 ]
		do
		shift	
			_field=`expr $_field - 1`
		done
		echo $1
}

################################################################################
#
#	InstNetCard [ number ] [ adapter ] [ device ]
#
#	number : 0 ... n - number of network card : ie net0
#	adapter : name of adapter
#
################################################################################
InstNetCard () {
# This installs the network card
	_number=$1
	_adapter=$2
	_device=$3
	_id=$4
HWosver=`uname -v`	
INSTALL_DIR=`ls /var/opt/K/SCO/lli | grep $HWosver`
INSTALL_DIR="/var/opt/K/SCO/lli/$INSTALL_DIR"	


# determine which card
if [ $_adapter ]; then
	if [ `ifconfig -a | grep -c "net$_number"` -ne 0 ]; then
		echo "Error: Already network card configured as net$_number!"
		return 1
	fi

	case $_adapter in
		"D-link")
			CustomInst software D-Link:d5B $root_dir/Drivers/DLINK
			ADAPTYPE="D-Link DFE-530TX PCI Fast Ethernet Adapter."
			cp $root_dir/Drivers/DLINK/net0 ${INSTALL_DIR}/sysdb/net$_number
			;;
		"ALLIED")
			ADAPTYPE="AT-2500TX Fast Ethernet Adapter Driver."
		 	cp -r $root_dir/Drivers/AT2500/r8e ${INSTALL_DIR}/ID	
			cp $root_dir/Drivers/AT2500/net0 ${INSTALL_DIR}/sysdb/net$_number
			cd ${INSTALL_DIR}/ID/r8e
			chmod +x r8e.h
			chmod +x Driver.o
			chmod +x System
			chmod +x Node
			chmod +x Master
			chmod +x Space.c
			chmod +x space.h
			chmod +x lkcfg
			cd AOF
			chmod +x r8e
			;;
		"3Com")
			ADAPTYPE="3Com 3C9x whichever corresponds to your NIC"
			cp $root_dir/Drivers/3COM/net0 ${INSTALL_DIR}/sysdb/net$_number
			CustomInst software 3Com:e3H $root_dir/Drivers/3COM
			chmod 777 ${INSTALL_DIR}/sysdb/net$_number
			repline ${INSTALL_DIR}/sysdb/net$_number "\tSELECT=14" "\tSELECT=$_device"
			if [ $HWosver = "5.0.5" ]; then
				echo "Your Network card may not be supported by 5.0.5."
				echo "If your network card is non-functional on reboot."
				echo "please install manually using correct drivers."
				echo "- Note, this feature will be implemented if requested."	
			fi
			;;
		"Intel")
			case $_id in
			"0x1010"|"0x100d")
				if [ $HWosver = "5.0.5" ]; then
					setcolor $ERROR_COL
					echo "Gigabit NIC's are not supported by 5.0.5 or lower"
					echo "these drivers can not be installed!"
					return 1
				else
					ADAPTYPE="Intel Gbit"
					CustomInst software SCO:eeG $root_dir/Drivers/InteleeG
					cp $root_dir/Drivers/InteleeG/net0 ${INSTALL_DIR}/sysdb/net$_number
					chmod 777 ${INSTALL_DIR}/sysdb/net$_number
					repline ${INSTALL_DIR}/sysdb/net$_number "\tSELECT=4" "\tSELECT=$_device"
				fi
				;;
			*)
				ADAPTYPE="Intel"
				cp $root_dir/Drivers/INTEL/net0 ${INSTALL_DIR}/sysdb/net$_number
				chmod 777 ${INSTALL_DIR}/sysdb/net$_number
				repline ${INSTALL_DIR}/sysdb/net$_number "\tSELECT=3" "\tSELECT=$_device"
				;;	
			esac
			;;
		*)
			echo "Network card does not appear to be supported"
			return 1
			;;
	esac
		echo "Installing $ADAPTYPE on Dev $_device as net$_number"
		case $RunMode in
		"AUTO")
			[ $g_TEMP/hardware.cfg ] && { . $g_TEMP/hardware.cfg; }
			if [ -z "$hw_Ipnet0" ]; then
				echo "hardware.cfg not complete. Aborting network card install"
				exit 1
			fi
			IQM_DOMAIN_NAME=$hw_Domainnet0
			IQM_TCP_IPADDR=`grep "hw_Ipnet$_number=" $g_TEMP/hardware.cfg | awk -F = '{print $2}'`
			IQM_TCP_NETMASK=`grep "hw_Masknet$_number=" $g_TEMP/hardware.cfg | awk -F = '{print $2}'`
			IQM_TCP_BROADCAST=`grep "hw_Broadnet$_number=" $g_TEMP/hardware.cfg | awk -F = '{print $2}'`
			if [ $_number -ne 0 ]; then
			IQM_SYSTEM_NAME=`grep "hw_HostNamenet$_number=" $g_TEMP/hardware.cfg | awk -F = '{print $2}'`
			else
				IQM_SYSTEM_NAME=`uname -n`
			fi
			;;
		"INT")
			echo "Please enter the following for $_adapter Adapter net$_number."
			echo -n "Host name (of card) : "
			read IQM_SYSTEM_NAME
			echo -n "IP Address : " 
			read IQM_TCP_IPADDR
			echo -n "Broadcast Address : "
			read IQM_TCP_BROADCAST
			echo -n "Netmask : "
			read IQM_TCP_NETMASK
			echo -n "Domain : "
			read IQM_DOMAIN_NAME
			;;
		*)
			echo "Not a valid runmode for Network Install"
			return 1
			;;
		esac
		for i in "$IQM_TCP_IPADDR" "$IQM_TCP_BROADCAST" "$IQM_TCP_NETMASK" "$IQM_DOMAIN_NAME" "$IQM_SYSTEM_NAME"
		do
				if [ -z "$i" ]; then
					if [ $_number = 1 ]; then
						echo "Value missing for network set up.\nCheck you Hardware.cfg file"
						return 1
					fi
					echo "Missing IP information - a card was not installed.\nThis may be intentional - please check your Hardware.cfg file"
						return 1
				fi
		done
# we have got this far - so the Variables are all loaded, and ready to go
		IQM_FILE=/bin/true
		IQM_INSTALL_TYPE="fresh"
		DHCP=No
		export DHCP IQM_TCP_IPADDR IQM_TCP_BROADCAST IQM_TCP_NETMASK IQM_DOMAIN_NAME IQM_FILE IQM_INSTALL_TYPE IQM_SYSTEM_NAME
		netconfig -a sco_tcp#net${_number}
fi
}
