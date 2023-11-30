#!/bin/bash

# Check if parent directory is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <parent_directory_path>"
    exit 1
fi

# Parent directory
PARENT_DIR="$1"

# Loop through each subdirectory in the parent directory
for subdir in "$PARENT_DIR"/*; do
    if [ -d "$subdir" ]; then # Check if it's a directory
        echo "Processing directory: $subdir"
        bash stack-images.bash "$subdir"
    fi
done

echo "All subdirectories have been processed."
