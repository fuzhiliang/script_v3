#!/bin/perl -w
use strict;

die "usage:perl $0 txt" unless @ARGV==1;

my $txt=shift;
my %hash;

open IN,"$txt" or die $!;
while(my $line=<IN>){
	chomp($line);
	my $test=(split/\t/,$line)[0];
	if($test eq "Chr"){
		print "ratio\tDP\tAO\tDP1\tAO1\t$line\n";
	}
	else{
		my $info=(split/\t/,$line)[53];
		my ($chr,$pos,$ref,$alt)=(split/\t/,$line)[46,47,49,50];
		my ($AO,$DP)=(split/;/,$info)[5,7];
		my $dp=$DP;
		my $ao=$AO;
		$AO=~s/AO=//;
		$DP=~s/DP=//;
		my @aa=split(/,/,$AO);
		if(exists $hash{$chr,$pos,$ref,$alt}){
			$hash{$chr,$pos,$ref,$alt}++;
			my $depth=$aa[$hash{$chr,$pos,$ref,$alt}];
			my $ratio=$depth/$DP;
			$ratio=printf ("%0.4f",$ratio);
			print "$ratio\t$DP\t$depth\t$dp\t$ao\t$line\n";
		}
		else{
			$hash{$chr,$pos,$ref,$alt}=0;
			my $depth=$aa[$hash{$chr,$pos,$ref,$alt}];
			my $ratio=$depth/$DP;
			$ratio=printf ("%0.4f",$ratio);
			print "$ratio\t$DP\t$depth\t$dp\t$ao\t$line\n";
		}
	}
}
close IN;
#适应fuzl的注释流程
