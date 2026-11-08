#!/bin/sh

#Author: Ruben Moreno
#Date: November 5th, 2026

#Configuration
PROJ_DIR="$(pwd)"
BUILDROOT_DIR=buildroot/buildroot
CACHE_DIR=/mnt/DataStorage/ECEN5713/dl
QEMU_DIR=qemu_build
BEAGLE_DIR=beaglebone_build
CACHE_EXISTS=0
FUNC_LIMITED=0

#Ensure this is being run from the root directory of the project
#If this directory does not exist do an exit 1.
if [ ! -d "$BUILDROOT_DIR" ]
then
	echo "ERROR: BUILDROOT_DIR:($BUILDROOT_DIR) does not exist. Run this from the root of the
	project."
	exit 1
fi

#Determine if tools will be run for BBB or Qemu builds
#Helper menu
echo "******************************************************************************"
echo "|                           Buildroot cleaning tools setup                    |"
echo "******************************************************************************"
echo "1) Qemu build tools              - Configured to run clean tools on qemu builds."
echo
echo "2) BeagleBone Black build tools  - Configured to run clean tools on BBB builds."
echo "******************************************************************************"

#Parse the input from the command line and save into BUILD_OPT. read -p allows us to 
#specify a prompt.
read -p "Select an option [1-2]: " BUILD_OPT

case $BUILD_OPT in 
	1)
		echo "Running OPT 1: Qemu clean tools"
		OUTPUT_DIR=$QEMU_DIR
		;;
	2)
		echo "Running OPT 2: BeagleBone clean tools"
		OUTPUT_DIR=$BEAGLE_DIR
		;;
	*)	
		echo "Error: Invalid selection made"
		exit 1
		;;
esac

#Verify if the CACHE is available to clear. 
if [ -d "$CACHE_DIR" ];
then
	CACHE_EXISTS=1
fi

#Confirm whether the out of tree build has been executed previously if so leverage
#the out of build wrapped scripts, by CD to directory and run cmds in directory 
if [ -d "$OUTPUT_DIR" ] && [ -f "${OUTPUT_DIR}/Makefile" ]
then
	echo "INFO: Out of tree build for build: ($OUTPUT_DIR) exists. Run this from the
	out of tree build directory directly."
	
	#Change directory to out of tree build
	cd "$PROJ_DIR/$OUTPUT_DIR" || exit 1
else
	echo "INFO: Out of tree build for build: ($OUTPUT_DIR) does not exist."

	#Determine whether to run cleans on cache or dl, where out of tree buids
	#are not required to have been created to run these tasks
	if [ -d "$CACHE_DIR" ]
	then
		echo "INFO: Functionality limited, only valid cmd: clean cache."
		FUNC_LIMITED=1
	fi
fi

#Determine whether to print helper menu in limited functionality mode or not.

if [ 1 -eq "$FUNC_LIMITED" ]
then
	echo "*****************************************************************"
	echo "|                   Limited clean tool                          |"
	echo "*****************************************************************"
	echo "1) Cache clean (rm dl)           - Deletes the dl folder that 
	holds the downloaded archives"
	echo "2) Exit                          - Exit cleaning tools menu"
	echo "*****************************************************************"

	#parse the input for the limited clean tool
	read -p "Select an option [1-2]: " OPT
	case $OPT in 
		1)
			echo "Cleaning cache..."
			if [ $CACHE_EXISTS -eq 1 ]
			then 
				rm -rf "${CACHE_DIR}"/*
				echo "Cleaning cache successful"
			else
				echo "No cache to clear."
			fi
			;;
		2)
			echo "Exiting limited clean tools menu."
			;;
	esac
else
	#Helper menu
	echo "******************************************************************************"
	echo "|                           Buildroot cleaning tools                         |"
	echo "******************************************************************************"
	echo "1) Standard clean (make clean)   - Deletes all compilation artifacts aside 
	                                   from config and toolchain."
	echo
	echo "2) Better clean (make distclean) - Deletes all compilation artifacts including
	                                   config and toolchain."
	echo
	echo "3) Deep Clean                    - Deletes all compilation artifacts including
	                                   config and toolchain in addition to clearing 
					   dl(downloaded archives). disclean + empties cache"
	echo
	echo "4) Package clean (make dirclean) - Deletes custom packag build files"
	echo
	echo "5) Cache clean (rm dl)           - Deletes the dl folder that holds the
        	                           downloaded archives"
	echo
	echo "6) Fresh build (make clean all)  - Guaranteed clean rebuild, keeps configs"
	echo 
	echo "7) Exit                          - Exit Buildroot cleaning tools menu"
	echo "******************************************************************************"

	#Parse the input from the command line and save into OPT. read -p allows us to 
	#specify a prompt.
	read -p "Select an option [1-7]: " OPT

	case $OPT in 
		1)
			echo "Running OPT 1: make clean"
			make clean
			echo "Make Clean successful"	
			;;
		2)
			echo "Running OPT 2: make distclean"
			make distclean 
			echo "Make distclean successful"	
			;;
		3)
			echo "Running OPT 3: delete all"
			if [ $CACHE_EXISTS -eq 1 ]
			then
				rm -rf "${CACHE_DIR}"/*
				echo "Clean all successful"
			else
				echo "No cache to clear"
			fi
			make distclean
			echo "Make distclean successful"
			;;
		4)
			echo "Running OPT 4: make dirclean"
			echo "Usage: Enter the raw package name only 
			(e.g., busybox, glibc)"
			read -p "Package name: " PKG
			if [ -n "$PKG" ]
			then 
				echo "Running dirclean on $PKG..."
				make "${PKG}-dirclean"
			else
				echo "No Package specified"
			fi
			;;
		5)
			echo "Running OPT 5: Cache Clean"
	
			#check if dir exists and if so clear it. 
			if [ -d "$CACHE_DIR" ]
			then
				rm -rf "${CACHE_DIR}"/*
				echo "Cache clean successful"
			else
				echo "No Cache to clear"
			fi
			;;
		6)
			echo "Running OPT 6: make clean all"
			make clean all 
			echo "Make clean all successful"	
			;;
		7)
			echo "Exiting buildroot cleaning tools"
			;;
		*)
			echo "Error: Invalid selection made"
			exit 1
			;;
	esac
fi #end if then for menu

#Ensure file permissions are unaffected and then exit
chmod 755 "$0"
echo "exiting build tools successfully..."
exit 0

