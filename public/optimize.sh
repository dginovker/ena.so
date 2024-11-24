#!/bin/bash

# Define source and destination directories
SOURCE_DIR="non_compressed_images"
DEST_DIR="images"

# Maximum sizes in bytes
IMAGE_MAX_SIZE=$((3 * 1024 * 1024))    # 3MB
VIDEO_MAX_SIZE=$((10 * 1024 * 1024))   # 10MB

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Loop through all files in the source directory
for file in "$SOURCE_DIR"/*; do
    # Get file extension and filename without extension
    filename=$(basename "$file")
    extension="${filename##*.}"
    filename="${filename%.*}"

    # Process images and videos
    if [[ "$extension" == "jpg" || "$extension" == "jpeg" || "$extension" == "png" ]]; then
        echo "Converting and compressing image: $file"
        quality=85
        min_quality=10
        while true; do
            # Compress to WebP format
            magick "$file" -strip -quality $quality -define webp:method=6 "$DEST_DIR/$filename.webp"
            # Check output file size
            output_size=$(stat -c%s "$DEST_DIR/$filename.webp")
            if [ $output_size -le $IMAGE_MAX_SIZE ]; then
                echo "File compressed to acceptable size ($output_size bytes) in WebP format with quality $quality"
                break
            elif [ $quality -le $min_quality ]; then
                echo "Cannot compress $file below target size in WebP format with acceptable quality. Falling back to original format."
                break
            else
                echo "Output size $output_size bytes exceeds limit, reducing quality"
                quality=$((quality - 5))
            fi
        done

        # If WebP fails to meet size constraints, fall back to the original format
        if [ $output_size -gt $IMAGE_MAX_SIZE ]; then
            echo "Falling back to original format for $file"
            if [[ "$extension" == "jpg" || "$extension" == "jpeg" ]]; then
                quality=85
                while true; do
                    magick "$file" -sampling-factor 4:2:0 -strip -quality $quality -interlace JPEG -colorspace sRGB "$DEST_DIR/$filename.jpg"
                    output_size=$(stat -c%s "$DEST_DIR/$filename.jpg")
                    if [ $output_size -le $IMAGE_MAX_SIZE ]; then
                        echo "File compressed to acceptable size ($output_size bytes) in JPEG format with quality $quality"
                        break
                    elif [ $quality -le $min_quality ]; then
                        echo "Cannot compress $file below target size with acceptable quality"
                        break
                    else
                        quality=$((quality - 5))
                    fi
                done
            elif [[ "$extension" == "png" ]]; then
                quality=85
                colors=256
                while true; do
                    magick "$file" -strip -quality $quality +dither -colors $colors "$DEST_DIR/$filename.png"
                    output_size=$(stat -c%s "$DEST_DIR/$filename.png")
                    if [ $output_size -le $IMAGE_MAX_SIZE ]; then
                        echo "File compressed to acceptable size ($output_size bytes) in PNG format with quality $quality and colors $colors"
                        break
                    elif [ $quality -le $min_quality ] && [ $colors -le 16 ]; then
                        echo "Cannot compress $file below target size with acceptable quality and colors"
                        break
                    else
                        if [ $quality -gt $min_quality ]; then
                            quality=$((quality - 5))
                        else
                            colors=$((colors / 2))
                        fi
                    fi
                done
            fi
        fi
    elif [[ "$extension" == "gif" ]]; then
        echo "Compressing GIF image: $file"
        optimization_level=3
        scale=1.0
        min_scale=0.5
        while true; do
            gifsicle --optimize=$optimization_level --scale $scale "$file" -o "$DEST_DIR/$filename.gif"
            output_size=$(stat -c%s "$DEST_DIR/$filename.gif")
            if [ $output_size -le $VIDEO_MAX_SIZE ]; then
                echo "File compressed to acceptable size ($output_size bytes) with scale $scale"
                break
            elif (( $(echo "$scale <= $min_scale" | bc -l) )); then
                echo "Cannot compress $file below target size with acceptable scale"
                break
            else
                scale=$(echo "$scale - 0.1" | bc)
            fi
        done
    elif [[ "$extension" == "mp4" ]]; then
        echo "Compressing MP4 video: $file"
        crf=28
        max_crf=51
        scale=1.0
        min_scale=0.5
        while true; do
            ffmpeg -y -i "$file" -vf "scale=iw*$scale:ih*$scale" -vcodec libx264 -crf $crf -preset slow -acodec aac -strict -2 "$DEST_DIR/$filename.mp4"
            output_size=$(stat -c%s "$DEST_DIR/$filename.mp4")
            if [ $output_size -le $VIDEO_MAX_SIZE ]; then
                echo "File compressed to acceptable size ($output_size bytes) with crf $crf and scale $scale"
                break
            elif [ $crf -ge $max_crf ] && (( $(echo "$scale <= $min_scale" | bc -l) )); then
                echo "Cannot compress $file below target size with acceptable quality and scale"
                break
            else
                if [ $crf -lt $max_crf ]; then
                    crf=$((crf + 2))
                else
                    scale=$(echo "$scale - 0.1" | bc)
                fi
            fi
        done
    else
        echo "Skipping unsupported file type: $file"
    fi
done

echo "Optimization complete. Optimized files are in the '$DEST_DIR' directory."

