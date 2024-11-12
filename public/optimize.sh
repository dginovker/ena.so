#!/bin/bash

# Define source and destination directories
SOURCE_DIR="non_compressed_images"
DEST_DIR="images"

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Loop through all files in the source directory
for file in "$SOURCE_DIR"/*; do
    # Get file extension and filename without extension
    filename=$(basename "$file")
    extension="${filename##*.}"
    filename="${filename%.*}"
    
    # Process images
    if [[ "$extension" == "jpg" || "$extension" == "jpeg" ]]; then
        echo "Compressing JPEG image: $file"
        # Compress JPEG and save as optimized JPEG
        magick "$file" -sampling-factor 4:2:0 -strip -quality 85 -interlace JPEG -colorspace sRGB "$DEST_DIR/$filename.jpg"
    elif [[ "$extension" == "gif" ]]; then
        echo "Compressing GIF image: $file"
        # Compress GIF and save as optimized GIF
        gifsicle --optimize=3 "$file" > "$DEST_DIR/$filename.gif"
    elif [[ "$extension" == "png" ]]; then
        echo "Compressing PNG image: $file"
        # Compress PNG and save as optimized PNG
        magick "$file" -strip -quality 85 "$DEST_DIR/$filename.png"
    elif [[ "$extension" == "mp4" ]]; then
        echo "Compressing MP4 video: $file"
        # Compress MP4 video and save as optimized MP4 with overwrite flag
        ffmpeg -y -i "$file" -vcodec libx264 -crf 28 -preset slow -acodec aac -strict -2 "$DEST_DIR/$filename.mp4"
    else
        echo "Skipping unsupported file type: $file"
    fi
done

echo "Optimization complete. Optimized files are in the '$DEST_DIR' directory."

