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
OUTPUT_DIR="${TARGET_DIR}/csv_output"
mkdir -p "$OUTPUT_DIR"

# Error log
ERROR_LOG="${OUTPUT_DIR}/csv_errors.log"
> "$ERROR_LOG"

for file in "$TARGET_DIR"/*.volcano; do
    [ -e "$file" ] || continue

    base=$(basename "${file%.volcano}")

    echo "Processing $file..."

    ###########################################################
    # Select probe numbers based on filename
    ###########################################################

    case "$base" in

        # xL0p03 through xL0p59
        *xL0p03*|*xL0p1*|*xL0p3*|*xL0p4*|*xL0p5*)
            probes=(333 291 250 208 166)
            ;;

        # xL0p73
        *xL0p73*)
            probes=(311 269 227 186 144)
            ;;

        # xL0p86
        *xL0p86*)
            probes=(261 220 178 136 95)
            ;;

        # xL1p2 must come before xL1
        *xL1p2*)
            probes=(132 99 66 33 0)
            ;;

        # xL1
        *xL1*)
            probes=(208 166 125 83 42)
            ;;

        *)
            echo "WARNING: No probe mapping defined for $base" | tee -a "$ERROR_LOG"
            continue
            ;;
    esac

    ###########################################################
    # Build monitor variable list
    ###########################################################

    vars=()

    for p in "${probes[@]}"; do

        # Ensure 3-digit formatting (000, 033, 099, etc.)
        p=$(printf "%03d" "$p")

        vars+=(
            "${p}_density"
            "${p}_machnumber"
            "${p}_machnumberavg"
            "${p}_pressure"
            "${p}_pressureavg"
            "${p}_temperature"
            "${p}_velocitymag"
            "${p}_velocitymagavg"
            "${p}_velocityx"
            "${p}_velocityy"
            "${p}_velocityz"
        )

    done

    ###########################################################
    # Run monitor
    ###########################################################

    if monitor \
        -F "$file" \
        -X time \
        -Y "${vars[@]}" \
        -C ; then

        echo "SUCCESS: $file"

    else

        echo "ERROR: $file" | tee -a "$ERROR_LOG"
        # rm -f "${OUTPUT_DIR}/${base}.csv"
        continue

    fi

done

mv "$TARGET_DIR"/*.csv "$OUTPUT_DIR"/

echo "Finished processing all files."
echo "Results: $OUTPUT_DIR"
echo "Errors:  $ERROR_LOG"