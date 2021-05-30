# ! /bin/sh
# vim.sh
# SysSet v2.9 comp.

[ -e $root_dir/SysSet.var ] && { . $root_dir/SysSet.var; }
[ -e $root_dir/SysSet.fun ] && { . $root_dir/SysSet.fun; }
BannTitle "VIM"
Check element FULLINSTALL:extra:vim:VIM $g_TEMP/elements.list X
element=$?
if [ $element = 1 ]; then
	if [ -e /usr/vim ]; then
		setcolor $INFO_COL
		echo "Vim already installed." 
		SetCheckInf VIM yes	
	elif [ ! $RunMode = CHK ]; then
		setcolor $OUTPUT_COL
		echo "Installing Vim."
		UnpackFiles VIM
		[ $? = 1 ] && { exit 2; }
		if [ -e $ProgFiles/VIM/vim.TAR.Z ]; then
			uncompress $ProgFiles/VIM/vim.TAR.Z
			tar xvfn $ProgFiles/VIM/vim.TAR >> $g_TEMP/Extras.log
			[ ! $? = 0 ] && {
				setcolor $ERROR_COL
				echo "Error with vim.TAR file"
				SetCheckInf VIM no	
				exit 2
			}	
			mv /usr/bin/vi /usr/bin/vi.safe
			ln /usr/bin/vim /usr/bin/vi
			repline /usr/vim/.vimrc "set cindent" "\" set cindent"
			cp /usr/vim/.vimrc /.vimrc
			SetCheckInf VIM yes	
		else
			setcolor $ERROR_COL
			echo "Unable to find vim.TAR.Z"
			SetCheckInf VIM no	
			exit 2
		fi
	elif [ $RunMode = CHK ]; then
		setcolor $NOT_COL
		echo "Vim NOT installed."
		SetCheckInf VIM no	
	fi
	ListRemove vim:VIM $g_TEMP/elements.list
fi

if [ $g_reboot = 1 ]; then
	exit 3
else
	exit 0
fi
