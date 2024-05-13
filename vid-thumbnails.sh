#!/bin/bash

#set -x

# Directory containing the video files
read -p "Enter the directory: " video_dir

# Remove whitespace
# while read line 
# 	do mv "$line" "${line// /}" 
# done < <(find $video_dir -iname "* *")

# Check for whitespace; if found, exit and alert
whitespace=`find "$video_dir" -name "* *"`
if [[ -n $(find "$video_dir" -name "* *") ]]; then
	echo -ne "Whitespace found in file or directory name. Please fix before proceeding:\n$whitespace"
	exit 1
fi

# Find all video files recursively in the directory and put them in an array
video_list=`find "$video_dir" -type f \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mov" \)`

# If no video files found, exit and alert
if [[ -z ${video_list[@]} ]]; then
    echo "No video files found"
    exit 1
fi

# For each item in the video_list, create a thumbnail
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

# Create contact sheets
montage -label '%t' @$video_dir/thumb_list.txt -geometry 280x190 -frame 5 -tile 6x $video_dir/thumbnails.png

# Not working version of the montage that should change labels ...
#montage -label @$video_dir/thumb_labels.txt @$video_dir/thumb_list.txt -geometry 200x150 -frame 5 -tile 6x$num_rows $video_dir/thumbnails.png

# Remove that no-longer-needed list
rm $video_dir/thumb_list.txt


# 
# thumbs=("$video_dir"/*-th.png)
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
thumb_list=`find "$video_dir" -type f \( -iname "*-th.png" \)`

for delete_me in $thumb_list
do
	rm $delete_me
done

# Check if thumbnails.png was successfully created
if test -f $video_dir/thumbnails.png; then
	echo "Thumbnails.png successfully created"
else
	echo "Error in creating thumbnails.png"
fi
