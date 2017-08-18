#!/usr/bin/python

# getlogaudio.py
#
# Fetch audio needed to play a particular log
#
#  (C) Copyright 2017 Fred Gleason <fredg@paravelsystems.com>
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
#  Examples:
#
#   Pulling from a directory on the local machine:
#      getlogaudio.py MyLog /source/file/path /dest/file/path
#
#   Pulling from a directory on a remote machine:
#      getlogaudio.py MyLog user@server.example.com:/source/file/path /dest/file/path my_ssh_identity
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

usage='getlogaudio.py <logname> <from-dir> <to-dir> [<ssh-identity>]'

#
# Get arguments
#
if((len(sys.argv)!=4) and (len(sys.argv)!=5)):
    print(usage)
    sys.exit(1)
logname=sys.argv[1]
from_dir=sys.argv[2]
to_dir=sys.argv[3]
identity=''
if(len(sys.argv)==5):
    identity=sys.argv[4]

#
# Fetch files
#
db=OpenDb()
sql='select CART_NUMBER from '+logname.replace(" ","_").upper()+'_LOG'
q=db.cursor()
q.execute(sql)
for row in q.fetchall():
    if(len(identity)==0):
        files=glob.glob(from_dir+'/'+str(row[0])+'_*.wav');
        for name in files:
            subprocess.check_call(('cp','-v',name,to_dir))
    else:
        subprocess.check_call(('scp','-i',identity,from_dir+'/'+str(row[0])+'_*.wav',to_dir))
