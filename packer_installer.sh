#!/bin/bash

## Name:
##     packer_installer.sh 
##
## Purpose:
##     Download, verify, and stow Packer (see http://packer.io).
##
## Usage:
##     packer_installer.sh [ -u | -h ]
##
## Options:
##     -h = show documentation
##     -u = show usage
##
## Copyright:
##      Copyright 2014 Todd A. Jacobs
##      All Rights Reserved
##
## License:
##      Released under the GNU General Public License (GPL)
##      http://www.gnu.org/copyleft/gpl.html
##
##      This program is free software; you can redistribute it and/or
##      modify it under the terms of the GNU General Public License
##      as published by the Free Software Foundation; either version 3
##      of the License, or (at your option) any later version.
##
##      This program is distributed in the hope that it will be useful,
##      but WITHOUT ANY WARRANTY; without even the implied warranty of
##      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##      GNU General Public License for more details.

######################################################################
# User-Configurable Defaults
######################################################################
: "${PACKER_VERSION:=0.5.2}"
: "${PACKER_PLATFRM:=linux}"
: "${PACKER_TEMPDIR:=/tmp}"
: "${PACKER_STOWDIR:=$HOME/stow}"

######################################################################
# Functions
######################################################################
function usage {
    local LINES=1
    grep -E -A $LINES "^## Usage:" "$0" | sed 's/^## //'
    exit 2
}

function help {
    sed -n '/^##\([^#]\|$\)/ {s/##//; s/^ //; p}' "$0"
    exit 2
}

options_parse () {
    unset ACTION SHIFT
    while getopts ":hu" opt; do
        case $opt in
            h) help ;;
            u|\?) usage ;;
        esac
    done
    shift $(($OPTIND - 1))
}

######################################################################
# Main
######################################################################
set -e
options_parse "$@"

case `arch` in
    x86_64) 
	: "${PACKER_ARCH:=amd64}"
	;;
    *)
	echo 'EX_SOFTWARE: unknown architecture' >&2
	exit 70
	;;
esac

URL_BASEURI="https://dl.bintray.com/mitchellh/packer"
URL_CHCKSUM="${URL_BASEURI}/${PACKER_VERSION}_SHA256SUMS?direct"
URL_ZIPFILE="${URL_BASEURI}/${PACKER_VERSION}_${PACKER_PLATFRM}_${PACKER_ARCH}.zip"

echo "Downloading Packer $PACKER_VERSION ..."
    : "${TMPDIR:=$PACKER_TEMPDIR}"
    PACKER_TEMPDIR=$(mktemp --tmpdir --directory packer.XXXXXX)
    zipfile="${URL_ZIPFILE##*/}"
    trap "rm $zipfile{,.sha256sum}; rmdir \"$PACKER_TEMPDIR\"" EXIT
    cd "$PACKER_TEMPDIR"
    curl -sSLo "${zipfile}.sha256sum" "$URL_CHCKSUM"
    curl -sSLO "$URL_ZIPFILE"
echo 'Downloading complete.'

if ! fgrep -q "$(sha256sum "$zipfile")" "${zipfile}.sha256sum"; then
    echo 'EX_OSFILE: bad checksum' >&2
    exit 71
fi

echo "Extracting Packer $PACKER_VERSION ..."
    : "${TMPDIR:=$PACKER_TEMPDIR}"
    dir="${PACKER_STOWDIR}/packer_${PACKER_VERSION}/bin"
    mkdir -p "$dir"
    unzip -B -q -d "$dir" "$zipfile"
echo "Extraction complete."

echo "Stowing Packer $PACKER_VERSION ..."
    find "$PACKER_STOWDIR" -type d -name packer_\* -exec basename {} \; |
	xargs -n1 stow -d "$PACKER_STOWDIR" -t ~ -D
    stow -d "$PACKER_STOWDIR" -t ~ --ignore='~\d+\z' "packer_${PACKER_VERSION}"
echo "Stowing complete."
