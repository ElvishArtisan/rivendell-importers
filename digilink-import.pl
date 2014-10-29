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

##############################################################################
# Process startup options.                                                   #
#                                                                            #
# This section should be applicable to most use cases.  You probably don't   #
# want to muck around with it unless you really Know What You Are Doing.     #
##############################################################################

#
# RDImport Options
#
my @rdimport_opts=('--add_scheduler-codes',
		   '--autotrim-level',
		   '--cart-number-offset',
		   '--create-enddate-offset',
		   '--create-startdate-offset',
		   '--delete-cuts',
		   '--delete-source',
		   '--drop-box',
		   '--enddate-offset',
		   '--fix-broken-formats',
		   '--log-mode',
		   '--metadata-pattern',
		   '--normalization-level',
		   '--segue-length',
		   '--segue-level',
		   '--set-datetimes',
		   '--set-daypart-times',
		   '--set-marker-end',
		   '--set-marker-fadedown',
		   '--set-marker-fadeup',
		   '--set-marker-start-cut',
		   '--set-marker-start-hook',
		   '--set-marker-start-talk',
		   '--set-marker-start-segue',
		   '--set-string-agency',
		   '--set-string-album',
		   '--set-string-artist',
		   '--set-string-bpm',
		   '--set-string-client',
		   '--set-string-composer',
		   '--set-string-conductor',
		   '--set-string-description',
		   '--set-string-label',
		   '--set-string-outcue',
		   '--set-string-publisher',
		   '--set-string-song-id',
		   '--set-string-title',
		   '--set-string-user-defined',
		   '--set-string-year',
		   '--single-cart',
		   '--startdate-offset',
		   '--title-from-cartchunk-id',
		   '--to-cart',
		   '--use-cartchunkl-cutid');


my $usage="USAGE: digilink-import.pl [--string1-to=<field>] [-string2-to=<field>] <group-name> <filespec>";
if(scalar @ARGV lt 2) {
    print $usage."\n";
    exit 256;
}

my $rdimport_args="";
my @keys;
my @values;

#
# Read Options
#
for(my $i=0;$i<(scalar @ARGV-2);$i++) {
    if(substr($ARGV[$i],0,2) ne "--") {
	print "Invalid argument\n";
	exit 256;
    }
    my @f0=split "=",$ARGV[$i];
    push(@keys,$f0[0]);
    if(scalar @f0>1) {
	push(@values,$f0[1]);
    }
    else {
	push(@values,"");
    }
}

#
# Process RDImport Options
#
for(my $i=0;$i<scalar @keys;$i++) {
    for(my $j=0;$j<scalar @rdimport_opts;$j++) {
	if($keys[$i] eq $rdimport_opts[$j]) {
	    $rdimport_args=$rdimport_args." \"".$keys[$i];
	    if($values[$i] ne "") {
		$rdimport_args=$rdimport_args."=".$values[$i];
	    }
	    $rdimport_args=$rdimport_args."\"";
	    splice(@keys,$i,1);
	    splice(@values,$i,1);
	    $i--;
	    $j=scalar @rdimport_opts;
	}
    }
}

#print "RDImport args: ".$rdimport_args."\n";

#for(my $i=0;$i<scalar @keys;$i++) {
#    print "key[".$i."]: ".$keys[$i]."  value[".$i."]: ".$values[$i]."\n";
#}

my $filespec=pop @ARGV;
my $group_name=pop @ARGV;

# ###########################################################################
#  End of startup section                                                   #
# ###########################################################################


#############################################################################
#  Now we're ready to Do The Business.  The following variables are         #
#  available:                                                               #
#                                                                           #
#     $group_name - The <group-name> specified on the command-line.         #
#                                                                           #
#       $filespec - The <filespec> specified on the command-line.           #
#                                                                           #
#  $rdimport_args - The list of rdimport options from the command-line.     #
#                   Generally, it's safe to just pass this whole to         #
#                   rdimport(1).                                            #
#                                                                           #
#           @keys - The key (left side of the '=' sign) part of the         #
#                   command-line options, scrubbed of any rdimport(1)       #
#                   options.                                                #
#                                                                           #
#         @values - The value (right-hand side of '=' sign) part of the     #
#                   command-line options, scrubbed of any rdimport(1)       #
#                   options.                                                #
#############################################################################

#
# Generate --set-string-* options
#
my $string1="";
for(my $i=0;$i<scalar @keys;$i++) {
    if($keys[$i] eq "--string1-to") {
	$string1=$values[$i];
    }
}
my $string2="";
for(my $i=0;$i<scalar @keys;$i++) {
    if($keys[$i] eq "--string2-to") {
	$string2=$values[$i];
    }
}

#
# Run the import
#
@files=glob $filespec;
foreach $file (@files) {
    my @f0=split '\+',$file;
    if(scalar @f0 eq 11) {
	my @start=split '_',$f0[6];
	my @end=split '_',$f0[7];
	my $cmd="rdimport ".$rdimport_args." ".
	    "\"--set-string-".$string1."=".$f0[1]."\" ".
	    "\"--set-string-".$string2."=".$f0[2]."\" ".
	    sprintf("--set-marker-end-talk=%d ",1000*$f0[3]).
	    sprintf("--set-marker-start-segue=%d ",-1000*$f0[4]);
	if((scalar @start eq 3)&&(scalar @end eq 3)) {
	    if($end[2] lt 2099) {
		$cmd=$cmd."--set-datetimes=".
		    sprintf("%04d%02d%02d-000000,",
			    $start[2],$start[0],$start[1]).
			    sprintf("%04d%02d%02d-235959 ",
				    $end[2],$end[0],$end[1]);
	    }
	}
	$cmd=$cmd.$group_name." \"".$file."\"";
	print "Importing \"".$f0[1]."\" / \"".$f0[2]."\" into ".$group_name;
	system($cmd);
    }
}
