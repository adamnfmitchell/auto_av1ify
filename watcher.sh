#!/bin/sh
MONITORDIR1="/autoav1/encode/300/"
MONITORDIR2="/autoav1/encode/400/"
MONITORDIR3="/autoav1/encode/600/"

three() {
inotifywait -m -r -e close_write --format "%f" "$1" | while read NEWFILE
do
        cp "./encode/300/${NEWFILE}" ./ && /autoav1/ravb300.sh "${NEWFILE}"
done
}
four() {
inotifywait -m -r -e close_write --format "%f" "$1" | while read NEWFILE
do
        cp "./encode/400/${NEWFILE}" ./ && /autoav1/ravb400.sh "${NEWFILE}"
done
}
six() {
inotifywait -m -r -e close_write --format "%f" "$1" | while read NEWFILE
do
        cp "./encode/600/${NEWFILE}" ./ && /autoav1/ravb600.sh "${NEWFILE}"
done
}
three "$MONITORDIR1" &
four "$MONITORDIR2" &
six "$MONITORDIR3"