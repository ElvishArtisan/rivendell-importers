#!/usr/bin/perl
#/usr/bin/perl -Wall
#
# dadpro-import.pl
#
# Import audio files from an ENCO DADPro System into Rivendell
#
# (C) Copyright 2015 Fred Gleason <fredg@paravelsystems.com>
#
#  This script requires the Perl 'Xbase' module, available at:
#
#    http://www.dcs.ed.ac.uk/home/perl5/Xbase.html
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

use Xbase;

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


my $usage="USAGE: dadpro-import.pl --dbf-file=<filename> --first-cut=<dad-cut> --last-cut=<dad-cut> --cart-offset=<offset> <group-name> <cut-dir>";
if(scalar @ARGV lt 3) {
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
	print "invalid argument\n";
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

my $cutdir=pop @ARGV;
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
#             $cutdir - The <cut-dir> specified on the command-line.        #
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

#
# Get DBF Filepath
#
my $dbf_name;
for(my $i=0;$i<scalar @keys;$i++) {
    if($keys[$i] eq "--dbf-file") {
	$dbf_name=$values[$i];
    }
}

#
# Cart Range
#
my $first_cut=1;
my $last_cut=99999;
my $cart_offset=0;
for(my $i=0;$i<scalar @keys;$i++) {
    if($keys[$i] eq "--cart-offset") {
	$cart_offset=int($values[$i]);
	if((int($values[$i])<-99998)||(int($values[$i])>900000)) {
	    print "dadpro-import.pl: invalid \"--cart-offset\"\n";
	    exit(1);
	}
    }
    if($keys[$i] eq "--first-cut") {
	$first_cut=int($values[$i]);
	if(($first_cut<1)||($first_cut>99999)) {
	    print "dadpro-import.pl: invalid \"--first-cut\" value\n";
	    exit(1);
	}
    }
    if($keys[$i] eq "--last-cut") {
	$last_cut=int($values[$i]);
	if(($last_cut<1)||($last_cut>99999)) {
	    print "dadpro-import.pl: invalid \"--last-cut\" value\n";
	    exit(1);
	}
    }
}
if($first_cut > $last_cut) {
    print "dadpro-import.pl \"--first-cut\" must be less than or equal to \"--last-cut\"\n";
    exit(1);
}

my $dbh=new Xbase;
$dbh->open_dbf($dbf_name);
$dbh->go_top;
while (!$dbh->eof) {
    my $cutnum=$dbh->get_field("CUT");
    my $cutpath=$cutdir."/".$dbh->get_field("CUT").".MP2";
    if(($cutnum>=$first_cut)&&($cutnum<=$last_cut)) {
	if(-f $cutpath) {
	    my $cmd="rdimport ".$rdimport_args;
	    $cmd=$cmd.sprintf(" --to-cart=%u",$cutnum+$cart_offset);
	    $cmd=$cmd." --set-string-title=\"".&trim($dbh->get_field("TITLE"))."\"";
	    $cmd=$cmd." --set-string-artist=\"".&trim($dbh->get_field("ARTIST"))."\"";
	    $cmd=$cmd." --set-string-outcue=\"".&trim($dbh->get_field("OUTCUE"))."\"";
	    $cmd=$cmd." --set-string-agency=\"".&trim($dbh->get_field("AGENCY"))."\"";
	    $cmd=$cmd." --set-string-user-defined=\"".&trim($dbh->get_field("USERDEF"))."\"";
	    $cmd=$cmd." --set-string-album=\"".&trim($dbh->get_field("ALBUM"))."\"";
	    $cmd=$cmd." --set-string-composer=\"".&trim($dbh->get_field("COMPOSER"))."\"";
	    $cmd=$cmd." --set-string-song-id=\"".&trim($dbh->get_field("SONGID"))."\"";
#	    $cmd=$cmd.sprintf(" --set-marker-start-cut=%d",$dbh->get_field("STARTTIME")*1000);
#	    $cmd=$cmd.sprintf(" --set-marker-end-cut=%d",$dbh->get_field("ENDTIME")*1000);
#	    $cmd=$cmd.sprintf(" --set-marker-start-talk=%d",$dbh->get_field("STARTTALK")*1000);
#	    $cmd=$cmd.sprintf(" --set-marker-end-talk=%d",$dbh->get_field("ENDTALK")*1000);
#	    $cmd=$cmd.sprintf(" --set-marker-start-hook=%d",$dbh->get_field("HOOKSTART")*1000);
#	    $cmd=$cmd.sprintf(" --set-marker-end-hook=%d",$dbh->get_field("HOOKEND")*1000);
#	    $cmd=$cmd.sprintf(" --set-marker-start-segue=%d",$dbh->get_field("SEGUESTART")*1000);
#	    $cmd=$cmd.sprintf(" --set-marker-end-segue=%d",$dbh->get_field("SEGUELEN")*1000);
	    #$cmd=$cmd." ".&trim($dbh->get_field("GROUP"));
	    $cmd=$cmd." ".$group_name;
	    $cmd=$cmd." ".$cutpath;
	    printf "Importing cut %d [%s]\n",$cutnum,&trim($dbh->get_field("TITLE"));
	    #print "CMD: ".$cmd."\n";
	    system($cmd);
	}
	else {
	    printf STDERR "Cut %d [%s] has no audio, skipping...\n", $cutnum,&trim($dbh->get_field("TITLE"));
	}
    }
    $dbh->go_next;

}

exit(0);


sub SetString
{
    my $field=$_[0];
    my $value=$_[1];

    if($value eq "") {
	return "";
    }
    return " --set-string-".$field."=\"".$value."\"";
}


sub trim 
{ 
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    return $s 
}
