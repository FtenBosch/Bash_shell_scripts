#!/bin/bash
# md5batch.sh
# License: GNU Public License v2.0
# Author: Falko ten Bosch, falko@tenbosch.net
# Version: 03.05.2015, v0.5
#
# This bash shell script utilizes the following programs:
# cat cut basename echo grep md5sum mkdir printf read stat uniq 
# --------------------------------------------------------------------------------------
# In case you're using a small linux (for example on SYNOLOGY NAS devices) with BusyBox:
#
# 1) install BASH, because ASH does not offer all the required functionality
# 2) install COREUTILS ( to utilize the piping ability of these heavyweight tools )
#                   # ipkg install coreutils
# 3) install GREP
#       Option a) get it here: ftp://ftp.gnu.org/gnu/grep/ )
#                 This script is tested on grep Version 2.16
#                 To enable MAKE on a Synology NAS you might have to
#                 login as "root" and install the following:
#                   # ipkg install gcc
#                   # ipkg install optware-devel
#                 Then cd to the downloaded folder and:
#                    (1) # ./configure 
#                    (2) # make 
#                    (3) # make install 
#       Option b) Install the grep version that is enlisted with ipkg:
#                   # ipkg list
#                   (to show all available packages)
#                   # ipkg install grep
#                   (to install a grep version for your Synology)
#
# 4) Since aliasing doesn't work with shell scripts, you might have to 
#    remove (as root) the symlinks that link to "BusyBox" calls 
#    and replace them with heavyweight programs. 
#    See your configuration! For example:
#    a) remove  
#       # rm /bin/cat
#       # rm /bin/grep
#    b) ... and create new symlinks to the heavyweight programs of COREUTILS
#       # ln -s /opt/bin/coreutils-cat /bin/cat
#       # ln -s /opt/bin/coreutils-cut /bin/cut
#       # ln -s /opt/bin/coreutils-basename /bin/basename
#       # ln -s /opt/bin/coreutils-ls /bin/ls
#       # ln -s /opt/bin/coreutils-md5sum /bin/md5sum
#       # ln -s /opt/bin/coreutils-printf /bin/printf
#       # ln -s /opt/bin/coreutils-stat /bin/stat
#       # ln -s /opt/bin/coreutils-uniq /bin/uniq
#    c) ... and to the dedicated install of GREP 
#       # ln -s /opt/bin/grep-grep /bin/grep
# ------------------------------------------------------------------------------------

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

# Constants: File name stuff 
v_md5file_ext=".md5info"
v_timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

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
	echo -e "${cBlackWhite}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${cStandard}"	
	echo -e "${cBlackWhite} md5batch.sh -- Identify identical files on your drive!                       ${cStandard}"
	echo -e "${cBlackWhite} ------------------------------------------------------                       ${cStandard}"
	echo -e "${cBlackWhite} I)  Batch create info files (containing MD5 checksum and other information)  ${cStandard}"
	echo -e "${cBlackWhite}     in the MD5 subfolder                                                     ${cStandard}"
	echo -e "${cBlackWhite}     for each file in the Base directory (including subdirectories)           ${cStandard}"
	echo -e "${cBlackWhite} II) Create a 'Summary' and a 'Multiples' text file (showing identical files) ${cStandard}"
	echo -e "${cBlackWhite}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${cStandard}"
}

# Main Menu
function show_menu() {
	clear
    display_title
	echo -e "1. ${cBrown}SET${cStandard} Base directory."
	echo -e "       Current is: "${cYellowBlack}${v_dir_base}${cStandard}
	echo -e "2. ${cBrown}SET${cStandard} ${cCyanStd}MD5 directory${cStandard}."
	echo -e "       Current is: "${cYellowBlack}${v_dir_md5}${cStandard}
	echo -e "3. ${cBrown}SET${cStandard} name of ${cBlueStd}MD5 subfolder${cStandard} to be created in ${cCyanStd}MD5 directory${cStandard}."
	echo -e "       Current is: "${cYellowBlack}${v_md5_subfolder_name}${cStandard}
	echo -e "4. ${cGreen}START${cStandard} batch to create '.md5info'-files"
	echo -e "         in the ${cBlueStd}MD5 subfolder${cStandard}. "
	echo -e "5. ${cGreen}START${cStandard} analysis of ${cBlueStd}MD5 subfolder${cStandard}"
	echo -e "         to create 2 resulting text files in ${cCyanStd}MD5 directory${cStandard}."
	echo -e "6. ${cRed}EXIT${cStandard}"
}

