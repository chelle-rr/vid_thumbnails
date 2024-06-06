#!/bin/bash

#set -x

# Directory containing the video files
read -p "Enter the directory: " video_dir

# Check for whitespace; if found, exit and alert
whitespace=`find "$video_dir" -name "* *" -a -not -iname ".*"`
if [[ -n ${whitespace[@]} ]]; then
	echo -ne "Whitespace found in file or directory name. Please fix before proceeding:\n$whitespace"
	exit 1
fi

# Find all video files recursively in the directory and put them in an array
video_list=`find "$video_dir" -type f \( \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.mts" \) -a -not -iname ".*" \)`

# If no video files found, exit and alert
if [[ -z ${video_list[@]} ]]; then
    echo "No video files found"
    exit 1
fi

# Create a temp directory for thumbnails
thumbnails_dir="$video_dir/thumbnails"
mkdir -p –m777 "$thumbnails_dir"

# For each item in the video_list, create a thumbnail. Note: if the video is less than 00:00:02, no thumbnail will be generated
for video_file in $video_list
do
    # Get the directory of the video file
    dir=$(dirname "$video_file")

    # Get the filename without extension
    filename=$(basename -- "$video_file")
    filename_no_ext="${filename%.*}"

    # Output thumbnail filename
    thumbnail_filename="$thumbnails_dir/$filename_no_ext-th.png"

    # Extract thumbnail with ffmpeg; only reviews first two seconds of file, scales the thumbnail to a max width of 280px
    ffmpeg -ss 00:00:02 -i "$video_file" -hide_banner -loglevel fatal -frames:v 1 -filter:v scale="280:-1" "$thumbnail_filename"
    

    # Check if extraction was successful
    if [ $? -eq 0 ]; then
        echo "Thumbnail extracted for $filename"
    else
        echo "Error extracting thumbnail for $filename"
    fi
done

# Find all the thumbnails in the directory
find "$thumbnails_dir" -type f -iname *-th.png > $thumbnails_dir/thumb_list.txt

# Split thumbnails into groups of 120 (to try to improve montage creation time for large directories? 🤞)
gsplit -l 120 -a 3 --additional-suffix=.txt $thumbnails_dir/thumb_list.txt $thumbnails_dir/thumb_list_

# Counter for PNG filenames
counter=1

# For each group of thumbnails ...
for thumb_list_file in "$thumbnails_dir"/thumb_list_*; do
    # ... create contact sheets
    montage -label '%t' -font Helvetica -pointsize 10 -size 200x200 @"$thumb_list_file" -geometry 280x190 -tile 6x "$thumbnails_dir/__${filenameinfo}-vid-thumbnails-$counter.png"

    # Check if thumbnails.png was successfully created
    if test -f "$video_dir/__${filenameinfo}-vid-thumbnails-$counter.png"; then
        echo "__${filenameinfo}-vid-thumbnails-$counter.png successfully created"
    else
        echo "Error in creating __${filenameinfo}-vid-thumbnails-$counter.png"
    fi

    ((counter++))
done

# Combine thumbnail PNGs into a PDF
montage "$thumbnails_dir/__${filenameinfo}-vid-thumbnails-"*.png -tile 1x -geometry +0+0 "$video_dir/__${filenameinfo}_vid-thumbnails.pdf"

# Check if PDF was successfully created
if test -f "$video_dir/__${filenameinfo}_vid-thumbnails.pdf"; then
    echo "__${filenameinfo}_vid-thumbnails.pdf successfully created"
else
    echo "Error creating __${filenameinfo}_vid-thumbnails.pdf"
fi

# Delete thumbnails directory
rm -rf "$thumbnails_dir"
