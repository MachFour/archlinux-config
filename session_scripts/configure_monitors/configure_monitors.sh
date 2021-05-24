#! /bin/bash

# uses Xrandr to configure monitor outputs to one of a number of preset configurations

# when xf86-video-intel driver is used, there is no dash. When modesetting is used, there is a dash
DASH=-

# the following logic is used to figure out which (system-specific) display adapters are to be used
# when configuring displays with xrandr. They should be a subset of what's found in /sys/class/drm/

SYSTEM=$(cat /sys/devices/virtual/dmi/id/product_name)

EXT_DPI=96
UHD_DPI=140

case $SYSTEM in
	20XWCTO1WW)
		# Thinkpad X1 Carbon 9th Gen
		LAPTOP=eDP${DASH}1
		LAPTOP_RES=1920x1200
		LAPTOP_DPI=120
		EXT1=HDMI${DASH}1
		EXT2=DP${DASH}2
		EXT3=DP${DASH}1
		;;
	20HRCTO1WW)
		# ThinkPad X1 Carbon 5th Gen
		# no non-dash support yet
		LAPTOP=eDP${DASH}1
		LAPTOP_RES=1920x1080
		LAPTOP_DPI=120
		EXT1=HDMI${DASH}1
		EXT2=DP${DASH}2
		EXT3=DP${DASH}1
		;;
	3354CTO)
		# ThinkPad Edge E330
		LAPTOP=LVDS${DASH}1
		LAPTOP_RES=1366x768
		LAPTOP_DPI=96
		EXT1=HDMI${DASH}1
		EXT2=VGA${DASH}1
		# doesn't exist
		EXT3=BLAHBLAH
		;;
	*)
		echo "This script isn't configured for your computer!"
		exit 1
		;;
esac

# laptop setup (index 0)
#|================================|
#|                                |
#|                                |
#|                                |
#|       LVDS-1 (1366x768)        |
#|   OR   eDP-1 (1920x1080)       |
#|                                |
#|                                |
#|                                |
#|================================|


# single setup (index 1)
# EXT1 and LAPTOP mirrored

# home 'up' setup (index 2)
#|====================================|========================|
#|                                    |                        |
#|                                    |                        |
#|                                    |                        |
#|               EXT1                 |                        |
#|            (1600x1200)             |                        |
#|                                    |         EXT2           |
#|                                    |      (1200x1600)       |
#|                                    | (monitor rotated left) |
#|                                    | (screen rotated right) |
#|                                    |                        |
#|====================================|                        |
#                                     |                        |
#                                     |                        |
#                                     |                        |
#                                     |                        |
#                                     |                        |
#                                     |========================|

# home 'down' setup (index 3)
#                                     |========================|
#                                     |                        |
#                                     |                        |
#                                     |                        |
#                                     |                        |
#                                     |                        |
#                                     |         EXT2           |
#|====================================|      (1200x1600)       |
#|                                    | (monitor rotated left) |
#|                                    | (screen rotated right) |
#|                                    |                        |
#|               EXT1                 |                        |
#|            (1600x1200)             |                        |
#|                                    |                        |
#|                                    |                        |
#|                                    |                        |
#|                                    |                        |
#|====================================|========================|
# in both of the following functions
# $1 is the name of the mode that was requested

# zurich setup (index 4)
# (laptop off)
#|==========================================|
#|                                          |
#|                                          |
#|                                          |
#|                   EXT1                   |
#|                (1920x1080)               |
#|                                          |
#|                                          |
#|                                          |
#|                                          |
#|                                          |
#|==========================================|

# UHD setup (index 5)
# (laptop off)
#|==========================================|
#|                                          |
#|                                          |
#|                                          |
#|                   EXT1                   |
#|                (3840x2160)               |
#|                                          |
#|                                          |
#|                                          |
#|                                          |
#|                                          |
#|==========================================|

function success_msg () {
	echo 'Reconfigured monitors for' "$1"
}

function failure_msg () {
	echo 'Failed to reconfigure monitors for' "$1" >&2
}

function set_dpi () {
	dpi="$1"
	echo "Xft.dpi: $dpi" | xrdb -override
	xrandr --dpi $dpi
}

function home_setup {
	if [[ $1 == 'down' ]]; then
		local pos=0x400
	else
		local pos=0x0
	fi
	set_dpi $EXT_DPI && \
	xrandr --verbose --output ${EXT1} --mode 1600x1200 --rotate normal --primary --pos $pos && \
	xrandr --verbose --output ${EXT2} --mode 1600x1200 --rotate right --pos 1600x0 && \
	xrandr --output ${LAPTOP} --off
	if [[ $? -ne 0 ]]; then
		failure_msg ${FUNCNAME[0]}
		return 1
	else
		success_msg ${FUNCNAME[0]}
		return 0
	fi

}
# assumes both HDMI and VGA connected
function home_up_setup {
	home_setup up
}

function home_down_setup {
	home_setup down
}

