#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use Data::Dumper;
use FileHandle;
die "perl $0 bam out \n" if (@ARGV < 2); 
my $in=$ARGV[0];
my %hash;
my %hash2;
#my %hash3;
open A ,"samtools view -F4 $in|" or die $!;
while (<A>){
        chomp ;
        next if (/^\s+$/);
        my ($id,$ref,$map)=(split '\t', $_)[0,2,5];
        my ($type,$loc)=(split "_",$ref)[0,1];
      #  print $loc;
        $hash2{$id}{$type}++;
        
        if (exists $hash{$id}){
                next if (exists $hash2{$id}{$loc});
                $hash{$id}.="\t$ref\;$map";
        #       print $_;
        }else{
                $hash{$id}="\t$ref\;$map";      
        }
        $hash2{$id}{$loc}++;
}
#print Dumper %hash;

open O ,"> $ARGV[1]" or die $!;
foreach my $id(keys %hash){
        my $tmp="";
        $tmp.=(exists $hash2{$id}{'left'})?"\t$hash2{$id}{'left'}":"\t0";
        $tmp.=(exists $hash2{$id}{'right'})?"\t$hash2{$id}{'right'}":"\t0";
   
        print O "$id$hash{$id}$tmp\n"; 
        
}