#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use Data::Dumper;
use FileHandle;
my $usage=<<USAGE;
	Usage:
		perl $0 [options]
			*-r1 --read1 <string>		read1.fq.gz
			*-r2 --read2 <string>		read2.fq.gz
			 -e  --errNum <int>		mismatch number [default: 0]
			*-f  --firstCycle <int>		first cylce of barcode
			*-l  --lastCycle <int>		last cycle of barcode
			*-b  --barcodeList <string>	barcodes list
			 -rc --revcom	<Y|N>		generate reverse complement of barcode.list or not
			 -c  --compress <Y|N>		compress(.gz) output or not [default: Y]
			 -o  --outdir <string>		output directory [default: ./]
			 -h  --help			print help information and exit
	Example:
		perl $0 -r1 read1.fq.gz -r2 read2.fq.gz -e 2 -f 100 -l 110 -b barcode.list -o /path/outdir
		
	============barcode.list===========
	#barcodeNum	barcodeSeq
	1	ATGCATCTAA
	2	AGCTCTGGAC
	===================================
USAGE

#=============global variants=============
my ($read1,$read2,$errNum,$fc,$lc,$bl,$compress,$outdir,$rc,$help);
my (%bchash,$prefix,$ambo1,$ambo2);
#=========================================
GetOptions(
	"read1|r1=s"=>\$read1,
	"read2|r2=s"=>\$read2,
	"errNum|e:i"=>\$errNum,
	"firstCycle|f=i"=>\$fc,
	"lastCycle|l=i"=>\$lc,
	"barcodeList|b=s"=>\$bl,
	"revcom|rc:s"=>\$rc,
	"compress|c:s"=>\$compress,
	"outdir|o:s"=>\$outdir,
	"help|h:s"=>\$help
);
$errNum||=0;
$outdir ||= `pwd`;
$compress ||= 'Y';
$rc ||= 'Y';
print "ErrNum:$errNum\n";
if(!$read1 || !$read2 || !$fc || !$lc || !$bl || $help ){
	die "$usage";
}

#========global variables==========
my (%barhash,%oh,%oribar,%correctBar,%correctedBar,%unknownBar,$totalReadsNum);
my (%tagNum,$am1,$am2,@fq);
#=========================

my $name=basename($read2);
$prefix=$1 if $name=~/(.*)\_(\w+)_2\.fq(.gz)?/;
unless(-e $outdir){
	print STDERR "$outdir: No such directory, but we will creat it\n";
	`mkdir -p $outdir`;
}
$outdir=abs_path($outdir);
chomp($outdir);
open my $fh,$bl or die "$bl No such file, check it !\n$!";
#if(uc($compress) eq 'Y'){
#	open $am1,"|gzip -9 >$outdir/$prefix\_ambiguous_1.fq.gz" or die $!;
#	open $am2,"|gzip -9 >$outdir/$prefix\_ambiguous_2.fq.gz" or die $!;
#}else{
open $am1,">$outdir/$prefix\_unbarcoded_1.fq" or die $!;
open $am2,">$outdir/$prefix\_unbarcoded_2.fq" or die $!;
push @fq,"$outdir/$prefix\_unbarcoded_1.fq";
push @fq,"$outdir/$prefix\_unbarcoded_2.fq";
#}
open my $BS,">$outdir/BarcodeStat.txt" or die $!;
open my $SS,">$outdir/TagStat.txt" or die $!;

print $BS "#SpeciesNO\tCorrect\tCorrected\tTotal\tPct\n";
print $SS "#Sequence\tSpeciesNO\treadCount\tPct\n";

while(<$fh>){	#1	ATGCATCTAA
	next if /^#/;
	chomp;
	my @tmp=split /\s+/,$_;
	if(uc($rc) eq 'Y'){
		$tmp[1]=reverse(uc($tmp[1]));
		$tmp[1]=~tr/ATCGN/TAGCN/;
	}else{
		$tmp[1]=uc($tmp[1]);
	}
	$oribar{$tmp[1]} =1;
	&bar_hash($tmp[1],$tmp[0],$errNum,\%barhash);
#	if(uc($compress) eq 'Y'){
#		open $oh{$barhash{$tmp[1]}}[0],"|gzip -9 >$outdir/$prefix\_$tmp[0]\_1.fq.gz" or die $!;
#		open $oh{$barhash{$tmp[1]}}[1],"|gzip -9 >$outdir/$prefix\_$tmp[0]\_2.fq.gz" or die $!;
#	}
#	else{
	open $oh{$barhash{$tmp[1]}}[0],">$outdir/$prefix\_$tmp[0]\_1.fq" or die $!;
	open $oh{$barhash{$tmp[1]}}[1],">$outdir/$prefix\_$tmp[0]\_2.fq" or die $!;
	push @fq,"$outdir/$prefix\_$tmp[0]\_1.fq";
	push @fq,"$outdir/$prefix\_$tmp[0]\_2.fq";
#	}
}
close $fh;
my($rd1,$rd2);
if($read2=~/fq$/){
	open $rd1,$read1 or die $!;
	open $rd2,$read2 or die $!;
}
elsif($read2=~/fq.gz$/){
	open $rd1,"gzip -dc $read1|" or die $!;
	open $rd2,"gzip -dc $read2|" or die $!;
}

