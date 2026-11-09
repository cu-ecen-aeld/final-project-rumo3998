#!/bin/bash

#Author: Ruben Moreno
#Date: November 9th, 2026

#Configuration
PROJ_DIR="$(pwd)"
BUILDROOT_DIR=buildroot/buildroot
EXTERNAL_DIR="${PROJ_DIR}/base_external"
QEMU_DIR=qemu_build
BEAGLE_DIR=beaglebone_build

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
echo "|                           Buildroot build tools setup                      |"
echo "******************************************************************************"
echo "1) Save Qemu Configuration        - Minimizes and exports current Qemu config."
echo
echo "2) Save BeagleBB Configuration    - - Minimizes & exports current BBB config. "
echo "******************************************************************************"
echo 

#Parse the input from the command line and save into BUILD_OPT. read -p allows us to 
#specify a prompt.
read -p "Select an option [1-2]: " BUILD_OPT

case $BUILD_OPT in 
	1)
		echo "Running OPT 1: Save Qemu configuration"
		OUTPUT_DIR=$QEMU_DIR
		DEFCONFIG=qemu_arm_vexpress_custom_defconfig
		;;
	2)
		echo "Running OPT 2: Save BeagleBone configuration"
		OUTPUT_DIR=$BEAGLE_DIR
		DEFCONFIG=beaglebone_custom_defconfig
		;;
	*)	
		echo "Error: Invalid selection made"
		exit 1
		;;
esac

#Verify that there exists an active .config in the build directory. If not run
#build tools first.  
if [ ! -f "$PROJ_DIR/$OUTPUT_DIR/.config" ];
then
	echo "ERROR: No active .config found in the $PROJ_DIR/$OUTPUT_DIR"
	echo "You must run build.sh and configure your environment before running this script."
	exit 1 
fi

DEFCONFIG_PATH="$EXTERNAL_DIR/configs/$DEFCONFIG"
mkdir -p "$EXTERNAL_DIR/configs"

echo 
echo " Saving Configurations for Target Profile: ${OUTPUT_DIR^^}"
echo " Targeting Build Output Folder:            $PROJ_DIR/$OUTPUT_DIR"
echo " Saving Defconfig File To:                 $DEFCONFIG_PATH"
echo 

#make out of tree build
make -C "$PROJ_DIR/$OUTPUT_DIR" BR2_DEFCONFIG="$DEFCONFIG_PATH" savedefconfig

#Check if the linux configuration exists and or has changed
if ls "$PROJ_DIR/$OUTPUT_DIR"/build/linux-*/.config 1> /dev/null 2>&1
then 
	if grep -q "BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE" "$PROJ_DIR/$OUTPUT_DIR/.config"
	then 
		echo "Linux kernel updates were found. Saving changes..."
		echo 
		make -C "$PROJ_DIR/$OUTPUT_DIR" linux-update-defconfig
	fi
fi

echo "Configuration save complete for $OUTPUT_DIR"

#Ensure file permissions are unaffected and then exit
chmod 755 "$PROJ_DIR/${0##*/}"
echo "Exiting build tools successfully..."
echo
exit 0
