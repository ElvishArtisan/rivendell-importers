#!/usr/bin/python

# check_logs.py
#
# Print the name and last modified datetime of the most recent logs
#
#  (C) Copyright 2021 Fred Gleason <fredg@paravelsystems.com>
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

usage='check_logs.py'

db=OpenDb()
sql='select `NAME` from `SERVICES` order by `NAME`';
q=db.cursor()
q.execute(sql)
for row in q.fetchall():
    sql="select `NAME`,`MODIFIED_DATETIME` from `LOGS` where `SERVICE`='"+row[0]+"' order by `MODIFIED_DATETIME` desc"
    q1=db.cursor()
    q1.execute(sql)
    row1=q1.fetchone()
    if(row1!=None):
        print(row[0]+': '+row1[0]+' ['+str(row1[1])+']')
