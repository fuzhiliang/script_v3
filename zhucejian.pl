#! /usr/bin/perl -w
use strict;
use warnings ;
use Data::Dumper;
my $neg=$ARGV[0];
my $pos=$ARGV[1];
my $out=$ARGV[2];

die "" if (@ARGV <2);
my %hash;
open N ,"$neg" or die $!;
while (<N>){
	chomp;
	my $loc=(split "\t", $_)[1];
	$hash{$loc}=$_;
}

open P ,"$pos" or die $!;
my $head=<P>;

while (<P>){
	chomp;
	my $loc=(split "\t", $_)[1];
	$hash{$loc}=$_;
}

open O ,">$out" or die $!;

print O $head;
foreach my $key (keys %hash){
	print O "$hash{$key}\n";
}
#########

###ddddd





