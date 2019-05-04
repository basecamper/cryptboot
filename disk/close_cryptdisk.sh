#!/bin/sh

[ "$1" == "" ] && echo "no config file" && exit 1

src="$1"
if [ "$src[0]" != "/" ] && [ "$src[0]" != "." ]; then
	src="./$1"
fi

source $src

[ "$DEC_DISK_NAME" == "" ] && echo "no decryption disk name" && exit 1

exe="cryptsetup close $DEC_DISK_NAME"


echo "closing $DEC_DISK_NAME"
eval "$exe"

exit $?
