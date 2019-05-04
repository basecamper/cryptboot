#!/bin/sh

extract_initrd() {
    
    [ ! -e "${1}" ] && echo "$1 nonexisting ?" && return 1

        # extract initrd
    echo "#  extracting initram $1 ..."\
        && lsinitcpio -x "$1"
    
}
add_files() {
    
    # create initrd crypt dir
    mkdir "$INITRD_CRYPT_DIR"

    # inject
    for f in $INJECT_FILES; do
        echo "#  injecting ../$f -> $INITRD_CRYPT_DIR"
        cp "../$f" "$INITRD_CRYPT_DIR"
    done
    
    echo "#  copying hook"
    cp "../$hook" "./hooks/special-encrypt"
}
re_build() {

    # re-build
    echo "#  re-building -> $1.tmp"
    eval "find -mindepth 1 -printf '%P\0' | LANG=C bsdcpio -0 -o -H newc --quiet | gzip > $1.tmp"
    if [ "$?" ]; then
        echo -e "#  replacing $1.tmp -> $1"
        mv "$1.tmp" "$1"
    else
        echo "error rebuilding - did not replace $1"
        exit 1
    fi
}

run_inject()
{
    cdir=$(pwd)
    src="$1"
    [ "$src[0]" != "/" ] \
        && [ "$src[0]" != "." ] \
        && src="./$1"
    
    source $src
    
    echo "# finding images in $CRYPT_BOOT_DIR"
    images=$(ls $CRYPT_BOOT_DIR | grep -e '\.img$\|\.img ')
    
    hook="custom_encrypt_hook"

    if mkdir EX && mount -t ramfs ramfs EX; then
        for e in $images; do
        	if cd EX; then
        		target="${cdir}/$CRYPT_BOOT_DIR/$e"
    
        		extract_initrd $target
    
        		add_files
    
        		re_build $target
        		cd ..
        	fi
        done
    else
        echo "error creating ramfs dir"
    fi
    
    mountpoint -q EX \
        && echo "# umounting ramfs" \
        && umount EX

    [ -e EX ] \
        && echo "# removing ramfs dir" \
        && rmdir EX
}

[ "$#" -lt "1" ] \
    && echo "usage: ${0} <name.rc> [<name.rc>,..]" \
    && exit 1

case "$1" in
    [aA]ll|ALL) files="$(ls | grep .rc)";;
    *) files="$@"
esac

for file in $files; do
    [ ! -e "$file" ] \
        && echo "$file not existing" \
        && exit 1
    run_inject "$file"
done

exit 0