# Program call #1, set base directory
function set_base_dir() {
	echo "-----------------------------"
	echo "Enter path of Base directory" 
	read -p "(press <Enter> for current directory):" v_dir_base
	if [ "$v_dir_base" == "" ]
	then v_dir_base="./"
	else 
		neat_pathname "$v_dir_base"
		v_dir_base="$v_neatpathname" 
		# Check if it is a valid file system directory. If not, try again! 
		if ( [[ -d "$v_dir_base" ]] || [[ "$v_dir_base" == "~/" ]] ); then echo -e "${cGreen}OK!${cStandard}"
		else echo -e "'$v_dir_base' is ${cRed}NOT${cStandard} a directory!"; set_base_dir 
		fi
	fi
}

# Program call #2, set MD5 directory
function set_md5_dir() {
	echo "----------------------------------"
	echo "Enter path of MD5 folder directory" 
	read -p "(press <Enter> for current directory):" v_dir_md5
	
	if [ "$v_dir_md5" == "" ]
	then v_dir_md5="./"
	else
		neat_pathname "$v_dir_md5"
		v_dir_md5=$v_neatpathname 
		# Check if it is a valid file system directory. If not, try again! 
		if ( [[ -d "$v_dir_md5" ]] || [[ "$v_dir_md5" == "~/" ]] ); then echo -e "${cGreen}OK!${cStandard}"
		else echo -e "'$v_dir_md5' is ${cRed}NOT${cStandard} a directory!"; set_md5_dir 
		fi
	fi	
}

# Program call #3, set MD5 subfolder name
function set_md5_subfolder_name() {
	v_timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
	v_md5_subfolder_name="MD5storage_${v_timestamp}/"
	echo "------------------------------------------"
	echo -e "Default name of MD5 subfolder would be  :"${cYellowBlack}${v_md5_subfolder_name}${cStandard}
	read -p "Enter new name (press Enter for default):" v_md5_subfolder_name
	if [ "$v_md5_subfolder_name" == "" ]
	then 
		v_md5_subfolder_name="MD5storage_${v_timestamp}/"
	else
		neat_pathname "$v_md5_subfolder_name"
		v_md5_subfolder_name=$v_neatpathname 
	fi
}

