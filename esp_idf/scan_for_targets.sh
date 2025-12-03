#!/usr/bin/env bash


printf "%-14s %-20s %-10s %-10s %-50s %-8s %-12s %-10s\n" \
"Port" "MAC Address" "Chip" "Revision" "Features" "Crystal" "Flash Size" "Vendor"
echo "--------------------------------------------------------------------------------------------------------------------------------------------"

for PORT in /dev/ttyUSB* /dev/ttyACM*; do
	[ -e "$PORT" ] || continue

	# ---- Get MAC ----
	MAC=$(esptool.py --port "$PORT" read_mac 2>/dev/null \
	    | grep "MAC:" \
	    | head -n1 \
	    | awk '{print $2}')

	[ -n "$MAC" ] || continue   # Only proceed if ESP is actually detected

	# ---- Get CHIP + REVISION + FEATURES + XTAL ----
	CHIPINFO=$(esptool.py --port "$PORT" chip_id 2>/dev/null)

	CHIP=$(echo "$CHIPINFO"      | grep "Chip is"        | awk '{print $3}')
	REV=$(echo "$CHIPINFO"       | grep "revision"       | awk '{print $NF}' | tr -d ')')
	FEATURES=$(echo "$CHIPINFO"  | grep "Features:"      | cut -d':' -f2 | sed 's/^ *//')
	XTAL=$(echo "$CHIPINFO"      | grep "Crystal is"     | awk '{print $3}')

	# ---- Get FLASH INFO ----
	FLASHINFO=$(esptool.py --port "$PORT" flash_id 2>/dev/null)

	FLSZ=$(echo "$FLASHINFO"     | grep "Detected flash size" | awk '{print $4}')
	VENDOR=$(echo "$FLASHINFO"   | grep "Manufacturer:" | awk '{print $2}')
	
	# Optional: convert hex vendor to name
	case "$VENDOR" in
	    0xC8|c8)  VENDOR="GigaDevice" ;;
	    0xEF|ef)  VENDOR="Winbond" ;;
	    0x20)     VENDOR="Micron" ;;
	    0x1F|1f)  VENDOR="Atmel" ;;
	    *)        VENDOR="$VENDOR" ;;
	esac

	printf "%-14s %-20s %-10s %-10s %-50s %-8s %-12s %-10s\n" \
	    "$PORT" "$MAC" "$CHIP" "$REV" "$FEATURES" "$XTAL" "$FLSZ" "$VENDOR"
done

exit 0
