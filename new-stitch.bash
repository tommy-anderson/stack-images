#!/bin/bash

# Check if directory is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

# Constants
DIRECTORY="$1"
[[ "${DIRECTORY}" != */ ]] && DIRECTORY="${DIRECTORY}/"
HEIGHT_BOX=100 # Height of the white box
POINT_SIZE=50 # Font size for text
SIDE_PADDING=10 # Padding for each side

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

# Adjust max_width to account for side padding
max_width=$((max_width + 2 * SIDE_PADDING))

# Temporary directory for processed images
temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT

# Process each image
for img in "${all_images[@]}"; do
    filename=$(basename "$img")
    name_no_ext="${filename%.*}"

    # Step 1: Create a white box with the filename
    # -size: specify the size of the white box
    # xc:white: create a solid white image
    # -gravity center: set the text position to the center
    # -pointsize: set the font size for the annotation
    # -annotate: add the text annotation (filename without extension)
    convert -size "${max_width}x${HEIGHT_BOX}" xc:white -gravity center -pointsize $POINT_SIZE -annotate +0+0 "$name_no_ext" "$temp_dir/white_box_$filename"

    # Step 2: Append the white box to the top of the current image
    # -gravity north: ensure that the appending happens at the top
    # -append: append the white box image above the current image
    convert "$temp_dir/white_box_$filename" "$img" -gravity north -append "$temp_dir/$filename"

    # Clean up the temporary white box image
    rm -f "$temp_dir/white_box_$filename"
done

# Rest of the script remains the same


# Stack all images vertically and add side padding
montage "$temp_dir/"* -tile 1x -geometry +0+0 -background white miff:- | convert - -gravity center -background white -extent "${max_width}x" "$OUTPUT_IMAGE"

echo "Stacked image created: $OUTPUT_IMAGE"

# Clean up
rm -rf -- "$temp_dir"
