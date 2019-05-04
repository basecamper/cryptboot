#!/bin/sh

[ ! -n $1 ] && echo "missing rc file" && exit 1

src="$1"
exe=""
if [ "$src[0]" != "/" ] && [ "$src[0]" != "." ]; then
	src="./${src}"
fi

source $src

if [ ! -z "$KEYDISK_RC" ]; then
	./open_cryptdisk.sh "$KEYDISK_RC"
	[ "$?" != "0" ] && exit 1
fi

[ "$DEC_DISK_NAME" == "" ] && echo "no decryption disk name" && exit 1

cmd=""
counter=0

for file in $ENC_DISK_FILE; do
	[ "$counter" != "0" ] \
		&& counter=0 \
		&& echo "trying next disk"

	while [ ! -L "${file}" ]; do
		counter=$(($counter+1))
		if [ "$counter" -gt "20" ]; then
			echo "timeout"
			break;
		fi
		echo "waiting for $NAME"
		sleep 1
	done
	if [ -L "${file}" ]; then
		cmd="cryptsetup open $file $DEC_DISK_NAME"
		break;
	fi
done

if [ "$cmd" == "" ]; then
	echo "error finding keyfile"
	exit 1
fi

[ -n "$ENC_DISK_OFFSET" ] &&         exe="$exe --offset=$ENC_DISK_OFFSET"
[ -n "$ENC_DISK_SIZE" ] &&           exe="$exe --size=$ENC_DISK_SIZE"
[ -n "$CRYPT_TYPE" ] &&              exe="$exe --type=$CRYPT_TYPE"
[ -n "$CRYPT_KEY_CIPHER" ] &&        exe="$exe --cipher=$CRYPT_KEY_CIPHER"
[ -n "$CRYPT_KEY_SIZE" ] &&          exe="$exe --key-size=$CRYPT_KEY_SIZE"

[ -n "$CRYPT_KEY_FILE" ] &&          exe="$exe --key-file=$CRYPT_KEY_FILE"
[ -n "$CRYPT_KEY_FILE_SIZE" ] &&     exe="$exe --keyfile-size=$CRYPT_KEY_FILE_SIZE"
[ -n "$CRYPT_KEY_FILE_OFFSET" ] &&   exe="$exe --keyfile-offset=$CRYPT_KEY_FILE_OFFSET"
exe="$cmd $exe"
echo "opening $DEC_DISK_NAME"
$exe
status=$?
[ ! -z "$KEYDISK_RC" ] && ./close_cryptdisk.sh "$KEYDISK_RC"
exit $status
