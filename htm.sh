#! /bin/sh
root_dir=/usr/jaysen/F2001/V2
. $root_dir/SysSet.var
. $root_dir/SysSet.fun
. $root_dir/html.fun
. $g_TEMP/check.inf

_page=/jcutils/jjpage.html

htm_head "SysSet $SYS_VERSION check" $_page
htm_print $_page "System Setup Checks" "align=center> <font size=10"
htm_print $_page "machine name : `hostname`" "align=center> <font size=3 color=BLUE"
htm_section $_page "align=center> Just A Test <font size=3 color=RED align=center"
htm_print $_page "INITIAL SETUP" "align=center> <font size=5"
htm_section $_page "font size=3 color=RED align=center"
htm_print $_page "Parallel Port : $PARALLEL" 
htm_print $_page "Power Management : $POWER"
htm_print $_page "CalServer Fix : $CALSERVER"
htm_print $_page "Environment Setup : $ENV"
htm_print $_page "MAXEXECARGS altered : $MAXEX"
htm_print $_page "HARDWARE" "align=center> <font size=5"
htm_section $_page "font size=3 color=RED align=center"
htm_print $_page "Tape Streamer : $TAPE"
htm_print $_page "PowerChute for APC UPS : $UPS"
htm_print $_page "Network Card(s) : $NETWORK"
if [ ! -z "$SPECIALIX" ]; then
	htm_print $_page "Specialix Drivers : $SPECIALIX"
	else
	htm_print $_page "There are no Specialix cards in this machine"
fi
htm_print $_page "PATCHES" "align=center> <font size=5"
htm_section $_page END
htm_foot $_page 

