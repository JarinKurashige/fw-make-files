#!/bin/bash

# Default settings if none is specified
ADAPTER_SPEED=5000
INTERFACE="cmsis-dap.cfg"
TARGET="rp2350.cfg"

while getopts "i:t:b:f:" opt; do
	case $opt in
		i) INTERFACE="$OPTARG" ;;
		t) TARGET="$OPTARG" ;;
		b) ADAPTER_SPEED="$OPTARG" ;;
		f) FILE="$OPTARG" ;;
		*) echo "Usage: $0 -f <file.elf> [-i <interface.cfg>] [-t <target.cfg>] [-b <adapter speed>]"
			exit 1;;
	esac
done

if [[ -z "$FILE" ]]; then
	echo "Error: Missing required arguments"
	echo "Usage: $0 -f <file.elf> [-i <interface.cfg>] [-t <target.cfg>] [-b <adapter speed>]"
	exit 1
fi

echo "Scanning for CMSIS-DAP devices..."
CMSIS_DAP_SERIALS=($(lsusb -v 2>/dev/null | grep -A3 "CMSIS-DAP" | grep iSerial | awk '{print $3}'))

if [[ ${#CMSIS_DAP_SERIALS[@]} -eq 0 ]]; then
    echo "Error: No CMSIS-DAP devices found!"
    exit 1
elif [[ ${#CMSIS_DAP_SERIALS[@]} -eq 1 ]]; then
    SERIAL="${CMSIS_DAP_SERIALS[0]}"
    echo "Found one CMSIS-DAP device (serial: $SERIAL)"
else
    echo "Multiple CMSIS-DAP devices found:"
    for i in "${!CMSIS_DAP_SERIALS[@]}"; do
        echo "  [$i] ${CMSIS_DAP_SERIALS[$i]}"
    done

    read -p "Select device number to use: " SELECTION
    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || (( SELECTION < 0 || SELECTION >= ${#CMSIS_DAP_SERIALS[@]} )); then
        echo "Invalid selection"
        exit 1
    fi

    SERIAL="${CMSIS_DAP_SERIALS[$SELECTION]}"
    echo "Selected CMSIS-DAP serial: $SERIAL"
fi

# Run command
"$HOME/developer/toolchain/openocd/src/openocd" \
	-f "$HOME/developer/toolchain/openocd/tcl/interface/$INTERFACE" \
	-f "$HOME/developer/toolchain/openocd/tcl/target/$TARGET" \
	-c "adapter speed $ADAPTER_SPEED" \
	-c "adapter serial $SERIAL" \
	-c "program $FILE verify reset exit"
