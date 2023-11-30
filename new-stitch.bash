#!/bin/bash

# Check if directory is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

# Constants
DIRECTORY="$1"
[[ "${DIRECTORY}" != */ ]] && DIRECTORY="${DIRECTORY}/"

# Sanitize directory name for the output image filename
sanitized_dir_name=$(basename "$DIRECTORY" | sed 's/ /_/g')
OUTPUT_IMAGE="${sanitized_dir_name}_stitched_image.png"

# Array to hold all images
all_images=()

# Find all .png and .jpg files in the directory (not in subdirectories)
while IFS= read -r file; do
    all_images+=("$file")
done < <(find "$DIRECTORY" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" \))

# Check if any images were found
if [ ${#all_images[@]} -eq 0 ]; then
    echo "No PNG or JPG images found in the directory."
    exit 1
fi

# Initialize variables to track the largest width
max_width=0

# Loop through each image to find the largest width
for img in "${all_images[@]}"; do
    width=$(identify -format "%w" "$img")
    if [ "$width" -gt "$max_width" ]; then
        max_width=$width
    fi
done

# Temporary directory for processed images
temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT

# Process each image
for img in "${all_images[@]}"; do
    filename=$(basename "$img")
    width=$(identify -format "%w" "$img")
    # Calculate the amount of padding needed on each side
    padding=$(( (max_width - width) / 2 ))
    # Add white blocks to the left and right of the image
    convert "$img" -gravity center -background white -extent "${max_width}x" "$temp_dir/$filename"
done

# Stack all images vertically
montage "$temp_dir/"* -tile 1x -geometry +0+0 -background white "$OUTPUT_IMAGE"

echo "Stacked image created: $OUTPUT_IMAGE"
