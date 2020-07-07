#!/bin/bash
function nrwait() {
    local nrwait_my_arg
    if [[ -z $1 ]] ; then
    nrwait_my_arg=2
    else
    nrwait_my_arg=$1
    fi
    
    while [[ $(jobs -p | wc -l) -ge $nrwait_my_arg ]] ; do
    sleep 0.33;
    done
}

root_dir="/"
watch_dir="watch/"
script_dir="config/"
progress_dir="in_progress/"
converted_dir="converted/"
bitrate="$1"
filename="$2"
quality_preset="$3"
filebase=$(basename "$filename")
nonce=$(date +%s)

working_dir="${root_dir}${progress_dir}$nonce/"
audio_dir="${working_dir}audio/"
video_dir="${working_dir}video/"
source=$(echo "${root_dir}${watch_dir}${bitrate}/${filename}" | sed 's:/*$::')
dest="${root_dir}${converted_dir}${filebase} (AV1 ${bitrate}kbps).mkv"

echo "\n------------------\n"
echo "Source - $source"
echo "Generating working directory and /audio /video - $working_dir"
echo "\n------------------\n"
mkdir -p "${working_dir}" "${audio_dir}" "${video_dir}"
## Get width and height
dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$source")
read width height <<< $(echo "$dimensions" | sed "s/x/ /g")
## Extract audio
echo "Extracting audio:"
ffmpeg -i "$source" -b:a 96k -c:a libopus "${audio_dir}$nonce.opus" && \
echo "Chunking:" && \
## CHUNK OUT THE FILE
ffmpeg -i "$source" -f segment -segment_time 30 -pix_fmt yuv420p ${video_dir}chunk_%04d.y4m && \
cd ${video_dir} && \
wait
## Encode the video
echo "Encoding chunks:"
for chunk in chunk_*.y4m; do
  echo "$chunk"
  SvtAv1EncApp -i $chunk -w $width -h $height --keyint 55 --rc 1 --tbr $bitrate --lookahead 55 --preset $quality_preset -b $chunk.ivf
  nrwait 8
done
wait
## Generate the list of IVFs
echo "Listing chunks and concatenating:"
if test -f chunks.txt; then
    rm chunks.txt
fi
for f in ${video_dir}*.ivf; do echo "file '$f'" >> ${working_dir}chunks.txt; done
## Combine them into one video
ffmpeg -f concat -safe 0 -i ${working_dir}chunks.txt -metadata codec="AV1" -c copy "${video_dir}$nonce.noaudio.mkv" &&
echo "Combining and publishing:"
## Mux with the video into one MKV
ffmpeg -i "${audio_dir}$nonce.opus" -i "${video_dir}$nonce.noaudio.mkv" -c copy "${video_dir}$nonce.done.mkv" &&
mv "${video_dir}$nonce.done.mkv" "${dest}" &&
rm -rf $working_dir
wait