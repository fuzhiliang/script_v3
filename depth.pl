#! /usr/bin/perl -w
use strict;
use warnings ;
use Data::Dumper;
my $depth=$ARGV[0];
my $bed=$ARGV[1];
my $windows=$ARGV[2];
my $out=$ARGV[3];
my $warnings=$ARGV[4];

$warnings||=500; #depth <=500x , print out Warnings file; 
die "perl $0  *.bam.depth 38-cf1-genepanel.bed 10 *_windows_10  500\n" if (@ARGV<3);
my %hash;
open B ,"$bed" or die $!;
while (<B>) {
	chomp;
	my (@tmp)=split "\t",$_;
	my $length=$tmp[2]-$tmp[1];
	for (my $i=$tmp[1]; $i<$tmp[2];$i+=$windows) {
		my $end=$i+$windows-1;
		$end=$tmp[2] if ($end > $tmp[2]) ;
		$hash{$tmp[0]}{$i}=$end;
	}
}

my %hash2;
open D ,"$depth" or die $!;
while (<D>) {
	chomp;
	my (@tmp)=split "\t",$_;
	#print "@tmp\n" ;die;
	if (exists $hash{$tmp[0]}) {
		my $chr =$tmp[0];
		foreach my $start (keys %{$hash{$chr}}) {
				if (($tmp[1]>=$start) && ($tmp[1]<=$hash{$chr}{$start})) {
					my $name="$chr\t$start\t$hash{$chr}{$start}";
					$hash2{$name}+=$tmp[2];
#				$hash2{$name}+=1;
				}
			}
		}	
}
close D;
#print Dumper %hash2;

open O ,">$out" or die $!;


open O1,">$out.bed" or die $!;
open W,">$out.warnings.bed" or die $! ;
foreach my $chr (sort {$a cmp $b} keys %hash) {
	foreach my $start (sort {$a <=> $b} keys %{$hash{$chr}}) {
		my $name="$chr\t$start\t$hash{$chr}{$start}";
		my $length=$hash{$chr}{$start}-$start+1;
			if (exists $hash2{$name}){
				my $rate=$hash2{$name}/$length;
				print O "$name\t$length\t$hash2{$name}\t$rate\n";
				if ($rate<=$warnings){
					print W "$name\t$length\t$hash2{$name}\t$rate\n";
				}
			}else{
				print O "$name\t$length\t0\t0\n";
				print W "$name\t$length\t0\t0\n";		
			}
			print O1 "$chr\t$start\t$hash{$chr}{$start}\n";
	}
}
close B;
close O1;
close O;


=cut
[zhangjl@web txt]$ pwd
/home/zhangjl/temp/txt 
根据samtools depth的结果统计覆盖度，计算没有覆盖的区域。
for i in `ls *rmdup.bam.txt`; do perl depth.pl $i ../38-cf1-genepanel.bed 10 ${i}_windows_10 500 &    done
for i in `ls *rmdup.bam.txt`; do cut -f 6 ${i}_windows_10 > ${i}_windows_10_cut6 &    done

sed 's/\t/_/g' lib-FZ18-04625F.rmdup.bam.txt_windows_10.bed  >id

ls *F.rmdup.bam.txt_windows_10_cut6 |tr "\n" " "|awk '{print "paste id "$0" >paste_windows10.F.txt " }'
ls *P.rmdup.bam.txt_windows_10_cut6 |tr "\n" " "|awk '{print "paste id "$0" >paste_windows10.P.txt " }'
ls *T.rmdup.bam.txt_windows_10_cut6 |tr "\n" " "|awk '{print "paste id "$0" >paste_windows10.T.txt " }'
ls *B.rmdup.bam.txt_windows_10_cut6 |tr "\n" " "|awk '{print "paste id "$0" >paste_windows10.B.txt " }'

 ls *B.rmdup.bam.txt_windows_10_cut6 |tr "\n" "\t" |sed 's/.rmdup.bam.txt_windows_10_cut6//g' |awk '{print "ID\t"$0}' >head.B
ls *P.rmdup.bam.txt_windows_10_cut6 |tr "\n" "\t" |sed 's/.rmdup.bam.txt_windows_10_cut6//g' |awk '{print "ID\t"$0}' >head.P
ls *F.rmdup.bam.txt_windows_10_cut6 |tr "\n" "\t" |sed 's/.rmdup.bam.txt_windows_10_cut6//g' |awk '{print "ID\t"$0}' >head.F
ls *T.rmdup.bam.txt_windows_10_cut6 |tr "\n" "\t" |sed 's/.rmdup.bam.txt_windows_10_cut6//g' |awk '{print "ID\t"$0}' >head.T 

for i in F T P B
do
cat head.$i paste_windows10.$i.txt > paste_windows10.$i.txt.head &
done

scp *.head fuzl@192.168.10.11:/data2/fuzl/project/Depth_lip 




