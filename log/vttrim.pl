#!/usr/bin/perl -Wall

# vttrim.pl
#
# Remove extraneous information for a log VOICETRACK line.
#
#   (C) 2016 Fred Gleason <fredg@paravelsystems.com>
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

my $usage="vttrim.pl <dst-logfile> <src-logfile>";

my $dst_file=$ARGV[@ARGV-2];
my $src_file=$ARGV[@ARGV-1];

open(SRC,$src_file) or die("unable to open \"".$src_file."\"");
open($dst,'>',$dst_file) or die("unable to open \"".$dst_file);

foreach $line (<SRC>) {
    chomp $line;
    if($line =~ "\\bVOICETRACK\\b") {
	print $dst "VOICETRACK";
    }
    else {
	print $dst $line;
    }
}

close($dst);
close(SRC);
