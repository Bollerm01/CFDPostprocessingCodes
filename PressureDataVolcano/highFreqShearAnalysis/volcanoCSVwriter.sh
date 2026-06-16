#!/bin/bash

module purge 
module load volcano/2026.03.1

TARGET_DIR="$1"

if [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "ERROR: Directory does not exist: $TARGET_DIR"
    exit 1
fi

# Create output folder
OUTPUT_DIR="${TARGET_DIR}/csv_output"
mkdir -p "$OUTPUT_DIR"

# Error log
ERROR_LOG="${OUTPUT_DIR}/monitor_errors.log"
> "$ERROR_LOG"

for file in "$TARGET_DIR"/*.volcano; do
    [ -e "$file" ] || continue

    base=$(basename "${file%.volcano}")

    echo "Processing $file..."

    if monitor \
        -F "$file" \
        -X time \
        -Y 000_density 000_machnumber 000_machnumberavg 000_pressure 000_pressureavg 000_temperature 000_velocitymag 000_velocitymagavg  000_velocityx  000_velocityy  000_velocityz \
        125_density 125_machnumber 125_machnumberavg 125_pressure 125_pressureavg 125_temperature 125_velocitymag 125_velocitymagavg  125_velocityx  125_velocityy  125_velocityz \
        250_density 250_machnumber 250_machnumberavg 250_pressure 250_pressureavg 250_temperature 250_velocitymag 250_velocitymagavg  250_velocityx  250_velocityy  250_velocityz \
        374_density 374_machnumber 374_machnumberavg 374_pressure 374_pressureavg 374_temperature 374_velocitymag 374_velocitymagavg  374_velocityx  374_velocityy  374_velocityz \
        499_density 499_machnumber 499_machnumberavg 499_pressure 499_pressureavg 499_temperature 499_velocitymag 499_velocitymagavg  499_velocityx  499_velocityy  499_velocityz \
        -C > "${OUTPUT_DIR}/${base}.csv"; then

        echo "SUCCESS: $file"

    else

        echo "ERROR: $file" | tee -a "$ERROR_LOG"
        rm -f "${OUTPUT_DIR}/${base}.csv"
        continue

    fi
done

echo "Finished processing all files."
echo "Results: $OUTPUT_DIR"
echo "Errors:  $ERROR_LOG"