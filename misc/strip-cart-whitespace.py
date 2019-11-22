#!/usr/bin/python

# strip-cart-whitespace.py
#
# Strip leading/trailing whitespace from all cart text metadata fields
#
#  (C) Copyright 2019 Fred Gleason <fredg@paravelsystems.com>
#
#  This script requires the 'python', 'python-configparser' and
#  'mysql-connector-python' packages.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License version 2 as
#   published by the Free Software Foundation.
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

from __future__ import print_function

import ConfigParser
import glob
import mysql.connector
import subprocess;
import sys, os, string

def eprint(*args,**kwargs):
    print(*args,file=sys.stderr,**kwargs)


def GetDbCredentials():
    config=ConfigParser.ConfigParser()
    config.readfp(open('/etc/rd.conf'))
    return (config.get('mySQL','Loginname'),config.get('mySQL','Password'),
            config.get('mySQL','Hostname'),config.get('mySQL','Database'))

def OpenDb():
    creds=GetDbCredentials()
    return mysql.connector.connect(user=creds[0],password=creds[1],
                                   host=creds[2],database=creds[3],buffered=True)


# ############################################################################
#  Main method begins

usage='strip-cart-whitespace.py'

db=OpenDb()

#
# CART Table
#
fields=['TITLE','ARTIST','ALBUM','CONDUCTOR','LABEL','CLIENT','AGENCY','PUBLISHER','COMPOSER','USER_DEFINED','SONG_ID']

for field in fields:
    sql='select NUMBER,'+field+' from CART'
    q=db.cursor()
    q.execute(sql)
    for row in q.fetchall():
        if(row[1] is not None):
            sql='update CART set '+field+' = %s where NUMBER = %s'
            q1=db.cursor()
            q1.execute(sql,(row[1].strip('\x00'),row[0]))


#
# CUTS Table
#
fields=['DESCRIPTION','OUTCUE']

for field in fields:
    sql='select CUT_NAME,'+field+' from CUTS'
    q=db.cursor()
    q.execute(sql)
    for row in q.fetchall():
        if(row[1] is not None):
            sql='update CUTS set '+field+' = %s where CUT_NAME = %s'
            q1=db.cursor()
            q1.execute(sql,(row[1].strip('\x00'),row[0]))
