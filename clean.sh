#!/bin/sh

#Author: Ruben Moreno
#Date: November 5th, 2026

#Configuration
BUILDROOT_DIR=buildroot/buildroot

#Ensure this is being run from the root directory of the project
#If this directory does not exist do an exit 1.
if [ ! -d "$BUILDROOT_DIR" ]
then
	echo "ERROR: BUILDROOT_DIR:($BUILDROOT_DIR) does not exist. Run this from the root of the" \
	"project."
	exit 1
fi

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
echo "3) Best clean (ALL)              - Deletes all compilation artifacts including
                                   config and toolchain in addition to clearing 
				   dl(downloaded archives)."
echo
echo "4) Package clean (make dirclean) - Deletes custom packag build files"
echo
echo "5) Cache clean (rm dl)           - Deletes the dl folder that holds the
                                   downloaded archives"
echo
echo "6) Exit                          - Exit Buildroot cleaning tools menu"
echo "******************************************************************************"

#Parse the input from the command line and save into OPT. read -p allows us to 
#specify a prompt.
read -p "Select an option [1-6]: " OPT

case $OPT in 
	1)
		echo "Running OPT 1: make clean"
		make -C "$BUILDROOT_DIR" clean 
		;;
	2)
		echo "Running OPT 2: make distclean"
		make -C "$BUILDROOT_DIR" distclean 
		;;
	3)
		echo "Running OPT 3: delete all"
		make -C "$BUILDROOT_DIR" distclean 

		;;
	4)
		echo starting_2
		;;
	5)
		echo starting_1
		;;
	6)
		echo starting_2
		;;
	*)
		echo dont know
		;;
esac

#Ensure file permissions are unaffected
chmod 755 clean.sh
