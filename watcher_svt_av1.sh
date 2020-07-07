#!/bin/bash
root_dir="/"
watch_dir="watch/"
script_dir="config/"
script_file="queue_encode_svt_av1.sh"
escaped_root=$(echo ${root_dir} | sed 's/\//\\\//g')

watch() {
  inotifywait -m -r -e close_write --format "%w%f" "$1" | while read new_file_path
  do
    bitrate=$(echo "${new_file_path}" | sed "s/${escaped_root}//" | sed "s/\// /g" | awk '{print $2}')
    file=$(basename "${new_file_path}")
    eval "${root_dir}${script_dir}${script_file} ${bitrate} \"${file}\" 7"
  done
}
watch "${root_dir}${watch_dir}" &