#! /bin/sh
# software functions
################################################################################
#	InstMTA
#   installs MTA software
#
################################################################################
InstMTA () {
	UnpackFiles MTA
	[ $? = 1 ] && { exit 0; }	
	case $RunMode in
		"AUTO")
			# Currently there is no difference - but this will b worked on
			sh $ProgFiles/MTA/install.sh
			;;
		"INT")
			sh $ProgFiles/MTA/install.sh
			;;
		*)
			echo "Error, InstMTA cannot determine runmode"
			return 1	
			;;
	esac
}

################################################################################
#	SetSems
#	Set system semaphores
################################################################################
SetSems () {
	case $RunMode in
		"AUTO")
		/etc/conf/cf.d/configure SEMMAP=20
		/etc/conf/cf.d/configure SEMMNI=20
		/etc/conf/cf.d/configure SEMMNU=60
		/etc/conf/cf.d/configure XSEMMAX=90
		/etc/conf/cf.d/configure SHMMAX=1600000
			;;
		"INT")
		/etc/conf/cf.d/configure
			;;
		*)
			echo "Error SetSems cannot determine RunMode"
			return 1
			;;
	esac

	/etc/conf/bin/idtune -f SEMMSL 60
	if [ `uname -v` -ne "5.0.5" ]; then
		/etc/conf/bin/idtune -f SEMMNS 500
	fi

	g_reboot=1
}

InstDXS () {
	UnpackFiles DXS
	[ $? = 1 ] && { exit 0; }
	if [ -d $ProgFiles/DXS ]; then
		if [ `uname -v` = "5.0.5" ]; then
			CustomInst patch SCO:oss621B oss621b
		fi
		cd $ProgFiles/DXS
		[ -e fb_os716.tar.Z ] && { uncompress fb_os716.tar.Z; }
		tar xvf fb_os716.tar >> $g_TEMP/Other.log 2>&1
		chmod 777 $ProgFiles/DXS/copyfile.sco
		sh copyfile.sco >> $g_TEMP/Other.log 2>&1
		chmod 666 /usr/interbase/isc4.gdb
		cp /etc/services /etc/services.safe
		cp /etc/inetd.conf /etc/inetd.safe
		if [ `grep -c gds_db /etc/services` -lt 1 ]; then
		echo "gds_db		3050/tcp	#Interbase Database Remote Protocol" >> /etc/services
		fi
		if [ `grep -c gds_db /etc/inetd.conf` -lt 1 ]; then
		echo "gds_db		stream		tcp		nowait		root	/usr/interbase/bin/gds_inet_server	gds_inet_server" >> /etc/inetd.conf
		fi
		tcp stop
		tcp start
	else
		setcolor $ERROR_COL
		echo "There has been a problem installing DXS"
	fi
}
