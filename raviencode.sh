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

mkdir ./temp_chunks
## Extract audio

ffmpeg -i "$1" -b:a 96k -c:a libopus "./temp_chunks/$1.opus"
## CHUNK OUT THE FILE
ffmpeg -i "$1" -f segment -segment_time 10 -pix_fmt yuv420p ./temp_chunks/chunk_%03d.y4m
cd ./temp_chunks
## Encode the video
for output in chunk_*.y4m; do
  rav1e -y --quantizer 60 -i 72 -s 8 --tile-rows 2 --tile-cols 2 $output --output $output.q60.s8.4x4.ivf &
  nrwait 8
done
wait
## Generate the list of IVFs
for f in ./*q60.s8.4x4.ivf; do echo "file '$f'" >> chunks.txt; done
## Combine them into one video
ffmpeg -f concat -safe 0 -i chunks.txt -c copy "$1.noaudio.mkv" &&
## Mux with the video into one MKV
ffmpeg -i "$1.opus" -i "$1.noaudio.mkv" -c copy "$1.mkv" &&
mv "./$1.mkv" "../$1.av1.mkv" &&
cd .. &&
rm -rf temp_chunks/
wait