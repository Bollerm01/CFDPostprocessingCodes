#!/bin/bash

module purge 
module load volcano/2025.10

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
OUTPUT_DIR="${TARGET_DIR}/kulite_output"
mkdir -p "$OUTPUT_DIR"

# Error log
ERROR_LOG="${OUTPUT_DIR}/kulite_errors.log"
> "$ERROR_LOG"

for file in "$TARGET_DIR"/k*.volcano; do
    [ -e "$file" ] || continue

    base=$(basename "${file%.volcano}")

    echo "Processing $file..."

    if monitor \
        -F "$file" \
        -X time \
        -Y 000_density 000_pressure 000_pressureavg 000_temperature 000_velocitymag 000_velocitymagavg  000_velocityx \
        -C ; then

        echo "SUCCESS: $file"

    else

        echo "ERROR: $file" | tee -a "$ERROR_LOG"
        #rm -f "${OUTPUT_DIR}/${base}.csv"
        continue

    fi
done

mv "$TARGET_DIR"/*.csv "$OUTPUT_DIR"/

echo "Finished processing all files."
echo "Results: $OUTPUT_DIR"
echo "Errors:  $ERROR_LOG"