#!/bin/bash
module purge 
module load volcano/2026.03.1

for file in *.volcano; do
    # Skip if no files match
    [ -e "$file" ] || continue

    echo "Processing $file..."

    monitor \
        -F "$file" \
        -X time \
        -Y 000_density 000_pressure 000_temperature \
        -C

    status=$?

    if [ $status -ne 0 ]; then
        echo "WARNING: Failed to process $file (exit code $status). Skipping..."
        continue
    fi

    echo "Successfully processed $file"
done

echo "Finished processing all files."