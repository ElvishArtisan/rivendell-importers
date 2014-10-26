#!/usr/bin/perl -Wall
#
# digilink-import.pl
#
# Import audio files from an Arrakis Digilink System into Rivendell
#
# (C) Copyright 2014 Fred Gleason <fredg@paravelsystems.com>
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

my $usage="USAGE: digilink-import.pl <group-name> <filespec>";
if(scalar @ARGV ne 2) {
    print $usage."\n";
    exit 256;
}

my $group_name=$ARGV[0];
my $filespec=$ARGV[1];

@files=glob $filespec;
foreach $file (@files) {
    my @f0=split '\+',$file;
    if(scalar @f0 eq 11) {
	my @start=split '_',$f0[6];
	my @end=split '_',$f0[7];
	my $cmd="rdimport \"--set-string-title=".$f0[2]."\" ".
	    "\"--set-string-artist=".$f0[1]."\" ".
	    sprintf("--set-marker-end-talk=%d ",1000*$f0[3]).
	    sprintf("--set-marker-start-segue=%d ",-1000*$f0[4]);

	$cmd=$cmd.$group_name." \"".$file."\"";
	print "Importing \"".$f0[2]."\" / \"".$f0[1]."\" into ".$group_name;
	system($cmd);
    }
}
