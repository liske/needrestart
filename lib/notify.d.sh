# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2020 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
#
# License:
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#

# Shell library for scripts in /etc/needrestart/notify.d/

NOTIFYCONF='/etc/needrestart/notify.conf'
GETTEXTLIB='/usr/bin/gettext.sh'
export TEXTDOMAIN='needrestart-notify'

if [ ! -r "$NOTIFYCONF" ]; then
    echo "[$0] Unable to read $NOTIFYCONF - aborting!" 1>&2
    exit 1;
fi

# Load global config
. "$NOTIFYCONF"

# Load gettext shell library
. "$GETTEXTLIB"

# Get LANG of session
export LANG=$(sed -z -n s/^LANG=//p "/proc/$NR_SESSPPID/environ")
