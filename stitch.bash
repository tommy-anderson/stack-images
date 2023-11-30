#!/bin/bash

# Check if directory is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

# Constants
DIRECTORY="$1/"
# Max width of output image in px
THRESHOLD=1600
# Gap between images in px
GAP=35
# Height of white box in px
HEIGHT_BOX=100
# Y position of text in px
y_position=30
# Font size of text in px
POINT_SIZE=50

# Running sum of width
current_width=0
# Running sum of height
current_height=0
row_images=()
output_rows=()
row_count=0

for file in ${DIRECTORY}*.png; do
    img_width=$(identify -format "%w" "$file")
    
    # Check if adding this image exceeds threshold
    if [ $((current_width + img_width + GAP)) -gt $THRESHOLD ] || [ ${#row_images[@]} -eq 0 ]; then
        # Process all previous images in row_images if they exist
        if [ ${#row_images[@]} -gt 0 ]; then
            row_count=$((row_count+1))
            montage "${row_images[@]}" -tile x1 -geometry +$GAP+0 -background white "row_temp_${row_count}.png"
            
            # Add white box above and annotate
            width=$(identify -format "%w" "row_temp_${row_count}.png")
            convert -size ${width}x$HEIGHT_BOX xc:white "row_temp_${row_count}.png" -append "annotated_row_${row_count}.png"
            
            # Annotate each image
            local_x=0
            for img in "${row_images[@]}"; do
                name=$(basename -- "$img" .png)
                half_img_width=$(identify -format "%[fx:w/2]" "$img")
                text_width=$(convert -debug annotate -pointsize $POINT_SIZE -annotate 0 "$name" null: 2>&1 | awk '/width:/ { print $2 }' | cut -d'+' -f1)
                half_text_width=$((text_width / 2))
                center_x_position=$((local_x + half_img_width - half_text_width))
                convert "annotated_row_${row_count}.png" -gravity northwest -pointsize $POINT_SIZE -annotate +${center_x_position}+${y_position} "$name" "annotated_row_${row_count}.png"
                local_x=$((local_x + half_img_width*2 + GAP))
            done
            
            # Save the annotated row to a list
            output_rows+=("annotated_row_${row_count}.png")
            
            # Reset
            row_images=()
            current_width=0
        fi
    fi
    
    row_images+=("$file")
    current_width=$((current_width + img_width + GAP))
done

# Process any remaining images in row_images
if [ ${#row_images[@]} -gt 0 ]; then
    row_count=$((row_count+1))
    montage "${row_images[@]}" -tile x1 -geometry +$GAP+0 -background white "row_temp_${row_count}.png"
    width=$(identify -format "%w" "row_temp_${row_count}.png")
    convert -size ${width}x$HEIGHT_BOX xc:white "row_temp_${row_count}.png" -append "annotated_row_${row_count}.png"

    # Annotate each image
    local_x=0
    for img in "${row_images[@]}"; do
        name=$(basename -- "$img" .png)
        half_img_width=$(identify -format "%[fx:w/2]" "$img")
        text_width=$(convert -debug annotate -pointsize $POINT_SIZE -annotate 0 "$name" null: 2>&1 | awk '/width:/ { print $2 }' | cut -d'+' -f1)
        half_text_width=$((text_width / 2))
        center_x_position=$((local_x + half_img_width - half_text_width))
        convert "annotated_row_${row_count}.png" -gravity northwest -pointsize $POINT_SIZE -annotate +${center_x_position}+${y_position} "$name" "annotated_row_${row_count}.png"
        local_x=$((local_x + half_img_width*2 + GAP))
    done

    output_rows+=("annotated_row_${row_count}.png")
fi

# Stitch together all rows
convert "${output_rows[@]}" -append stitched_image.png

# Clean up temporary images
rm -f row_temp_*.png annotated_row_*.png
