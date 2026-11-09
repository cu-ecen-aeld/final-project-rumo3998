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
		DEFCONFIG=qemu_arm_versatile_custom_defconfig
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

#Verify that the compiler CACHE directory exists. If not create the directory.
if [ ! -d "$COMPILER_CACHE_DIR" ];
then
	echo "COMPILER_CACHE_DIR DNE"
	mkdir -p "$COMPILER_CACHE_DIR"
	echo "Successfully created COMPILER_CACHE_DIR"
	echo 
fi

#Verify that the output directory exists. If not create the directory.
if [ ! -d "$OUTPUT_DIR" ];
then
	echo "OUTPUT_DIR DNE"
	mkdir -p "$OUTPUT_DIR"
	echo "Successfully created OUTPUT_DIR"
	echo 
fi

#Confirm that both the external tree directory and its hooks exist if not create them and 
#the sub-directories 
if [ ! -d "$EXTERNAL_DIR" ] || [ ! -f "${EXTERNAL_DIR}/external.desc" ]
then
	echo "INFO: External build tree ($EXTERNAL_DIR) does not exist."
	echo "Starting build of external directory structure..."
	echo 

	mkdir -p "$EXTERNAL_DIR/configs"
	mkdir -p "$EXTERNAL_DIR/package"
	mkdir -p "$EXTERNAL_DIR/rootfs_overlay"

	#write the mandatory files
	echo -e "name: AESD\ndesc: Custom workspace for project tasks" > "$EXTERNAL_DIR/external.desc"
	echo -e "# Main external configuration menus\nmenu \"Custom Tools\"\n\nendmenu" > "$EXTERNAL_DIR/Config.in"
	touch "$EXTERNAL_DIR/external.mk"
	echo "Successfully created the directories."
	echo
fi

#Change directory to out of tree build
cd "$PROJ_DIR/$OUTPUT_DIR" || exit 1

#Determine if there is an existing defconfig
if [ -f "$EXTERNAL_DIR/configs/$DEFCONFIG" ]
then
	echo "Applying the custom saved defconfig \"recipe\""
	make -C "$PROJ_DIR/$BUILDROOT_DIR" O="$(pwd)" BR2_EXTERNAL="$EXTERNAL_DIR" \
	       	BR2_DL_DIR="$FILE_CACHE_DIR" BR2_CCACHE_DIR="$COMPILER_CACHE_DIR"  \
		"$DEFCONFIG"
else
	echo "Custom defconfig file DNE. Using default..."
	case $BUILD_OPT in
		1)
			#Qemu defconfig
			make -C "$PROJ_DIR/$BUILDROOT_DIR" O="$(pwd)" \
				BR2_EXTERNAL="$EXTERNAL_DIR" BR2_DL_DIR="$FILE_CACHE_DIR" \
				BR2_CCACHE_DIR="$COMPILER_CACHE_DIR" qemu_arm_versatile_defconfig
			;;
		2)
			#Beaglebone Black defconfig
			make -C "$PROJ_DIR/$BUILDROOT_DIR" O="$(pwd)" \
				BR2_EXTERNAL="$EXTERNAL_DIR" BR2_DL_DIR="$FILE_CACHE_DIR" \
				BR2_CCACHE_DIR="$COMPILER_CACHE_DIR" beaglebone_defconfig
			;;
		*)
			#Should never execute since checked up front
			echo "ERROR: Invalid Selection"
			exit 1
			;;
	esac
fi 

#Start compilation
echo 
echo "Beginning the compilation of the $OUTPUT_DIR"
make all
echo "Build completed successfully..."

#Ensure file permissions are unaffected and then exit
chmod 755 "$PROJ_DIR/${0##*/}"
echo "Exiting build tools successfully..."
echo
exit 0
