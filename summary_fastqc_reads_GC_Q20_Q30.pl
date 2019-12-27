#!/usr/bin/perl -w
use Data::Dumper;
#
#opendir (DIR, "./lib-cfDNA-031-1_L4/FASTQC_trim/") or die "can't open the directory!";
#@dir = readdir DIR;
my @file=glob("./*/FASTQC_trim/*_1_paired_fastqc/fastqc_data.txt");
die "eq:\ncd /home/fuzl/project/boke519_test9sample && perl $0 " if @file==0;
print "Sample\tClearData\tGC%\tQ20\tQ30\n";
foreach $file ( sort  @file) {
    #next unless -d $file;
    #next if $file eq '.';
    #next if $file eq '..';
    $total_reads=  `grep '^Total' $file`;
    $total_reads=(split(/\s+/,$total_reads))[2]*2;
    $GC= `grep '%GC' $file`;
    $GC=(split(/\s+/,$GC))[1];
    $GC=~s/%//;
    chomp $GC;
    my $flag=0;
    open FH , "<$file";
    while (<FH>){
        chomp;
        next unless /#Quality/;
        while (<FH>){
            chomp;
            @F=split;
            $hash{'1'}{$F[0]}=$F[1];
            $flag=$F[0] if ($flag==0);
            last if />>END_MODULE/;
        }
    }
    $file=~s/_1_paired_fastqc/_2_paired_fastqc/;
#    print $file;
    my $GC2= `grep '%GC' $file`;
    $GC2=(split(/\s+/,$GC2))[1];
    $GC2=~s/\%//;
    chomp $GC2;
    $GC=($GC+$GC2)/2;
    open FH2 , "<$file";
    while (<FH2>){
        chomp;
        next unless /#Quality/;
        while (<FH2>){
            chomp;
            @F=split;
            $hash{'2'}{$F[0]}=$F[1];
            last if />>END_MODULE/;
            $flag=$F[0] if ($flag==0 || $F[0]<$flag);
        }
    }
    delete $hash{'1'}{">>END_MODULE"};
    delete $hash{'2'}{">>END_MODULE"};
#    print Dumper %hash;
    $all=0;$Q20=0;$Q30=0;
    foreach my $keys(keys %hash){
        foreach my $a (keys %{$hash{$keys}}){
            $all+=$hash{$keys}{$a};
            $Q20+=$hash{$keys}{$a} if($a<=20);
            $Q30+=$hash{$keys}{$a} if($a<=30) ;
        }
    }
    $Q20=1-$Q20/$all;
    $Q30=1-$Q30/$all;
    $file=~m/.*\/(.*)_2_paired_fastqc\/fastqc_data.txt/;
    print "$1\t$total_reads\t$GC%\t$Q20\t$Q30\n";
}
