#!/usr/bin/perl -Wall

# fix_oversched.pl
#
# Take overscheduled import events (those with a 'minutes' value greater
# then 59) and move them to XX:59:59.
#
#   (C) 2015 Fred Gleason <fredg@paravelsystems
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

my $usage="fix_oversched.pl <dst-logfile> <src-logfile>";

my $dst_file=$ARGV[@ARGV-2];
my $src_file=$ARGV[@ARGV-1];

open(SRC,$src_file) or die("unable to open \"".$src_file."\"");
open($dst,'>',$dst_file) or die("unable to open \"".$dst_file);

foreach $line (<SRC>) {
    chomp $line;
    if(substr($line,3,2) gt 59) {
	substr($line,3,5)="59:59";
    }
    print $dst $line;
}

close($dst);
close(SRC);
