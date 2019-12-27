#! /usr/bin/perl -w
my $in=$ARGV[0];
my $out=$ARGV[1];
my $sample=$ARGV[2];

die "$0 out 20 \n" if (@ARGV <2);

$/=">>" ;
my %hash;
open I ,"$in" or die $!;

while (<I>){
	chomp;
	my ($name,$sum)=(split "\n",$_,2);
	$name=(split "\t",$name)[0];
	$hash{$name}=$sum;

}
close I;
$/="\n";
open O ,">$out " or die $!;
my $n="Per base sequence content";

if (exists $hash{$n}){
	print O "$sample\n$hash{$n}\n";
}

close O;