while(<$rd1>){
	my $head1= $_;
	my $seq1 = <$rd1>;
	my $plus1= <$rd1>;
	my $qual1= <$rd1>;
	my $head2= <$rd2>;
	my $seq2 = <$rd2>;
	my $plus2= <$rd2>;
	my $qual2= <$rd2>;
	$totalReadsNum ++;
	chomp($head1,$seq1,$plus1,$qual1,$head2,$seq2,$plus2,$qual2);
	my $barseq=substr($seq2,$fc-1,$lc-$fc+1);
#	print "$barseq\n";
#	die if ($.==1000);
	$tagNum{$barseq} ++;
	if(exists $barhash{$barseq}){
#		my $spitseq2=substr($seq2,0,$fc-1);#.substr($seq2,$lc,);
#		my $spitqual2=substr($qual2,0,$fc-1);#.substr($qual2,$lc,);
		my $spitseq2=substr($seq2,0,$fc-9);#.substr($seq2,$lc,);
		my $spitqual2=substr($qual2,0,$fc-9);#.substr($qual2,$lc,);
		my $barseq_uid=substr($seq2,$fc-1,$lc-$fc+5).substr($seq2,0,4);##自制UID在reads 5'还有4bp uid

		#my $fh1=$oh{$barhash{$barseq}}[0];my$fh2=$oh{$barhash{$barseq}}[1];
		$oh{$barhash{$barseq}}[0]->print("$head1\t$barseq_uid\n$seq1\n$plus1\n$qual1\n");
		$oh{$barhash{$barseq}}[1]->print("$head2\t$barseq_uid\n$spitseq2\n$plus2\n$spitqual2\n");
		#print $fh1 "$head1\n$seq1\n$plus1\n$qual1\n";
		#print $fh2 "$head2\n$spitseq2\n$plus2\n$spitqual2\n";
		if(exists $oribar{$barseq}){
			$correctBar{$barhash{$barseq}} +=1;
		}
		else{
			$correctedBar{$barhash{$barseq}} +=1;
		}
	}
	else{
		my $spitseq2=substr($seq2,0,$fc-1).substr($seq2,$lc,);
		my $spitqual2=substr($qual2,0,$fc-1).substr($qual2,$lc,);
		print $am1 "$head1\t$barseq\n$seq1\n$plus1\n$qual1\n";
		print $am2 "$head2\t$barseq\n$spitseq2\n$plus2\n$spitqual2\n";
		$unknownBar{$barseq} +=1;
	}
}
close $rd1;close $rd2;
close $am1;close $am2;

my($totalcorrect,$totalcorrected,$totalbarreads,$totalpct);
for my $seq(sort {$barhash{$a}<=>$barhash{$b}} keys %oribar){
	my $BartotalReads = $correctBar{$barhash{$seq}}+$correctedBar{$barhash{$seq}};
	my $pct = ($BartotalReads/$totalReadsNum)*100;
	$totalcorrect += $correctBar{$barhash{$seq}};
	$totalcorrected+=$correctedBar{$barhash{$seq}};
	$totalbarreads += $BartotalReads;
	$totalpct += $pct;
	#print $BS "$barhash{$seq}\t$correctBar{$seq}\t$correctedBar{$seq}\t$BartotalReads\t$pct\n";
	printf $BS "%s\t%d\t%d\t%d\t%.4f%%\n",$barhash{$seq},$correctBar{$barhash{$seq}},$correctedBar{$barhash{$seq}},$BartotalReads,$pct;
}
#print $BS "Total\t$totalcorrect\t$totalcorrected\t$totalbarreads\t$totalpct\n";
printf $BS "Total\t%d\t%d\t%d\t%.4f%%\n",$totalcorrect,$totalcorrected,$totalbarreads,$totalpct;
close $BS;

for my $seq(sort {$tagNum{$b}<=>$tagNum{$a}} keys %tagNum){
	my $pct=($tagNum{$seq}/$totalReadsNum)*100;
	if(exists $barhash{$seq}){
		#print $SS "$seq\t$barhash{$seq}\t$tagNum{$seq}\t$pct\n";
		printf $SS "%s\t%s\t%d\t%.2f%%\n",$seq,$barhash{$seq},$tagNum{$seq},$pct;
	}
	else{
		#print $SS "$seq\tunknown\t$tagNum{$seq}\t$pct\n";
		printf $SS "%s\tunknow\t%d\t%.2f%%\n",$seq,$tagNum{$seq},$pct;
	}
}
close $SS;
if(uc($compress) eq 'Y'){
	for my $fastq(@fq){
		my $gz=$fastq.'.gz';
		system("echo \"gzip -f $fastq > $gz \" > $fastq.sh && sh $fastq.sh &");
	}
}

#=============subroutine==================
sub bar_hash{
	my ($seq,$name,$errnum,$hash)=@_;
	my ($tmp_seq);
	my @bases=('A','T','C','G','N');
	if($errnum==0){
		$hash->{$seq} =$name;
		return $hash;
	}else{
		for (my $i=0;$i<length($seq);$i++){
			for (my $j=0;$j<@bases;$j++){
				$tmp_seq =substr($seq,0,$i).$bases[$j].substr($seq,$i+1,);
				if($errnum > 1){
					&bar_hash($tmp_seq,$name,$errnum-1,$hash);
				}
				else{
					$hash->{$tmp_seq}=$name;
				}
			}
		}
		return $hash;
	}
}
