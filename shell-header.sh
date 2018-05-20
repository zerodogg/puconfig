exit 1 # Not intended to be run directly
##
## Lines beginning with ## are stripped when puconfig generates its script.
##
## This is the puconfig shell header. It is inserted to the top of any script that
## puconfig writes. The rest of the script gets generated by puconfig, based upon
## the user config and commmand-line arguments
##
#!/bin/sh
# This script was generated by puconfig {{puconfig_version}}.
#
# puconfig is Copyright (C) Eskild Hustvedt 2018
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Note that the generated content of this file is not governed by this license.
# This is indicated with comments where the GPL-licensed code ends, and the
# user-generated portion begins.

# A note about API stability:
# Variables and functions prefixed with _ are considered private. They
# may change or disappear between releases, and thus should NOT be used
# in *script blocks in your config. If you do use them, then your scripts
# may break in interesting ways if you upgrade puconfig.

# Output a message if PUCONFIG_SILENT != 1
_echo ()
{
    if [ "$PUCONFIG_SILENT" != "1" ]; then
        echo "$@"
    fi
}

# Try hard to get a hostname
_hostname ()
{
    if [ "x$HOST" != "x" ]; then
        echo "$HOST"
    elif [ "x$HOSTNAME" != "x" ]; then
        echo "$HOSTNAME"
    elif _has_command hostname; then
        hostname -f
    elif _has_perl_module "Sys::Hostname"; then
        perl -e "use Sys::Hostname qw(hostname); print hostname;"
    elif [ -e "/etc/hostname" ]; then
        cat /etc/hostname
    else
        echo "localhost"
    fi
}

# Check if hostname matches any of the provided strings
hostname_match ()
{
    myHost="`_hostname`"
    _string_match "$myHost" "$@"
    return $?
}

# Try hard to get a username
_username ()
{
    if [ "x$USER" != "x" ]; then
        echo "$USER"
    elif [ "x$USERNAME" != "x" ]; then
        echo "$USERNAME"
    elif _has_command whoami; then
        whoami
    elif _has_command id; then
        id -un
    elif _has_perl_module "POSIX"; then
        perl -e "use POSIX qw(cuserid); print cuserid;"
    elif [ "x$UID" != "x" ]; then
        echo "unknownuser-$UID"
    else
        echo "unknownuser"
    fi
}

# Check if username matches any of the provided strings
username_match ()
{
    myUser="`_username`"
    _string_match "$myUser" "$@"
    return $?
}

# Perform a string match
_string_match ()
{
    src="$1"
    shift
    for entry in $@; do
        echo "$src" | grep -q "$entry"
        if [ "$?" = "0" ]; then
            return 0
        fi
    done
    return 1
}

# Checks if perl is installed and a certain module available
_has_perl_module ()
{
    if ! _has_command perl; then
        return 1
    fi
    perl -e 'use($ARGV[0]) or die' "$1"  > /dev/null 2>&1
    return $?
}

# Checks if a command is available, silently
_has_command ()
{
    which "$1" >/dev/null 2>&1
    return $?
}

# Checks that a path is safe to write to
_validatePath ()
{
    fpath="$1"
    if [ -d "$fpath" ]; then
        echo "Error: $fpath: is a directory"
        exit 1
    fi
    if [ -e "$fpath" ] && [ ! -w "$fpath" ]; then
        echo "Error: $fpath: is not writeable"
        exit 1
    fi
    if _has_command dirname; then
        if [ ! -w "$(dirname "$fpath")" ]; then
            echo "Error: Can not write to target directory of $fpath"
            exit 1
        fi
    fi
}

# Copies a file into place.
# Usage: _copyIntoTree "relative/path" "/path/to/source" "/path/to/target" "CONTENT" "allowLocal"
#
# If it finds .head or .tail files, and the allowLocal argument is the string
# "true" it will concatenate those as well.  If CONTENT is set, then that is
# treated as the content of the file instead of whatever is at
# "/path/to/source" (and "/path/to/source" does not have to even exist)
_copyIntoTree ()
{
    srcName="$1"
    src="$2"
    target="$3"
    content="$4"
    allowLocal="$5"
    _validatePath "$target"
    if [ -e "$target" ] && [ -L "$target" ]; then
        rm -f "$target"
    fi
    printf "" > "$target"
    if [ "$allowLocal" = "true" ] && [ -e "$target.head" ]; then
        cat "$target.head" >> "$target"
    fi
    if [ "x$content" = "x" ]; then
        cat "$src" >> "$target"
    else
        printf '%s' "$content" >> "$target"
    fi
    if [ "$allowLocal" = "true" ] && [ -e "$target.tail" ]; then
        cat "$target.tail" >> "$target"
    fi
    _echo " $srcName => $target"
}

# Symlinks a file into place.
# Usage: _symlinkIntoTree "relative/path" "/path/to/source" "/path/to/target" "allowLocal" "linkType"
# Will convert into using _copyIntoTree if .tail or .head files exist if
# allowLocal is "true".
# Will hardlink if "linkType" is "hardlink", will symlink otherwise
_linkIntoTree ()
{
    srcName="$1"
    src="$2"
    target="$3"
    allowLocal="$4"
    linkType="$5"
    linkArrow="=~"
    _validatePath "$target"
    if [ "$allowLocal" = "true" ]; then
        if [ -e "$target.tail" ] || [ -e "$target.head" ]; then
            _echo "Converted $target into a copy because of .head or .tail files"
            _copyIntoTree "$srcName" "$src" "$target" "" "$allowLocal"
            return $?
        fi
    fi
    if [ "$linkType" = "hardlink" ]; then
        ln -f "$src" "$target"
        ret=$?
        linkArrow='=='
    else
        ln -sf "$src" "$target"
        ret=$?
    fi
    if [ "$ret" != "0" ]; then
        echo "Fatal error while inking $src to $target. Aborting. ($ret)"
        exit 1
    fi
    _echo " $srcName $linkArrow $target"
}

# Checks if a command failed, and exits with a message if it did
_checkCmdReturnValue ()
{
    ret="$1"
    message="$2"
    if [ "$ret" != "0" ]; then
        echo "$message"
        exit 1
    fi
}
