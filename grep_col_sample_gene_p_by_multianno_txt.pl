#!/usr/bin/perl -w
use strict;
#use Cwd qw(abs_path);
use Getopt::Long;
use Data::Dumper;
#use FindBin qw($Bin $Script);
#use File::Basename qw(basename dirname);
#use newPerlBase;
my $BEGIN_TIME=time();
my $version="1.0";

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($heart,$outdir,$vcf_txt);

GetOptions(
    "heart:s" =>\$heart,
    "outdir:s" =>\$outdir,
    "vcf_txt:s" =>\$vcf_txt,
    ) or &USAGE;
&usage unless ($heart and $outdir );
#die "perl $0 --heart all_HD_heart_gene_p.txt --outdir hd -vcf_txt \n根据txt文件,三列sample,gene,p点，提取注释后txt文件对应的点\n" unless  (-f $heart && -f $vcf_txt);
#/home/fuzl/bed/gene_c_p_location/41_heart.txt
#chr14  105246551   105246551   207 AKT1    NM_005163   /   /   COSM33765   1   c.49G>A  p.E17K  1

#all_HD_heart_gene_p.txt        heart
#lib-HD-1    FGFR1   P150L
`mkdir $outdir ` unless  (-d $outdir );
`rm $outdir/*.txt`;
open I ,"$heart" or die $!;
while (<I>) {
    chomp ;
    my ($sample,$gene,$p)=(split "\t",$_)[0,1,2];
    if ($p){
    	`grep $gene $vcf_txt/$sample*/vcf/${sample}*.hg19_multianno.txt|grep -E "$p" >>$outdir/$sample.snpindel ` ;  
    	`grep $gene $vcf_txt/$sample*/SE_$sample*/Result/${sample}*fusions.txt|grep -E "$p"|wc -l >>$outdir/${sample}_${p}_${gene}.SE ` ;  
    	my $flag=`grep $gene $vcf_txt/$sample*/vcf/${sample}*.hg19_multianno.txt|grep -E "$p"`; 
    	unless ($flag){
    #		`echo "$_" >> $outdir/$sample.txt `    		
    	}
    }else{
    #	`echo "$_" >> $outdir/$sample.txt `
    }
}
close I;
sub usage {
    die(
        qq!
Usage:
	eg:
#/home/fuzl/project/huada_MGI2000/rawdata_v2/L01_clear
# perl heart_p_location.pl  --heart all_HD_heart_gene_p.txt --outdir hd -vcf_txt  /home/fuzl/project/huada_MGI2000/rawdata_v2/L01_clear
根据txt文件'-heart' ,三列sample,gene,p点，提取注释后txt文件对应的点，txt中样本名要与-vcf_txt 中路径名中一致
\n!
)
}
