#!/usr/bin/perl
#INSTALL@ /usr/local/bin/roffmerge
#INSTALLEDFROM verlaine:/home/ljm/src/roffmerge
use strict;
use warnings;
use Text::CSV;

sub usage {
print"
NAME:	 roffmerge -- mail merge for *roff
SYNOPSIS:
		  roffmerge csv-file  text-file 
		  roffmerge -h
DESCRIPTION:

Roffmerge generates personalized documents (such as letters, labels, or emails) by combining a template
document, typically in groff, with a CSV file as data source. The data source contains fields like names,
addresses, or other custom information, which are inserted into predefined placeholders in the template.

The first line in the CSV file must be the column name that is used for the placeholder. Fields are 
separated by a , (comma). Fields may be quoted using \" (double quotes). Fields must not contain {-- or
--}.

DEPENDENCIES:
	Text::csv
"}

my $csvfilename;
my $textfilename;
my @text;
my $row;
my %fieldnames;
my $mergetype='=';
my $pagenr=0;
# Label definition; default=herma4550
my $qtyx=3;	
my $qtyy=9;
my $topx=0;
my $topy=0.5;
my $width=7;
my $height=3.2;
my $xspace=0;
my $yspace=0;

#                                             _       
#   __ _ _ __ __ _ _   _ _ __ ___   ___ _ __ | |_ ___ 
#  / _` | '__/ _` | | | | '_ ` _ \ / _ \ '_ \| __/ __|
# | (_| | | | (_| | |_| | | | | | |  __/ | | | |_\__ \
#  \__,_|_|  \__, |\__,_|_| |_| |_|\___|_| |_|\__|___/
#            |___/      

if ( ! defined $ARGV[0]){
	usage();
	exit;
}
elsif ($ARGV[0] eq '-h'){
	usage();
	exit;
}
else {
	$csvfilename=$ARGV[0];
}
if ( ! defined $ARGV[1]){
	usage();
	exit;
}
else {
	$textfilename=$ARGV[1];
}
#                     _   _            _      __ _ _      
#  _ __ ___  __ _  __| | | |_ _____  _| |_   / _(_) | ___ 
# | '__/ _ \/ _` |/ _` | | __/ _ \ \/ / __| | |_| | |/ _ \
# | | |  __/ (_| | (_| | | ||  __/>  <| |_  |  _| | |  __/
# |_|  \___|\__,_|\__,_|  \__\___/_/\_\\__| |_| |_|_|\___|
#
open my $FH, '<', $textfilename or die "Could not open file: $!";
@text=<$FH>;
close $FH;

#                     _    ____ ______     __  _                    _           
#  _ __ ___  __ _  __| |  / ___/ ___\ \   / / | |__   ___  __ _  __| | ___ _ __ 
# | '__/ _ \/ _` |/ _` | | |   \___ \\ \ / /  | '_ \ / _ \/ _` |/ _` |/ _ \ '__|
# | | |  __/ (_| | (_| | | |___ ___) |\ V /   | | | |  __/ (_| | (_| |  __/ |   
# |_|  \___|\__,_|\__,_|  \____|____/  \_/    |_| |_|\___|\__,_|\__,_|\___|_|   
#                                                                                

# Create a new CSV parser object
my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

# Open the CSV file
open my $fh, "<", $csvfilename or die "Could not open file: $!";

if ($row = $csv->getline($fh)) {
	my $i=0;
	foreach my $field (@$row) {
		$fieldnames{$field}=$i;
		$i++;
	}
}
else {
	die "Cannot get the header from $csvfilename";
}

#  _ _                 _                               _ _                 
# (_) |_ ___ _ __ __ _| |_ ___    _____   _____ _ __  | (_)_ __   ___  ___ 
# | | __/ _ \ '__/ _` | __/ _ \  / _ \ \ / / _ \ '__| | | | '_ \ / _ \/ __|
# | | ||  __/ | | (_| | ||  __/ | (_) \ V /  __/ |    | | | | | |  __/\__ \
# |_|\__\___|_|  \__,_|\__\___|  \___/ \_/ \___|_|    |_|_|_| |_|\___||___/
#   
foreach my $line (@text){
	if ($line =~ /^\.mergetype  *(.*)/){
		$mergetype=$1;
		chomp $mergetype;
		readlabels($mergetype);
		firstone();
	}
}

while ($row = $csv->getline($fh)) {
	# $row is an array reference containing the fields in the line
	my @lines;
	undef @lines;
	@lines=@text;
	nextone();
	foreach my $line (@lines){
		if ($line =~ /^\.mergetype  *(.*)/){
		}
		else {
			while ($line =~/{--(.*?)--\}/){
				my $fieldnr=$fieldnames{$1};
				my $fieldvalue=$row->[$fieldnr];
				$fieldvalue='' unless defined $fieldvalue;
				$line=~s/\{--.*?--\}/$fieldvalue/;
			}
			print $line;
		}
	}
}

# Close the file
close $fh or die "Could not close file: $!";

sub firstone {
	if ($mergetype eq 'herma4550'){
		$qtyx=3;	
		$qtyy=9;
		$topx=0;
		$topy=0.5;
		$width=7;
		$height=3.2;
		$xspace=0;
		$yspace=0;
		$mergetype='labels';
		labelmacro();
		print ".LABELCONTINUE ${topx}c ${topy}c ${width}c\n";
	}
	else {
		readlabels("/usr/lib/labels/$mergetype");
		readlabels("/usr/local/lib/labels/$mergetype");
		readlabels("$mergetype");
	}
}

sub nextone{
	if ($mergetype eq '='){
		if ($pagenr>0){
			print "=====================\n";
		}
		$pagenr++;
	}
	elsif ($mergetype eq 'page'){
		if ($pagenr>0){
			print ".bp\n";
		}
		$pagenr++;
	}
	elsif ($mergetype eq 'labels'){
		
		my $labelonpage=$pagenr%($qtyx*$qtyy);
		my $labelcol=$labelonpage%$qtyx;
		my $labelrow=int($labelonpage/$qtyx);
		my $xpos=$topx+$labelcol*($width+$xspace);
		my $ypos=$topy+$labelrow*($height+$yspace);
		print ".LABELCONTINUE ${xpos}c ${ypos}c ${width}c\n";
		$pagenr++;
	}
}

sub labelmacro {
	print ".de LABELCONTINUE\n";
#	print ".  ll \\\\n(.l                 \" Reset line length to its original value\n";
	print ".  sp |\\\\\$2                  \" Move to the specified y-offset\n";
	print ".  in \\\\\$1                   \" Set the indent to x-offset\n";
	print ".  ll \\\\\$1+\\\\\$3              \" Set the line length to x-offset + width\n";
	print "..\n";
	print ".po 0\n";
}

sub readlabels{
	(my $labelfile)=@_;
	if (open my $LBL,'<',$labelfile){
		$mergetype='labels';
		print ".po 0\n";
		labelmacro();
		while (<$LBL>){
			chomp;
			s/#.*//;
			if(/qtyx=([0-9][0-0]*)/){ $qtyx=$1;}
			if(/qtyy=([0-9][0-0]*)/){$qtyy=$1;}
			if(/topx=(\d+\.?\d*)/){$topx=$1;}
			if(/topy=(\d+\.?\d*)/){$topy=$1;}
			if(/width=(\d+\.?\d*)/){$width=$1;}
			if(/height=(\d+\.?\d*)/){$height=$1;}
			if(/xspace=(\d+\.?\d*)/){$xspace=$1;}
			if(/yspace=(\d+\.?\d*)/){$yspace=$1;}
		}
	}
}
