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

# For each item in the video_list, create a thumbnail. Note: if the video is less than 00:00:02, no thumbnail will be generated
for video_file in $video_list
do
    # Get the directory of the video file
    dir=$(dirname "$video_file")

    # Get the filename without extension
    filename=$(basename -- "$video_file")
    filename_no_ext="${filename%.*}"

    # Output thumbnail filename
    thumbnail_filename="$dir/$filename_no_ext-th.png"

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
find "$video_dir" -type f -iname *-th.png > $video_dir/thumb_list.txt

# [removed bc unnecessary] Determine number of rows for imagemagick
# read num_imgs <<< $(sed -n '$=' thumb_list.txt)
# let num_rows=num_imgs/6
# let lefto=num_imgs%6
# if [ $lefto -gt 0 ]
# then
#    let num_rows=num_rows+1
# fi

# Determine number of columns for imagemagick
read num_imgs <<< $(sed -n '$=' $video_dir/thumb_list.txt)
if [[ $num_imgs -gt 5 ]]
then
   let num_columns=6
else
	let num_columns=num_imgs	   
fi

# Label the pngs so that the final contact sheet doesn't contain "-th.png" not working though
# thumb_labels=`find "$video_dir" -type f -iname *-th.png`
# 
# for thumb_to_label in $thumb_labels
# do
# 	thumb_fn=$(basename -- "$thumb_to_label")
# 	thumb_fn_no_ext="${thumb_fn%.*}"
# 	remove="-th"
# 	thumb_fn_trim=${thumb_fn_no_ext%"$remove"}
# 	echo $thumb_fn_trim
# 	
# done > $video_dir/thumb_labels.txt

# Name the output thumbnails
# read thumb_filename <<< $(sed -n 's/[A][0-9]\{5\}//' $video_dir)

# Create contact sheets
montage -label '%t' @$video_dir/thumb_list.txt -geometry 280x190 -tile "$num_columns"x $video_dir/_thumbnails.png

# Not working version of the montage that should change labels ...
#montage -label @$video_dir/thumb_labels.txt @$video_dir/thumb_list.txt -geometry 200x150 -frame 5 -tile 6x$num_rows $video_dir/thumbnails.png

# Check if thumbnails.png was successfully created
if test -f $video_dir/_thumbnails.png; then
	echo "_thumbnails.png successfully created"
else
	echo "Error in creating _thumbnails.png"
fi

# Remove that no-longer-needed list
rm $video_dir/thumb_list.txt

# Delete thumbnails
thumb_list=`find "$video_dir" -type f \( -iname "*-th.png" \)`

for delete_me in $thumb_list
do
	rm $delete_me
done
