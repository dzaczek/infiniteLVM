#!/bin/bash

# -----------------------------------------------------------------------------
# Project       : InfiniteLVM
# Script name   : my_script.sh
# Author        : JZ
# Email         : infinitelvm@sysop.cat
# License       : MIT License
# Version       : 1.0.0
# Created       : 13 September 2023
# Description   : This is a sample sscipt is de
# Usage         : ./InfiniteLVM.sh -v
# -----------------------------------------------------------------------------

# Your script content goes here

# Define the VG name
VG_NAME="ubuntu-vg"

#Do not edit this part
VG_UUID=$(vgdisplay | awk -v vg_name=$VG_NAME '/VG Name/{vg=$3} /VG UUID/ {print $3}')

# Define the minimum free space percentage for LVs to start extending  (e.g., 12%)
MIN_FREE_PERCENTAGE_LV=12
FULL=100
((MAX_USE_PERCENTAGE = FULL - MIN_FREE_PERCENTAGE_LV))
# Define the minimum free space percentage for the VG (e.g., 2)
MIN_GB_LEFT_VG=2

verbose=0
dry=0
foutput() {
        if [ $verbose -eq 1 ]; then
                colors=("\033[32m" "\033[33m" "\033[31m" "\033[34m")

                local message="$1"
                local status="$2"

                case $status in
                "info")
                        # Green color
                        echo -e "${colors[0]}INFO:\033[0m $message"
                        ;;
                "warning")
                        # Yellow color
                        echo -e "${colors[1]}WARNING:\033[0m $message"
                        ;;
                "error")
                        # Red color
                        echo -e "${colors[2]}ERROR:\033[0m $message"
                        ;;
                "exec")
                        # Red color
                        echo -e "${colors[3]}EXEC: $message \033[0m"
                        ;;


                *)
                        # Default color
                        echo "$status $message"
                        ;;
                esac

        fi

}


print_help() {
        echo "Usage: $0 [options]"
        echo "Options:"
        echo -e "  -d    Enable dry run checking but not executing commands\n         run with -v "
        echo "  -v    Enable verbose output"
        echo "  -h    Show this help message"
        echo
        echo "Additional Information:"
        echo "  Edit the VG_NAME variable in the script to 'ubuntu-vg' or your desired Volume Group name."
        echo
        echo "Cron Setup:"
        echo "  To run this script every 10 minutes, add the following line to your crontab:"
        echo "    */10 * * * * /path/to/infinitelvm.sh"
}

# Parse command-line options
while getopts ":vhd" opt; do
        case $opt in
        v) verbose=1 ;;
        d) dry=1 ;;
        h)
                print_help
                exit 0
                ;;
        \?)
                echo "Invalid option: -$OPTARG" >&2
                print_help
                exit 1
                ;;
        esac
done

# Remove the options that have been parsed by getopts
shift $((OPTIND - 1))



# Function to check and extend LVs
check_and_extend_lvs() {
        # Get a list of all LVs in the specified VG
        LV_LIST=$(lvdisplay --units $((1042 * 1024 * 1024))b | awk -v vg_name="ubuntu-vg" '/LV Name/{lv_name=$3} /VG Name/{vg=$3} /LV UUID/{uuid=$3} /Block device/{bdev=$3} /LV Size/ && vg == vg_name {print lv_name, $3, uuid, bdev}')
        # Loop through each LV in the VG
        while read -r LV_NAME LV_SIZE LV_UUID DM; do

                foutput "$LV_NAME $LV_SIZE $LV_UUID" "info"
                DISK_PATH=$(echo "/dev/disk/by-id/dm-uuid-LVM-$(echo $VG_UUID | sed 's/-//g')$(echo $LV_UUID | sed 's/-//g')")
                FILESYSTEM=$(blkid -s TYPE -o value $DISK_PATH)

                if [ $? -eq 0 ]; then

                        # Check if the filesystem is ext2, ext3, or ext4
                        if [[ "$FILESYSTEM" == "ext2" || "$FILESYSTEM" == "ext3" || "$FILESYSTEM" == "ext4" ]]; then
                                foutput "The filesystem is $FILESYSTEM." "info"
                                # Get the current free space percentage for the LV
                                USE_PERCENTAGE=$(df $DISK_PATH --output=pcent | grep -oe '\([0-9.]*\)')
                                ((FREE_PERCENTAGE = FULL - USE_PERCENTAGE))
                                if [ "$FREE_PERCENTAGE" -lt "$MIN_FREE_PERCENTAGE_LV" ]; then
                                        # Perform LV extension
                                        foutput "Extending $VG_NAME/$LV_NAME by 1GB..." "info"
                                        if [ $dry -eq 0 ]; then

                                                lvextend -L +1G "$VG_NAME/$LV_NAME"
                                        else

                                                foutput "executing[ lvextend -L +1G '$VG_NAME/$LV_NAME']" "exec"
                                        fi

                                        # Resize the filesystem
                                        foutput "Resizing the filesystem for $VG_NAME/$LV_NAME..." "info"
                                        if [ $dry -eq 0 ]; then

                                                resize2fs $DISK_PATH
                                        else

                                                foutput "executing[ resize2fs  $DISK_PATH]" "exec"
                                        fi
                                else
                                        foutput "Free space for $VG_NAME/$LV_NAME(${FREE_PERCENTAGE}%) is above the threshold ($MIN_FREE_PERCENTAGE_LV%)" "info"
                                fi
                        else
                                foutput "unsupported filesystem ($FILESYSTEM)." "warning"
                        fi

                else

                        foutput "Warning: Could not determine the file system type." "error"

                fi

        done \
                <<<"$LV_LIST"
}

# Function to check free space in the VG
check_free_space_vg() {
        # Get the current free space percentage for the VG

        VG_FREE_GB=$(vgs --noheadings -o vg_name,vg_free $VG_NAME --units $((1024 * 1024 * 1024))b | awk '{ gsub(/[^0-9.]/, "", $2); print $2 }')

        if [ "${VG_FREE_GB%.*}" -lt "$MIN_GB_LEFT_VG" ]; then
                status=$(echo "Free space in $VG_NAME is below the threshold ($MIN_GB_LEFT_VG). Cannot extend LVs.")
                foutput "$status" "warning"
        else
                status=$(echo "Free space in $VG_NAME is sufficient ($VG_FREE_GB%). Proceeding with LV checks...")
                foutput "$status" "info"
                check_and_extend_lvs
        fi
}

# Execute the VG check function
check_free_space_vg

