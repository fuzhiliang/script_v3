#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Data::Dumper;

my $choose = shift;
chomp($choose);
my $blast_file = shift;


open (BLAST,$blast_file) || die ("Could not open the blast file.");
if($choose == 0){
	while (<BLAST>){
		chomp;
		next if(/\* No hist found \*/);
		if(/^>/){
			print $_ . "\n";
		}
		if(/^Sbjct/){
			s/ //g;
			s/\-//g;
			/Sbjct[0-9]+([a-zA-Z]+)/;
			print $1 . "\n";
		
		}
	}
}elsif($choose == 1){
	while (<BLAST>){
		chomp;
		next if(/\* No hist found \*/);
		if(/<Hit_def>(.*)<\/Hit_def>/){
			print ">$1\n";
		}
		if(/<Hsp_hseq>(.*)<\/Hsp_hseq>/){
		#	$1 =~ s/\-//g;
			my $sg = $1;
			$sg =~ s/\-//g;
			print "$sg\n";
		}
	}
}

close BLAST;
