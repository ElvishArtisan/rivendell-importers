#!/usr/bin/perl -Wall
#
# soundpanel-import.pl
#
# Import audio files from a Soundpanel array file (.AAR).
#
# (C) Copyright 2014,2016 Fred Gleason <fredg@paravelsystems.com>
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

use Config::IniFiles;

##############################################################################
# Process startup options.                                                   #
#                                                                            #
# This section should be applicable to most use cases.  You probably don't   #
# want to muck around with it unless you really Know What You Are Doing.     #
##############################################################################

#
# RDImport Options
#
my @rdimport_opts=('--add-scheduler-code',
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


my $usage="USAGE: soundpanel-import.pl [--title-to=<field>] [--legend-to=<field>] <group-name> <aar-filespec>";
if(scalar @ARGV lt 2) {
    print $usage."\n";
    exit 256;
}

my $rdimport_args="";
my @keys;
my @values;
my $to_cart_used=0;
my $cart_number=0;
my $cart_number_offset=0;

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
	    if($keys[$i] eq "--to-cart") {
		$cart_number=$values[$i];
		$to_cart_used=1;
	    }
	    if($keys[$i] eq "--cart-number-offset") {
		$cart_number_offset=$values[$i];
	    }
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

my $filespec=pop @ARGV;
my $group_name=pop @ARGV;

# ###########################################################################
#  End of startup section                                                   #
# ###########################################################################


#############################################################################
#      Now we're ready to Do The Business.  The following variables are     #
#      available:                                                           #
#                                                                           #
#         $group_name - The <group-name> specified on the command-line.     #
#                                                                           #
#           $filespec - The <filespec> specified on the command-line.       #
#                                                                           #
#      $rdimport_args - The list of rdimport options from the command-line. #
#                       Generally, it's safe to just pass this whole to     #
#                       rdimport(1).                                        #
#                                                                           #
#               @keys - The key (left side of the '=' sign) part of the     #
#                       command-line options, scrubbed of any rdimport(1)   #
#                       options.                                            #
#                                                                           #
#             @values - The value (right-hand side of '=' sign) part of the #
#                       command-line options, scrubbed of any rdimport(1)   #
#                       options.                                            #
#                                                                           #
#       $to_cart_used - Boolean.  If 'true', it means that the --to-cart    #
#                       option was specified --i.e. you probably don't want #
#                       use the cart number read from the file metadata.    #
#                                                                           #
# $cart_number_offset - Value of the --cart-number-offset option.           #
#############################################################################

my $title_to="user-defined";
my $legend_to="title";

#
# Process Options
#
for(my $i=0;$i<scalar @keys;$i++) {
    if($keys[$i] eq "--title-to") {
	$title_to=$values[$i];
    }	
    if($keys[$i] eq "--legend-to") {
	$legend_to=$values[$i];
    }	
}

#
# Run the import
#
@files=glob $filespec;
foreach $file (@files) {
    my $cfg=Config::IniFiles->new(-file=>$file);
    my $title=$cfg->val('Panel0','Title');
    for(my $i=0;$i<90;$i++) {
	my $wavefile=$cfg->val('Panel0','Wavefile'.$i);
	my $legend=$cfg->val('Panel0','Legend'.$i);
	if(!defined $legend) {
	    $legend=$wavefile;
	}
	if(defined $wavefile) {
	    my $cmd="rdimport ".$rdimport_args." ";
	    if($legend_to ne "") {
		$cmd=$cmd."\"--set-string-".$legend_to."=".$legend."\" ";
	    }
	    if($title_to ne "") {
		$cmd=$cmd."\"--set-string-".$title_to."=".$title."\" ";
	    }
	    $cmd=$cmd."\"".$group_name."\" \"".$wavefile."\"";
	    print "Importing ".$wavefile." [".$legend."].";
	    system $cmd;
	}
    }
}
