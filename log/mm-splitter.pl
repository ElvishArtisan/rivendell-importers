#!/usr/bin/perl -Wall

# mm-splitter.pl
#
# Take a MusicMaster log containing both 'music' and 'traffic' items
# and split it into separate files so Rivendell can process them
# separately.
#
#   (C) 2014 Fred Gleason <fredg@paravelsystems
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

my $usage="mm_splitter.pl <src-logfile>";

my $src_file=$ARGV[@ARGV-1];

open(SRC,$src_file) or die("unable to open \"".$src_file."\"");
open($tfc,'>',$src_file.".tfc") or die("unable to open \"".$src_file.".tfc\"");
open($mus,'>',$src_file.".mus") or die("unable to open \"".$src_file.".mus\"");

my $tfc_mode=FALSE;

foreach $line (<SRC>) {
    my $title=trim(substr($line,10,24));
    if($title eq "BREAK") {
	$tfc_mode=!$tfc_mode;
    }
    else {
	if($tfc_mode) {
	    print $tfc $line;
	}
	else {
	    print $mus $line;
	}
    }
}

close($mus);
close($tfc);
close(SRC);


sub trim
{
    my $s=shift;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}