function laptop_setup {
	set_dpi $LAPTOP_DPI && \
	xrandr --output ${LAPTOP} --primary --auto && \
	xrandr --output ${EXT1} --off --output ${EXT2} --off
	if [[ $? -ne 0 ]]; then
		failure_msg ${FUNCNAME[0]}
		return 1
	else
		success_msg ${FUNCNAME[0]}
		return 0
	fi
}

function single_setup {
	if is_connected ${EXT1}; then
		set_dpi $EXT_DPI
		xrandr --verbose --output ${EXT1} --auto --primary \
			--output ${EXT2} --off --output ${LAPTOP} --off
	elif is_connected ${EXT2}; then
		set_dpi $EXT_DPI
		xrandr --verbose --output ${EXT2} --auto --primary \
			--output ${EXT1} --off --output ${LAPTOP} --off
	elif is_connected ${EXT3}; then
		set_dpi $EXT_DPI
		xrandr --verbose --output ${EXT3} --auto --primary \
			--output ${EXT1} --off --output ${EXT2} --off --output ${LAPTOP} --off
	else
		set_dpi $LAPTOP_DPI
		laptop_setup
	fi
	if [[ $? -ne 0 ]]; then
		failure_msg ${FUNCNAME[0]}
		return 1
	else
		success_msg ${FUNCNAME[0]}
		return 0
	fi
}

function zurich_setup {
	set_dpi $EXT_DPI && \
	xrandr --verbose --output ${EXT1} --mode 1920x1080 --rotate normal --primary && \
	xrandr --output ${LAPTOP} --off
	if [[ $? -ne 0 ]]; then
		failure_msg ${FUNCNAME[0]}
		return 1
	else
		success_msg ${FUNCNAME[0]}
		return 0
	fi
}

function uhd_setup {
	set_dpi ${UHD_DPI}
	local ext
	if is_uhd HDMI-A-1; then
		ext=${EXT1}
	elif is_uhd ${EXT2}; then
		ext=${EXT2}
	else
		ext=${EXT3}
	fi
	xrandr --verbose --output ${ext} --mode 3840x2160 --rotate normal --primary && \
	xrandr --output ${LAPTOP} --off
	if [[ $? -ne 0 ]]; then
		failure_msg ${FUNCNAME[0]}
		return 1
	else
		success_msg ${FUNCNAME[0]}
		return 0
	fi
}

# this function should not print anything
function is_connected {
    #if [[ $(cat /sys/class/drm/card0-$1/status) == "connected" ]]; then
	if xrandr | grep -E -e "^$1 connected" &>/dev/null; then
		return 0
	else
		return 1
	fi
}

# this function should not print anything
function is_uhd {
    if grep '3840x2160' "/sys/class/drm/card0-$1/modes" &>/dev/null; then
		return 0
	else
		return 1
	fi
}

# Writes to stdout the index of the suggested setup
# essentially returns the number of externally connected displays
function auto_detect_setup () {
	if is_connected ${EXT1} && is_connected ${EXT2}; then
		echo home_up
	elif is_connected ${EXT1}; then
		if is_uhd ${EXT1}; then
			echo uhd
		else
			echo single
		fi
	elif is_connected ${EXT2}; then
		if is_uhd ${EXT2}; then
			echo uhd
		else
			echo single
		fi
	elif is_connected ${EXT3}; then
		if is_uhd ${EXT3}; then
			echo uhd
		else
			echo single
		fi
	else
		echo 0
	fi
}

function ensure_installed () {
	prog=$1
	if ! which "$prog" &>/dev/null; then
		echo "Cannot find required program $1, aborting."
		exit 1
	fi
}

function apply_setup {
	ensure_installed xrandr
	ensure_installed xrdb

	case $1 in
		(5 | uhd)
			uhd_setup	
			;;
		(4 | zurich)
			zurich_setup
			;;
		(3 | home_down)
			home_down_setup
			;;
		(2 | home_up)
			home_up_setup
			;;
		(1 | single)
			single_setup
			;;
		(0 | laptop)
			laptop_setup
			;;
		(*)
			echo 'No or unrecognised configuration given, performing auto-detect...'
			setup=$(auto_detect_setup)
			echo "Detected setup $setup, applying..."
			apply_setup $setup
			;;
	esac
}

function print_help () {
	echo "configure_monitors: configures a custom monitor setup."
	echo "Specify the name of the setup to apply, or anything else to auto-detect."
	echo
	echo "--dryrun: Performs an auto detect and displays the detected setup"
	echo "          without making any changes to the display settings."
}

if [[ ! -v DISPLAY ]]; then
	echo 'Could not read DISPLAY environment variable, please provide it' >&2
	exit 1
fi

shopt -q -s extglob

case $1 in
	(--dryrun)
		echo -n 'Auto detecting setup... '
		auto_detect_setup
		;;
	([^-]*)
		apply_setup $1
		;;
	(*)
		print_help
		;;
esac

# propagate any error return values from setup functions
if [[ $? -ne 0 ]]; then
	echo "Return value from xrandr in configure_monitors was nonzero; returning 0 anyway..."
	exit 0
else
	exit 0
fi
