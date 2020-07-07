#!/bin/sh
cd /config/encode/
mkdir 300 400 600 1000 1500 2000 2250 2500
cd /
MONITORDIR1="/config/encode/300/"
MONITORDIR2="/config/encode/400/"
MONITORDIR3="/config/encode/600/"
MONITORDIR4="/config/encode/1000/"

three() {
inotifywait -m -r -e close_write --format "%f" "$1" | while read NEWFILE
do
        cp "./encode/300/${NEWFILE}" ./ && /config/raviencode.sh "${NEWFILE}" 300
done
}
four() {
inotifywait -m -r -e close_write --format "%f" "$1" | while read NEWFILE
do
        cp "./encode/400/${NEWFILE}" ./ && /config/raviencode.sh "${NEWFILE}" 400
done
}
six() {
inotifywait -m -r -e close_write --format "%f" "$1" | while read NEWFILE
do
        cp "./encode/600/${NEWFILE}" ./ && /config/raviencode.sh "${NEWFILE}" 600
done
}
onek() {
inotifywait -m -r -e close_write --format "%f" "$1" | while read NEWFILE
do
        cp "./encode/1000/${NEWFILE}" ./ && /config/raviencode.sh "${NEWFILE}" 1000
done
}
three "$MONITORDIR1" &
four "$MONITORDIR2" &
six "$MONITORDIR3" &
onek "$MONITORDIR4"