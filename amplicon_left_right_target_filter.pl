#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use Data::Dumper;
use FileHandle;
die "perl $0 /home/fuzl/project/amplicon_shengchan_new/database_v2/genename-t.txt /home/fuzl/project/amplicon_shengchan_new/test/join/cDNA-392_S1_join/cDNA-392_S1.sorted.fusion  out \n" if (@ARGV < 3); 
=c
#genename-t.txt
SLC34A2 exon14  ROS1    exon32
CD74    exon6   ROS1    exon32
#filter before
MN00706:2:000H23TTK:1:13103:19393:8098  left_chr2:29445383-29445473;ALK-exon20;45S90M47S        left_chr2:29446208-29446394;ALK-exon19;136H36M10H       right_chr2:29445210-29445274;ALK-exon21;44M138H 2       1
=cut
my $in=$ARGV[1];
my %hash;
my %hash2;
#my %hash3;
open G ,"$ARGV[0]" or die $!;

while (<G>){
    chomp;
    my @tmp=split "\t", $_;
    my $left=$tmp[0].'-'.$tmp[1];
    my $right=$tmp[2].'-'.$tmp[3];
    $hash{$left}{$right}=1;
}

open O ,"> $ARGV[2]" or die $!;
open A ,"$in" or die $!;
while (<A>){
    chomp ;
    next if (/^\s+$/);
    my @tmp=split '\t', $_;
    my $id=shift@tmp;
    my $num_right=pop@tmp;
    my $num_left=pop@tmp;
    next if ($num_right*$num_left==0);
    for (my $i=0;$i<$num_left;$i++){
        for (my $j=$num_left;$j<=$#tmp;$j++){
            my $l=(split ";",$tmp[$i])[1];
            my $r=(split ";",$tmp[$j])[1];
            if (exists $hash{$l}{$r}){
                print O "$l\t$r\t$_\n";
            }
        }
    }

}
#print Dumper %hash;
close O;
close A;
close G;
