#!/bin/bash
# drivecrypt.sh
# License: GNU Public License v2.0
# Author: Falko ten Bosch, falko@tenbosch.net
# Version: 24.05.2015, v0.3 -- stable
# History: 17.05.2015, v0.2 -- adding second mount option
#          17.05.2015, v0.1 -- initial version
#
# This bash shell script utilizes the following programs:
# sudo mount echo dialog
#
# In case you're using a small linux (for example on SYNOLOGY NAS devices) with BusyBox:
#
# 1) install BASH, because ASH does not offer all the required functionality:
#       http://jehanalvani.com/weblog/2014/12/29/bash-on-synology-diskstation
#    set the synonym
#       ln -s /opt/bin/bash /bin/bash
# 
# Login as root! (or use sudo)
# --------------------------------------------------------------------------------------

# Constants: Display colors

# Color		Foreground	Background
# black		30		40
# red		31		41
# green		32		42
# brown		33		43
# blue		34		44
# magenta	35		45
# cyan		36		46
# white		37		47

cStandard='\E[0;0;39m'

cYellowBlack='\E[33;40m'
cGreenBlack='\E[32;40m'

cBlackWhite='\E[30;47m'
cGreenWhite='\E[32;47m'
cRedWhite='\E[31;47m'

cBlueStd='\E[0;0;34m'
cCyanStd='\E[0;0;36m'
cBrown='\E[30;43m'
cGreen='\E[37;42m'
cRed='\E[37;41m'

# Create a neat pathname: In case the / (slash) at the end of the name is missing, add it! Remove multiple slashes.
v_neatpathname=""
function neat_pathname() {
	v_pathname=$1
	if [[ ${v_pathname: -1} != "/" ]]; then v_neatpathname="$v_pathname/"; else v_neatpathname="$v_pathname"; fi
	# Remove multiple slashes from the end of the pathname		
	while [[ ${v_pathname: -2} == "//" ]]
	do
		v_neatpathname=${v_pathname:0:${#v_pathname} - 1 }
		v_pathname=${v_neatpathname}
	done
}

function display_title() {
	echo -e "${cBlackWhite}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${cStandard}"	
	echo -e "${cBlackWhite} drivecrypt.sh - Manage your 'ecrypt' drive encryption on Linux! ${cStandard}"
	echo -e "${cBlackWhite}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${cStandard}"
}

# Main Menu
function show_menu() {
	clear
    display_title
    echo -e "0. ${cGreen}REFRESH${cStandard} this menu."
    echo -e "1. ${cGreen}SHOW${cStandard} all mounted encrypted directories."
	echo -e "2. ${cBrown}SET${cStandard} ${cBlueStd}Mount Point${cStandard} directory. Current is: "${cYellowBlack}${v_mountpoint_dir}${cStandard}
	echo -e "3. ${cBrown}SET${cStandard} ${cCyanStd}Encrypted${cStandard} directory.   Current is: "${cYellowBlack}${v_encrypted_dir}${cStandard}
	echo -e "4. ${cGreen}MOUNT${cStandard} your ${cCyanStd}Encrypted${cStandard} directory to the ${cBlueStd}Mount point${cStandard} using AES 256 Bit."
	echo -e "5. ${cGreen}MOUNT${cStandard} your ${cCyanStd}Encrypted${cStandard} directory to the ${cBlueStd}Mount point${cStandard} using custom settings."
	echo -e "6. ${cRed}UNMOUNT${cStandard} a encrypted directory."
	echo -e "7. ${cRed}EXIT${cStandard}"
	echo    "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

}

# Program call #1, set Mount Point directory
function set_mountpoint_dir() {
	v_mountpoint_dir=$( dialog --stdout --title "Choose Mount Point directory" --dselect "$v_mountpoint_dir" 10 20 )
    echo "${v_mountpoint_dir} directory chosen."
    
 	if [ "$v_mountpoint_dir" == "" ]
	then v_mountpoint_dir="./"
	else 
		neat_pathname "$v_mountpoint_dir"
		v_mountpoint_dir="$v_neatpathname" 
		# Check if it is a valid file system directory. If not, try again! 
		if ( [[ -d "$v_mountpoint_dir" ]] || [[ "$v_mountpoint_dir" == "~/" ]] ); then echo -e "${cGreen}OK!${cStandard}"
		else echo -e "'$v_mountpoint_dir' is ${cRed}NOT${cStandard} a directory!"; set_mountpoint_dir 
		fi
	fi
}

# Program call #2, set MD5 directory
function set_encrypted_dir() {
	v_encrypted_dir=$( dialog --stdout --title "Choose Encrypted directory" --dselect $HOME/ 10 20 )
    echo "${v_encrypted_dir} directory chosen."
	
	if [ "$v_encrypted_dir" == "" ]
	then v_encrypted_dir="./"
	else
		neat_pathname "$v_encrypted_dir"
		v_encrypted_dir=$v_neatpathname 
		# Check if it is a valid file system directory. If not, try again! 
		if ( [[ -d "$v_encrypted_dir" ]] || [[ "$v_encrypted_dir" == "~/" ]] ); then echo -e "${cGreen}OK!${cStandard}"
		else echo -e "'$v_encrypted_dir' is ${cRed}NOT${cStandard} a directory!"; set_encrypted_dir 
		fi
	fi	
}

# Program call #3, Show all Mounts
function show_mounts() {
	echo "----------------------------------"
	echo "Show all mounted encrypted drives:"
    mount -t ecryptfs
    # either display choice options...    
    read_options
    # ... or always go back to main menu
    #read -p "Press <Enter> to go back to main menu:" v_enterdummy
}

# Program call #4, Mount encrypted directory
function mount_dir() {
	echo "----------------------------"
	echo "Mounting Encrypted Directory"
	echo -e "${cBlueStd}Mount Point${cStandard} directory     : "${cYellowBlack}${v_mountpoint_dir}${cStandard}
	echo -e "${cCyanStd}Encrypted${cStandard} directory       : "${cYellowBlack}${v_encrypted_dir}${cStandard}
    # do the mounting    
    if [ "$1" == "AES" ]
	then
        sudo mount.ecryptfs "${v_encrypted_dir}" "${v_mountpoint_dir}" -o key=passphrase,ecryptfs_cipher=aes,ecryptfs_key_bytes=32,ecryptfs_passthrough=n,no_sig_cache,ecryptfs_enable_filename_crypto=y
	else
	    sudo mount.ecryptfs "${v_encrypted_dir}" "${v_mountpoint_dir}"
	fi	
    
    # either display choice options...    
    read_options
    # ... or always go back to main menu
    #read -p "Press <Enter> to go back to main menu:" v_enterdummy
}

# Program call #5, Unmount encrypted directory
function unmount_dir() {
    echo "-------------------------------"
	echo "Unmounting Encrypted Directory"
	echo -e "${cBlueStd}Mount Point${cStandard} directory     : "${cYellowBlack}${v_mountpoint_dir}${cStandard}
	echo -e "${cCyanStd}Encrypted${cStandard} directory       : "${cYellowBlack}${v_encrypted_dir}${cStandard}
 
    sudo umount "${v_mountpoint_dir}"
     
    echo -e "${cGreen}FINISHED!${cStandard} Unmounting of encrypted drive was successfull."
	
    # either display choice options...    
    read_options
    # ... or always go back to main menu
    #read -p "Press <Enter> to go back to main menu:" v_enterdummy
}

read_options(){
	local choice
	read -p "Enter choice [ 0 - 6 ] " choice
	case $choice in
		0) show_menu ;;
        1) show_mounts ;;
		2) set_mountpoint_dir ;;
		3) set_encrypted_dir ;;
		4) mount_dir "AES" 32 ;;
		5) mount_dir ;;
		6) unmount_dir ;;
		7) exit 0;;
		*) echo -e "${cRed}Error: Choice not available...${cStandard}" && sleep 2 && read_options
	esac
}
 
