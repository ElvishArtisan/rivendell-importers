#!/bin/sh

# sync_remote_system
# 
#   Copy a remote (and possibly active) Rivendell system to the local host.
#
#   (C) Copyright 2020 Fred Gleason <fredg@paravelsystems.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

#
# Remote Site Information
#
REMOTE_HOSTNAME=xfertest0
REMOTE_MYSQL_USERNAME=rduser
REMOTE_MYSQL_PASSWORD=letmein
REMOTE_MYSQL_DBNAME=Rivendell

#
# Local Site Information
#
LOCAL_HOSTNAME=localhost
LOCAL_MYSQL_USERNAME=rduser
LOCAL_MYSQL_PASSWORD=letmein
LOCAL_MYSQL_DBNAME=Rivendell
DB_TEMPFILE=/tmp/sync_remote_system.sql.gz

# ##########################################################################
#  Utility functions
# ##########################################################################
function Continue {
  read -a RESP -p "Continue (y/N) "
  echo
  if [ -z $RESP ] ; then
    exit 0
  fi
  if [ $RESP != "y" -a $RESP != "Y" ] ; then
    exit 0
  fi
}


# ##########################################################################
#  Main Program
# ##########################################################################

#
# Warning Messages
#
clear
echo
echo "This process will mirror the data from the Rivendell system"
echo -n "at '"
echo -n $REMOTE_HOSTNAME
echo "' to here."
echo
echo "Any Rivendell data on this system (carts, logs, etc)"
echo -n "that is not on '"
echo -n $REMOTE_HOSTNAME
echo "' will be DESTROYED!"
echo
Continue

echo
echo "Verify that ALL Rivendell modules on this system are closed."
echo
Continue

#
# Sync remote audio
#
echo -n "Syncing remote audio..."
rsync -va --delete $REMOTE_HOSTNAME::rivendell/ /var/snd
echo "done."
echo

#
# Get remote database
#
echo -n "Transferring database..."
mysqldump -h $REMOTE_HOSTNAME -u $REMOTE_MYSQL_USERNAME -p$REMOTE_MYSQL_PASSWORD $REMOTE_MYSQL_DBNAME | gzip > $DB_TEMPFILE

#
# Install database locally
#
systemctl stop rivendell

echo drop\ database\ $LOCAL_MYSQL_DBNAME\; | mysql -u $LOCAL_MYSQL_USERNAME -p$LOCAL_MYSQL_PASSWORD
echo create\ database\ $LOCAL_MYSQL_DBNAME\; | mysql -u $LOCAL_MYSQL_USERNAME -p$LOCAL_MYSQL_PASSWORD
gzip -cd $DB_TEMPFILE | mysql -u $LOCAL_MYSQL_USERNAME -p$LOCAL_MYSQL_PASSWORD $LOCAL_MYSQL_DBNAME

rddbmgr --modify
systemctl restart rivendell
rm -f $DB_TEMPFILE

echo "done."
echo

echo "System is syncronized."
