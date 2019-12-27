#! /usr/bin/perl -w
use strict;
use warnings;
use POSIX qw(strftime);
use Getopt::Std;
use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';
my $verbose ="v1.0";

die "将热点区域的freebayes Q13和Q30的结果提取到一起，并将多个alt的结果按一定顺序排列,只考虑snp\neg:\nperl $0 /home/fuzl/bed/508heart/heart_location.txt \\
/home/fuzl/project/huada_MGI2000/rawdata_v2/L03_L04_clear/HD753-2-1/vcf/HD753-2-1_freebayes_q30.snp.hg19_multianno.txt.freq \\
/home/fuzl/project/huada_MGI2000/rawdata_v2/L03_L04_clear/HD753-2-1/vcf/HD753-2-1.freebayesp_q13.hg19_multianno.txt.freq \\
 /home/fuzl/project/huada_MGI2000/rawdata_v2/L03_L04_clear/HD753-2-1/vcf/HD753-2-1.freebayesp.hg19_multianno.txt.freq_q30_q13merge \n" if (@ARGV<3);
#chr start	end	ref	alt	Q30_dp	Q30_ref	Q30_alt0	Q30_alt1	Q30_alt2	Q13_dp	Q13_ref	Q13_alt0	Q13_alt1	Q13_alt2	
my $heart=$ARGV[0];
my $Q30=$ARGV[1];
my $Q13=$ARGV[2];
my $out=$ARGV[3];


my %q30txt;
my %q30txtdp;
my %q13txt;
my %q13txtdp;
my %gene;
my %AA;
open Q30 ,"$Q30" or die $!;
while (<Q30>){
	chomp;
	next if (/Chr/);
	my $col="$#_";
	my ($ratio,$dp,$AO,$chr,$start,$end,$ref,$alt,$gene,$AA,$RO)=(split "\t", $_)[0,1,2,5,6,7,8,9,11,13,$col];
	$RO=(split ":",$RO)[3];
#	print "$RO\n$ratio,$dp,$AO,$chr,$start,$end,$ref,$alt,$gene,$AA,$RO\n";die;
	my $location="$chr\t$start\t$end\t$ref";
	my $dp_RO="$dp\t$RO";
	$q30txt{$location}{$alt}=$AO;
	$q30txtdp{$location}=$dp_RO;
	$gene{$location}{$alt}="$gene\t$AA";
	$AA{$location}="$gene";
}
close Q30;

open Q13 ,"$Q13" or die $!;
while (<Q13>){
	chomp;
	next if (/Chr/);
	my $col="$#_";
	my ($ratio,$dp,$AO,$chr,$start,$end,$ref,$alt,$gene,$AA,$RO)=(split "\t", $_)[0,1,2,5,6,7,8,9,11,14,$col];
	$RO=(split ":",$RO)[3];
	my $location="$chr\t$start\t$end\t$ref";
	my $dp_RO="$dp\t$RO";
	$q13txt{$location}{$alt}=$AO;
	$q13txtdp{$location}=$dp_RO; #dp 和 ref 深度
	$gene{$location}{$alt}="$gene\t$AA";
	$AA{$location}="$gene";
}
close Q13;


open C ,"$heart" or die $!;
#my $head=<C>;
open O ,">$out" or die $!;
open T ,">$out.un" or die $!;
my $head="#chr\tstart\tend\tref\talt\tQ30_dp\tQ30_ref\tQ30_alt0\tQ30_alt1\tQ30_alt2\talt\tQ13_dp\tQ13_ref\tQ13_alt0\tQ13_alt1\tQ13_alt2\tgene\tAAchange\n";
print O $head;
while (<C>){
	chomp;
	my ($chr,$start,$ref,$alt)=(split "\t",$_);
 
	my $length=length($ref)-length($alt);
	next unless ($length==0 ); 
	my $end=$start+length($ref)-1;
#	$end+=length($ref)-1  if ($length==0 && length($ref)>1);
	my $location="$chr\t$start\t$start\t$ref";
	my %alt=(A=>1,C=>1,G=>1,T=>1);

	delete $alt{$ref};
	my $tmp="";
	my $flag=0;
	if (exists $q30txt{$location}){
		if (exists $q30txt{$location}{$alt}){
			$tmp.="$location\t$alt\t$q30txtdp{$location}\t$q30txt{$location}{$alt}";
#			delete %{$q30txt{$location}{$alt}};
		}else{
			$tmp.="$location\t$alt\t$q30txtdp{$location}\t-";
		}
		delete $alt{$alt};
		foreach my $alt (sort {$a cmp $b } keys %alt){
			if (exists $q30txt{$location}{$alt}){
				$tmp.="\t$q30txt{$location}{$alt}";
			}else{
				$tmp.="\t-";
			}
		}

	$flag=1;
	}else{
		$tmp.="$location\t$alt\t-\t-\t-\t-\t-";
	}
	%alt=(A=>1,C=>1,G=>1,T=>1);
	delete $alt{$ref};	
	if (exists $q13txt{$location}){
		if (exists $q13txt{$location}{$alt}){
			$tmp.="\t$alt\t$q13txtdp{$location}\t$q13txt{$location}{$alt}";
#			delete %{$q30txt{$location}{$alt}};
		}else{
			$tmp.="\t$alt\t$q13txtdp{$location}\t-";
		}
			delete $alt{$alt};
			foreach my $alt ( sort {$a cmp $b } keys %alt){
				#print "alt\t$alt\n";
				if(exists $q13txt{$location}{$alt}){
					$tmp.="\t$q13txt{$location}{$alt}";
				}else{
					$tmp.="\t-";
				}
			}
	$flag=1;
	}else{
		$tmp.="\t$alt\t-\t-\t-\t-\t-";
	}
	if (exists $gene{$location}{$alt}){
		$tmp.="\t$gene{$location}{$alt}";
	}elsif(exists $AA{$location}){
		$tmp.="\t$AA{$location}\t-";
	}else{$tmp.="\t-\t-";}
	if ($flag==1){
		print O "$tmp\n" ;	
	}else{
		print T "$tmp\n";
	}
}
close C;
close O;
close T;


=c
chr1    11177096        11177096        C       A       -       -       -       -       -       A       -       -       -       -       2
chr1    11177096        11177096        C       T       -       -       -       -       -       T       -       -       -       -       2
chr1    11182158        11182158        A       C       -       -       -       -       -       C       -       -       -       -       2
=cut


