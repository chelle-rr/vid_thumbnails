#!/bin/bash

set -x

# Directory containing the video files
read -p "Enter the directory: " video_dir

# Find all video files recursively in the directory and put them in an array
video_list=`find "$video_dir" -type f \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mov" \)`


# For each item in the video_list, create a thumbnail
for video_file in $video_list
do
    # Get the directory of the video file
    dir=$(dirname "$video_file")

    # Get the filename without extension
    filename=$(basename -- "$video_file")
    filename_no_ext="${filename%.*}"

    # Output thumbnail filename
    thumbnail_filename="$dir/$filename_no_ext-thumb.png"

    # Extract thumbnail using ffmpeg
    ffmpeg -i "$video_file" -ss 00:00:02 -frames:v 1 "$thumbnail_filename"

    # Check if extraction was successful
    if [ $? -eq 0 ]; then
        echo "Thumbnail extracted for $filename"
    else
        echo "Error extracting thumbnail for $filename"
    fi
done

# Find all the thumbnails in the directory
find "$video_dir" -type f -iname *-thumb.png > $video_dir/thumb_list.txt
read num_imgs <<< $(sed -n '$=' thumb_list.txt)
let num_rows=num_imgs/8
let lefto=num_imgs%8
if [ $lefto -gt 0 ]
then
   let num_rows=num_rows+1
fi

# Create contact sheets
montage -label '%f' @$video_dir/thumb_list.txt -geometry 200x150 -label '%f' -tile 8x$num_rows $video_dir/contact_sheet.png

# Remove that no-longer-needed list
rm $video_dir/thumb_list.txt

# # Create contact sheets
# montage @thumb_list -geometry 200x150 -tile 8x$nrow $video_dir/contact_sheet.png

# 
# thumbs=("$video_dir"/*-thumb.png)
# num_thumbs=${#thumbs[@]}
# num_pdfs=$(( (num_thumbs + 39) / 40 ))
# 
# for ((i=0; i<num_pdfs; i++)); do
# 	pdf="$directory/contact_sheet_$i.pdf"
# 	start=$((i * 40))
# 	end=$((start + 39))
# 	montage "${thumbs[@]:$start:40}" -label '%f' -tile 5x8 -geometry +5+5 "$pdf"
# done

# Delete thumbnails
thumb_list=`find "$video_dir" -type f \( -iname "*-thumb.png" \)`

for delete_me in $thumb_list
do
	rm $delete_me
done