# Program call #4, start the batch creation of MD5 files
function start_batch() {
	echo "-----------------------------"
	echo "STARTING batch creation of MD5 files."
	echo -e "Base directory            : "${cYellowBlack}${v_dir_base}${cStandard}
	echo -e "MD5 directory             : "${cYellowBlack}${v_dir_md5}${cStandard}
	echo -e "Name of MD5 subfolder     : "${cYellowBlack}${v_md5_subfolder_name}${cStandard}
	# Create the full pathname for MD5 folder (directory + filename)	
	v_fullpath_md5=${v_dir_md5}${v_md5_subfolder_name}
	echo -e "Full path of MD5 subfolder: "${cYellowBlack}${v_fullpath_md5}${cStandard}
    
    if [[ -d "$v_fullpath_md5" ]]
    then
        echo -e "MD5 subfolder already exists: "${cYellowBlack}${v_fullpath_md5}${cStandard}
    else
        mkdir "$v_fullpath_md5"
    fi

    # Enter base directory and start the work
    echo -e "Entering Base directory: "${cYellowBlack}${v_dir_base}${cStandard}
    cd "$v_dir_base"

    # Filter to certain files
    v_fileformat="*"
    # loop through all directories
    find . -type d | while read l_currdir
    do
        if [[ "${l_currdir}" == "." ]]; then
            # Current directoy is base directory, so nothing to add to base directory string        
            v_curr_dir=""
        else
            # Cleanup directory name: (1) remove "./" from the beginning, (2) add "/" as a suffix        
            v_curr_dir=${l_currdir:2}/
        fi
	
        echo -e "Entering directory: "${cYellowBlack}${v_dir_base}${v_curr_dir}${cStandard}  
        cd "${v_dir_base}${v_curr_dir}"
        
        # loop through all files of the current directory
        for i in $v_fileformat;
        do
            # if directory is empty, break the file loop!
            if [[ "$i" == "$v_fileformat" ]]; then echo "No Files"; break; fi
            # continue to next file if the current is a directory    
            if [[ -d "$i" ]]; then continue; fi
            
            # split filename into prefix (name) and suffix (extension)
            v_filename=$(basename "$i")
            v_extension="${v_filename##*.}"
            v_filename="${v_filename%.*}"
            
            # skip this file (go to next file) if it has a MD5 extension    
            if [[ ${v_extension} == "md5" || ${v_extension} == "MD5" ]]; then continue; fi

            # Display
            echo -e "File Name         : "${cGreenBlack}${i}${cStandard}

            # Full Path (path and filename)            
            v_filefull_now="${v_dir_base}${v_curr_dir}${i}"
            
            # Full Path MD5 (path and filename)
            v_md5filefull_now=$( printf '%s' "$v_filefull_now" | md5sum )
            v_md5filefull_now=$( echo ${v_md5filefull_now} | cut --delimiter=" " -f 1 )
            # File Content MD5
            v_md5file=$( md5sum "${v_filefull_now}" | cut --delimiter=" " -f 1 )

            # Path only
            v_filepathonly=${v_filefull_now%/*}/
            # Path only MD5
            v_filepathonly_md5=$( printf '%s' "$v_filepathonly" | md5sum )
            v_filepathonly_md5=$( echo ${v_filepathonly_md5} | cut --delimiter=" " -f 1 )

            # Bytesize (of current file + fill up a prefix with leading zeros ...up to 12 digits total width) 
            v_file_bytesize=$( wc -c "${v_filefull_now}" | cut --delimiter=" " -f 1 )
            v_len_bytesize=${#v_file_bytesize}
            #echo "Len bytesize   : $v_len_bytesize"
            v_bytesize_fieldwidth=12            
            v_bytesize_fillzeros=$((v_bytesize_fieldwidth - v_len_bytesize))
            #echo "Fill zeros     : $v_bytesize_fillzeros"
            # repeat a number of "0"s to be used as a prefix            
            v_prefix_zeros=$( printf '%0.s0' $(seq 1 $v_bytesize_fillzeros) )            
            #echo "Prefix zeros     : $v_prefix_zeros"
            v_file_bytesize=${v_prefix_zeros}${v_file_bytesize}

            # Timestamp (filesystem stamp of the current file)
            v_timestamp=$( stat -c %y "$v_filefull_now" | cut --delimiter="." -f 1 )
            v_timestamp=${v_timestamp//:/-}

            # Display
            echo -e "File Content MD5  : ${cGreenBlack}${v_md5file}${cStandard}"
            echo -e "Full Path         : ${cBlackWhite}${v_filefull_now}${cStandard}"
            echo -e "Full Path MD5     : ${cBlackWhite}${v_md5filefull_now}${cStandard}"
            echo -e "Path only         : ${cRedWhite}${v_filepathonly}${cStandard}"
            echo -e "Path only MD5     : ${cRedWhite}${v_filepathonly_md5}${cStandard}"
            echo -e "Bytesize          : ${v_file_bytesize}"
            echo -e "Timestamp         : ${v_timestamp}"

            # create special filename for the target MD5 file.
            v_md5filename="${v_file_bytesize}-${v_md5file}-${v_md5filefull_now}${v_md5file_ext}"                    
            # write everything to resulting target MD5 file    
            echo -e "File Name         :${i}\nFile Content MD5  :${v_md5file}\nPath only         :${v_filepathonly}\nPath only MD5     :${v_filepathonly_md5}\nFull Path         :${v_filefull_now}\nFull Path MD5     :${v_md5filefull_now}\nTimestamp         :${v_timestamp}\nBytesize          :${v_file_bytesize}\n" >"${v_fullpath_md5}${v_md5filename}"
        done
    done
    echo -e "${cRed}FINISHED!${cStandard} All files have been processed."
	read -p "Press <Enter> to go back to main menu:" v_enterdummy
}

# Program call #5, start the analysis of MD5 files
function start_analysis() {
	echo "-------------------------------"
	echo "STARTING analysis of MD5 files."
	echo -e "MD5 directory              : "${cYellowBlack}${v_dir_md5}${cStandard}
	echo -e "Name of MD5 subfolder      : "${cYellowBlack}${v_md5_subfolder_name}${cStandard}
	# Create the full pathname for MD5 folder (directory + filename)	
	v_fullpath_md5=${v_dir_md5}${v_md5_subfolder_name}
	echo -e "Full path of MD5 subfolder : "${cYellowBlack}${v_fullpath_md5}${cStandard}

    # RESULT FILE #1: "Summary"
    # Prepare "Summary" file
    v_summaryfile="${v_fullpath_md5:0:${#v_fullpath_md5} - 1 }_summary.txt"
    echo -e "Name of MD5 Summary file  : "${cGreenBlack}${v_summaryfile}${cStandard}
    # Create "Summary" file
    echo "##Summary file of all the '.md5info' files in folder: ${v_fullpath_md5}" >"${v_summaryfile}"
    echo "##Bytesize|File Content MD5|Path only MD5|Full Path MD5|Timestamp|Path only|File name|Full Path" >>"${v_summaryfile}"

    # RESULT FILE #2: "Multiples"
    # Prepare "Multiples" file
    v_multiplesfile="${v_fullpath_md5:0:${#v_fullpath_md5} - 1 }_multiples.txt"
    echo -e "Name of MD5 Multiples file : "${cGreenBlack}${v_multiplesfile}${cStandard}
    # Create "Multiples" file
    echo "##Multiples file of all the '.md5info' files in folder: ${v_fullpath_md5}" >"${v_multiplesfile}"
    echo "##Bytesize|File Content MD5|Path only MD5|Full Path MD5|Timestamp|Path only|File name|Full Path" >>"${v_multiplesfile}"
    
    if [[ -d "${v_fullpath_md5}" ]]
    then
        echo -e "MD5 subfolder exists       : "${cYellowBlack}${v_fullpath_md5}${cStandard}
    else
        echo -e "MD5 subfolder does ${cRed}NOT${cStandard} exist: "${cYellowBlack}${v_fullpath_md5}${cStandard}
        return 
    fi

    # Enter MD5 subfolder and start the work
    echo -e "Entering MD5 subfolder     : "${cYellowBlack}${v_fullpath_md5}${cStandard}
    cd "$v_fullpath_md5"

    # Filter to MD5info files
    v_fileformat="*${v_md5file_ext}"
    # loop through all files of the MD5 subfolder
    for i in $v_fileformat;
    do
        # if directory is empty, break the file loop!
        if [[ "$i" == "$v_fileformat" ]]; then echo "No Files"; break; fi
        # continue to next file if the current is a directory    
        if [[ -d "$i" ]]; then continue; fi
        
        # split filename into prefix (name) and suffix (extension)
        v_filename=$(basename "$i")
        v_extension="${v_filename##*.}"
        v_filename="${v_filename%.*}"
        
        # Work on file
        echo -e "Processing MD5 file: "${cGreenBlack}${i}${cStandard}
        
        # full MD5 file pathname and filename            
        v_filefull_now="${v_fullpath_md5}${i}"
        #echo "Pathname     : ${v_filefull_now}"

        # grep infos from file
        v_grepstring="Bytesize          :"
        v_fc_bytesize=$(     grep --max-count=1 -e "$v_grepstring" "$v_filefull_now" | cut --delimiter=":" -f 2 )
        echo "       ${v_grepstring} ${v_fc_bytesize}"
        v_grepstring="File Content MD5  :"
        v_fc_content_MD5=$(  grep --max-count=1 -e "$v_grepstring" "$v_filefull_now" | cut --delimiter=":" -f 2 )
        echo "       ${v_grepstring} ${v_fc_content_MD5}"
        v_grepstring="Path only MD5     :"
        v_fc_pathonly_MD5=$( grep --max-count=1 -e "$v_grepstring" "$v_filefull_now" | cut --delimiter=":" -f 2 )
        echo "       ${v_grepstring} ${v_fc_pathonly_MD5}"
        v_grepstring="Full Path MD5     :"
        v_fc_fullpath_MD5=$( grep --max-count=1 -e "$v_grepstring" "$v_filefull_now" | cut --delimiter=":" -f 2 )
        echo "       ${v_grepstring} ${v_fc_fullpath_MD5}"
        v_grepstring="Timestamp         :"
        v_fc_timestamp=$( grep --max-count=1 -e "$v_grepstring" "$v_filefull_now" | cut --delimiter=":" -f 2 )
        echo "       ${v_grepstring} ${v_fc_timestamp}"
        v_grepstring="Path only         :"
        v_fc_pathonly=$( grep --max-count=1 -e "$v_grepstring" "$v_filefull_now" | cut --delimiter=":" -f 2 )
        echo "       ${v_grepstring} ${v_fc_pathonly}"
        v_grepstring="File Name         :"
        v_fc_filename=$( grep --max-count=1 -e "$v_grepstring" "$v_filefull_now" | cut --delimiter=":" -f 2 )
        echo "       ${v_grepstring} ${v_fc_filename}"
        v_grepstring="Full Path         :"
        v_fc_fullpath=$( grep --max-count=1 -e "$v_grepstring" "$v_filefull_now" | cut --delimiter=":" -f 2 )
        echo "       ${v_grepstring} ${v_fc_fullpath}"
                     
        # write everything to analysis result file    
        #echo "Bytesize|File Content MD5|Path only MD5|Full Path MD5|Timestamp|Path only|File name|Full Path" >>"${v_summaryfile}"
        echo "${v_fc_bytesize}|${v_fc_content_MD5}|${v_fc_pathonly_MD5}|${v_fc_fullpath_MD5}|${v_fc_timestamp}|${v_fc_pathonly}|${v_fc_filename}|${v_fc_fullpath}" >>"${v_summaryfile}"
    done
    
    # after creating the analysis file, also generate the "multiples" file :            
    IFS=$'\n'       # Internal File Separator: make newlines the only separator
    set -f          # disable globbing
    # compare the first 2 fields (Bytesize + Content MD5) to determine uniqueness
    for y in $( cat "${v_summaryfile}" | cut --delimiter="|" -f 1,2 | uniq -d )
    do
        echo "Multiples found for (Bytesize|Content MD5): "$y
        grep -e "$y" "$v_summaryfile" >>"$v_multiplesfile"
    done
     
    echo -e "${cRed}FINISHED!${cStandard} All MD5 files have been analyzed."
	read -p "Press <Enter> to go back to main menu:" v_enterdummy
}

read_options(){
	local choice
	read -p "Enter choice [ 1 - 6 ] " choice
	case $choice in
		1) set_base_dir ;;
		2) set_md5_dir ;;
		3) set_md5_subfolder_name ;;
		4) start_batch ;;
		5) start_analysis ;;
		6) exit 0;;
		*) echo -e "${cRed}Error: Choice not available...${cStandard}" && sleep 2
	esac
}
 
# #######################
# ### START of script ###
# #######################
# Trap CTRL+C, CTRL+Z and quit singles
#trap '' SIGINT SIGQUIT SIGTSTP
 
# display title box
display_title

# check 1st parameter: Base directory (which holds the files of which to create MD5 hashes)
if [ "$1" == "" ]; then
	set_base_dir
else
	neat_pathname "$1"
	v_dir_base="$v_neatpathname" 
	# Check if it is a valid file system directory. If not, try again! 
	if ( [[ -d "$v_dir_base" ]] || [[ "$v_dir_base" == "~/" ]] )
    then echo -e "Parameter 1: Base directory exists: "${cYellowBlack}${v_dir_base}${cStandard}
	else echo -e "'$v_dir_base' is ${cRed}NOT${cStandard} a directory!"; set_base_dir 
	fi
fi

# check 2nd parameter: MD5 directory (in which to create the MD5 subfolder)
if [ "$2" == "" ]; then
	set_md5_dir
else
	neat_pathname "$2"
	v_dir_md5="$v_neatpathname"
	# Check if it is a valid file system directory. If not, try again! 
	if ( [[ -d "$v_dir_md5" ]] || [[ "$v_dir_md5" == "~/" ]] )
    then echo -e "Parameter 2:  MD5 directory exists: "${cYellowBlack}${v_dir_md5}${cStandard}
	else echo -e "'$v_dir_md5' is ${cRed}NOT${cStandard} a directory!"; set_md5_dir 
	fi
fi

# check 3rd parameter: MD5 subfolder name
v_md5_subfolder_name="MD5storage_${v_timestamp}/"
    # if 3rd parameter is not given (or is ".") then use default subfolder name
if ( [ "$3" == "" ] || [ "$3" == "." ] ); then
	#set_md5_subfolder_name
    echo -e "Parameter 3: Using default MD5 subfolder name: "${cYellowBlack}${v_md5_subfolder_name}${cStandard}
else
	neat_pathname "$3"
	v_md5_subfolder_name="$v_neatpathname"
    echo -e "Parameter 3: Using MD5 subfolder name: "${cYellowBlack}${v_md5_subfolder_name}${cStandard}
fi

# check 4th parameter: command action, "start batch" or "start analysis"
if ( [ "$4" == "batch" ] || [ "$4" == "BATCH" ] ); then
	echo "Skipping main menu. Starting batch processing now!"
    start_batch
    exit 0
elif ( [ "$4" == "analysis" ] || [ "$4" == "ANALYSIS" ] ); then 
    echo "Skipping main menu. Starting analysis of MD5 subfolder now!"
    start_analysis
    exit 0
fi

# this is the main program: an infinite loop ;-)
while true
do
	show_menu
	read_options
done

# END OF SCRIPT
