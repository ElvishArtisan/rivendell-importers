#!/bin/sh

LOG="WXYZ"`date -d tomorrow +%m%d`

rmlsend "LL $LOG!"