# #######################
# ### START of script ###
# #######################
# Trap CTRL+C, CTRL+Z and quit singles
#trap '' SIGINT SIGQUIT SIGTSTP
 
# display title box
display_title

# check 1st parameter: Mount Point directory
if [ "$1" == "" ]; then
    v_mountpoint_dir="~/" 
    #set_mountpoint_dir
else
	neat_pathname "$1"
	v_mountpoint_dir="$v_neatpathname" 
	# Check if it is a valid file system directory. If not, try again! 
	if ( [[ -d "$v_mountpoint_dir" ]] || [[ "$v_mountpoint_dir" == "~/" ]] )
    then echo -e "Parameter 1: Base directory exists: "${cYellowBlack}${v_mountpoint_dir}${cStandard}
	else echo -e "'$v_mountpoint_dir' is ${cRed}NOT${cStandard} a directory!"; set_mountpoint_dir 
	fi
fi

# check 2nd parameter: Encrypted directory
if [ "$2" == "" ]; then
	v_encrypted_dir="~/" 
    #set_encrypted_dir
else
	neat_pathname "$2"
	v_encrypted_dir="$v_neatpathname"
	# Check if it is a valid file system directory. If not, try again! 
	if ( [[ -d "$v_encrypted_dir" ]] || [[ "$v_encrypted_dir" == "~/" ]] )
    then echo -e "Parameter 2:  MD5 directory exists: "${cYellowBlack}${v_encrypted_dir}${cStandard}
	else echo -e "'$v_encrypted_dir' is ${cRed}NOT${cStandard} a directory!"; set_encrypted_dir 
	fi
fi

# check 3rd parameter: command action, "mount" or "unmount"
if ( [ "$3" == "mount" ] || [ "$3" == "MOUNT" ] ); then
	echo "Skipping main menu. Mounting drive now!"
    mount_dir
    exit 0
elif ( [ "$3" == "unmount" ] || [ "$3" == "UNMOUNT" ] ); then 
    echo "Skipping main menu. Unmounting drive now!"
    unmount_dir
    exit 0
fi

# this is the main program: an infinite loop ;-)
while true
do
	show_menu
	read_options
done

# END OF SCRIPT
