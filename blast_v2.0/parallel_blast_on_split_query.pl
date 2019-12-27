#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET=1;
my $BEGIN_TIME=time();
my $version="1.0.0";
#######################################################################################
#
#######################################################################################
# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($query_file, $database_file, $index, $odir, $cutnum, $evalue, $xml, $notab, $verbose,$identity,$short);

GetOptions(
    "help|?"    => \&USAGE,
    "query=s"   => \$query_file,
    "database=s"=> \$database_file,
    "index=s"   => \$index,
    "odir=s"    => \$odir,
    "cutnum=i"  => \$cutnum,
    "evalue=f"  => \$evalue,
    "qcov=i"    => \$identity,
    "xml"       => \$xml,
    "notab"     => \$notab,
    "short" 	=> \$short,
    "verbose"   => \$verbose,
    ) or &USAGE;
#&USAGE unless ($query_file and $database_file);
&USAGE unless ($query_file);

# ------------------------------------------------------------------
# init 
# ------------------------------------------------------------------
$index  ||= basename($query_file);
$odir   ||= './';
$cutnum ||= 200;
$evalue ||= 1e-5;
$database_file ||= "/home/fuzl/soft/ncbi-blast-2.8.1+/database/nr.gz";
$identity ||= 80;

system "mkdir -p $odir" unless (-d $odir);
$query_file    = &ABSOLUTE_DIR($query_file);
$database_file = &ABSOLUTE_DIR($database_file);
$odir          = &ABSOLUTE_DIR($odir);
#$index =~s/\.fa(sta)?$//i;
my $work_sh = "$odir/work_sh";
system "mkdir -p $work_sh" unless (-d $work_sh);

# utils 
my $blastall = "/home/fuzl/soft/ncbi-blast-2.8.1+/bin"; 
my $formatdb = "$blastall/makeblastdb"; 
my $merge_blast_xml = "$Bin/merge_blast_xml.py";   
my $blast_parser = "$Bin/blast_parser.pl"; 
my $blast_fasta = "$Bin/blast_fasta.pl";
my $cmd;

&log_current_time("$Script start...");
# ------------------------------------------------------------------
# split query file and formatdb if needed
# ------------------------------------------------------------------
my $program;
my $blastdb;
my $query_biotype = fasta_format_check($query_file);
my $sbjct_biotype = fasta_format_check($database_file);

# make sure the BLAST program to be used 

if ($query_biotype eq 'nucleotide' && $sbjct_biotype eq 'aminoacide') {
    $program = 'blastx';
    $blastdb = "$database_file.psq";
} elsif ($query_biotype eq 'aminoacide' && $sbjct_biotype eq 'aminoacide') {
    $program = 'blastp';
    $blastdb = (glob "$database_file*.psq")[0];
} elsif ($query_biotype eq 'nucleotide' && $sbjct_biotype eq 'nucleotide') {
    $program = 'blastn';
    $blastdb = (glob "$database_file*.nsq")[0];
} elsif ($query_biotype eq 'aminoacide' && $sbjct_biotype eq 'nucleotide') {
    $program = 'tblastn';
    $blastdb = (glob "$database_file*.nsq")[0];
} else {
    print STDERR "Your inputfile is not a fasta file. Please use fasta format file!";
    exit;
    #die "ERROR: only suit for BLAST program blastx, blastp or blastn!\n";
}
#close OUTERR;

# add dir into program
#$program = "$blastall/$program";

# formatdb if needed 
if (not defined $blastdb or (defined $blastdb && !-f $blastdb)) {
    mkdir "$odir/blastdb" unless (-d "$odir/blastdb");
    $cmd = "cd $odir/blastdb/ && ln -s $database_file ./ && sed -i \'s/\\t/ /g\' ".basename($database_file)." && " unless (-s "$odir/blastdb/".basename($database_file));
    $database_file = "$odir/blastdb/".basename($database_file);

    # nt or pep 
    if ($sbjct_biotype eq 'aminoacide') {
        #$cmd.= "$formatdb -i $database_file -p T ";
        $cmd.= "$formatdb -parse_seqids -in $database_file -dbtype prot >formatdb.log 2>&1 ";
        $blastdb = (glob $database_file.'*.psq')[0];
    } elsif ($sbjct_biotype eq 'nucleotide') {
        #$cmd.= "$formatdb -i $database_file -p F ";
        $cmd.= "$formatdb -parse_seqids -in $database_file -dbtype nucl >formatdb.log 2>&1 ";
        $blastdb = (glob $database_file.'*.nsq')[0];
    }

    &run_or_die($cmd) if (not defined $blastdb or (defined $blastdb && !-f $blastdb));
}

# split query file
my %query;
my $query_dir = "$odir/query_dir";
mkdir $query_dir unless (-d $query_dir);

&load_fasta($query_file,\%query);
&cut_fasta(\%query, $query_dir, $cutnum, $index);

# ------------------------------------------------------------------
# BLAST 
# ------------------------------------------------------------------
# blast 
my $blast_shell_file = "$work_sh/$index.blast.sh";
my @subfiles = glob "$query_dir/$index*.fa";
mkdir "$odir/aln_subdir/" unless (-d "$odir/aln_subdir/");

# creat shell file
open OUT,">$blast_shell_file" or die $!;
$cmd="";
foreach my $subfile (@subfiles) {
    my $name = basename($subfile);
    if ($xml) {
        if ($program eq 'blastn') {
            $cmd.="$blastall/$program -num_alignments 50 -evalue $evalue -qcov_hsp_perc $identity -db $database_file -query $subfile -outfmt 5 -num_threads 2 -out $odir/aln_subdir/$name.blast.xml ";
            $cmd.=" -task blastn-short " if (defined $short);
            $cmd.=" \n";
        } else {
            $cmd.= "$blastall/$program -task ${program}-fast -max_target_seqs 50 -evalue $evalue -db $database_file -query $subfile -outfmt 5 -num_threads 4 -out $odir/aln_subdir/$name.blast.xml \n";
        }
    } else {
        if ($program eq 'blastn') {
            $cmd.= "$blastall/$program -num_descriptions 50 -num_alignments 50 -evalue $evalue -qcov_hsp_perc $identity -db $database_file -query $subfile -outfmt 0 -num_threads 2 -out $odir/aln_subdir/$name.blast ";
            $cmd.= " -task blastn-short " if (defined $short);
            $cmd.= " \n";
    } else {
            $cmd.= "$blastall/$program -task ${program}-fast -num_descriptions 50 -num_alignments 50 -evalue $evalue -qcov_hsp_perc $identity -db $database_file -query $subfile -outfmt 0 -num_threads 2 -out $odir/aln_subdir/$name.blast \n";
        }

    }
}
print OUT "$cmd";
close OUT;

#run the shell file
if (@subfiles>4) {
    &Cut_shell_qsub("$blast_shell_file",20,"6G","general.q");
} else {
    open (SH,"$blast_shell_file") or die $!;
    while (<SH>) {
        chomp;
        s/\s*\&\&\s*$//;
        &run_or_die($_);
    }
    close SH;
}

# ------------------------------------------------------------------
# merge BLAST result 
# parse the BLAST result and convert to tabular format 
# ------------------------------------------------------------------

if ($xml) {
    my @xml_file = glob "$odir/aln_subdir/*.blast.xml";

    if (@xml_file == 1) {
        $cmd = "cp -rf $xml_file[0] $odir/$index.blast.xml ";
    } else {
        $cmd = "python $merge_blast_xml $odir/$index.blast.xml $odir/aln_subdir/*.blast.xml ";
    }
} else {
    $cmd = "cat $odir/aln_subdir/*.blast > $odir/$index.blast ";
}

&run_or_die($cmd);

# ------------------------------------------------------------------
# convert alignment result to tabular format
# ------------------------------------------------------------------
# convert to tabular format
if ($xml) {
    $cmd = "perl $blast_parser -eval $evalue -tophit 1 -m 7 -topmatch 1 $odir/$index.blast.xml > $odir/$index.blast.tab.best && ";
    $cmd.= "perl $blast_parser -eval $evalue -tophit 50 -m 7 -topmatch 1 $odir/$index.blast.xml > $odir/$index.blast.tab ";
} else {
    $cmd = "perl $blast_parser -eval $evalue -tophit 1 -m 0 -topmatch 1 $odir/$index.blast > $odir/$index.blast.tab.best && ";
    $cmd.= "perl $blast_parser -eval $evalue -tophit 50 -m 0 -topmatch 1 $odir/$index.blast > $odir/$index.blast.tab ";
}

&run_or_die($cmd) unless ($notab);

if (-f "$odir/$index.blast.tab.best") {
    # create query and subject id list 
    &run_or_die("cut -f1 $odir/$index.blast.tab.best |sed '1d' | sort | uniq > $odir/$index.query.id.list");
    &run_or_die("cut -f5 $odir/$index.blast.tab.best |sed '1d' | sort | uniq > $odir/$index.subject.id.list");
    # abstract query and subject sequence
    &run_or_die("perl $Bin/abstractFabyId.pl -l $odir/$index.query.id.list -f $query_file -o $odir/$index.query.fa");
    &run_or_die("perl $Bin/abstractFabyId.pl -l $odir/$index.subject.id.list -f $database_file -o $odir/$index.subject.fa");
    
    &run_or_die("cat $odir/$index.query.fa $odir/$index.subject.fa > $odir/$index.queryNsubject.fa") if ($query_biotype eq $sbjct_biotype);
}

# remove intermediate file 
unless ($verbose) {
    system "rm -r $query_dir "; #$odir/aln_subdir ";
    system "rm -fr $odir/blastdb " if (-d "$odir/blastdb");
}

#`cp $Bin/readme.txt $odir`;
#######################################################################################
my $elapse_time = (time()-$BEGIN_TIME)."s";
&log_current_time("$Script done. Total elapsed time: $elapse_time.");
#######################################################################################
# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
#############################################################################################################
sub ABSOLUTE_DIR{ #$pavfile=&ABSOLUTE_DIR($pavfile);
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir\n";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

#############################################################################################################
sub load_fasta {
    &log_current_time("load FASTA file.");
    my ($fa,$info) = @_;

    open IN,"$fa" || die $!;
    $/='>';
    while (<IN>) {
        chomp;
        s/^\s+//;s/\s+$//;s/\r+$//;
        next if (/^$/ || /^\#/);
        my ($head,$seq)=split/\n+/,$_,2;
        my $id=(split/\s+/,$head)[0];
        $info->{$id}=$seq;
    }
    $/="\n";
    close IN;
}

#############################################################################################################
sub cut_fasta {
    &log_current_time("cut query sequence.");
    my ($fa,$od,$cut,$name) = @_;
    my %seq=%$fa;
    my @aa=sort(keys %seq);
    my $index=0;
    my $filenum = int(@aa/$cut) + 1;
    my $decimals=int(log($filenum)/log(10))+1;

    LAB: for (my $i=1;;) {
        my $num=0;
        $i=sprintf "%0${decimals}d",$i;
        open OUT,">$od/$name.$i.fa" || die $!;
        for ($index..$#aa) {
            $index++;
            if ($num<$cut) {
                print OUT ">$aa[$_]\n$seq{$aa[$_]}\n";
                $num++;
            }
            if ($num>=$cut) {
                $num=0;
                $i++;
                close OUT;
                if ($index==$#aa+1) {
                    last;
                } else {
                    next LAB;
                }
            }
        }

        close OUT if ($num);
        last;
    }
}

#############################################################################################################
sub Cut_shell_qsub {#Cut shell for qsub 1000 line one file
    # &Cut_shell_qsub($shell,$cpu,$vf,$queue);
    my $shell = shift;
    my $cpu = shift;
    my $vf = shift;
    my $queue = shift;
    my $line = system "wc -l $shell";
    `sh /home/fuzl/script/shell.sh $shell $cpu`;

=c
    my $notename=`hostname`;chomp $notename;

    if ($line<=1000) {
        if ($notename=~/cluster/) {
            system "perl $qsub_sge --queue $queue --maxproc $cpu --resource vf=$vf --independent --reqsub $shell ";
        } else {
            system "ssh cluster perl $qsub_sge --queue $queue --maxproc $cpu --resource vf=$vf --independent --reqsub $shell ";
        }
    } else {
        my @div = glob "$shell.div*";
        foreach (@div) {
            system "rm $_" if (-e $_);
        }
        my $div_index=1;
        my $line_num=0;

        open IN,"$shell" or die $!;
        while (<IN>) {
            chomp;
            open OUT,">>$shell.div.$div_index" or die $!;

            if ($line_num<1000) {
                print OUT "$_\n";
                $line_num++;
            } else {
                print OUT "$_\n";
                $div_index++;
                $line_num=0;
                close OUT;
            }
        }
        close OUT if ($line_num!=0);

        @div=glob "$shell.div*";
        foreach my $div_file (@div) {
            if ($notename=~/cluster/) {
                system "perl $qsub_sge --queue $queue --maxproc $cpu --resource vf=$vf --reqsub $div_file ";
            } else {
                system "ssh cluster perl $qsub_sge --queue $queue --maxproc $cpu --resource vf=$vf --reqsub $div_file ";
            }
        }
    }

=cut
}

#############################################################################################################
#&run_or_die($cmd);
sub run_or_die() {
    my ($cmd) = @_ ;
    &log_current_time($cmd);
    my $flag = system($cmd);
#    my $flag = 0;

    if ($flag){
        &log_current_time("Error: command fail: $cmd");
        exit(1);
    }
}

#############################################################################################################
sub fasta_format_check {
    my $file = shift;
    my $context = `grep -v "\^#" $file|head -n 2 `; chomp $context;
    my ($id, $seq) = (split /\n/,$context);
    $seq =~ s/\r//g;
    my $biotype;

    if ($id=~/^>/) {
        $biotype = ($seq =~/([^ATCGUN])/i) ? 'aminoacide' : 'nucleotide'; # error when nucleotide with degeneracy 
    } else {
        print STDERR "ERROR: this may be not a FASTA format file,please check $file!\n";
        die "ERROR: this may be not a FASTA format file, please check $file !\n";
    }

    return $biotype;
}

#############################################################################################################
sub log_current_time {
     # get parameter
     my ($info) = @_;

     # get current time with string
     my $curr_time = date_time_format(localtime(time()));

     # print info with time
     print "[$curr_time] $info\n";
}

#############################################################################################################
sub date_time_format {
    my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
    return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

#############################################################################################################
sub USAGE {
	my $usage = <<"USAGE";
 ProgramName: $Script
     Version: $version
     Contact: Evan.Fu <fuzl\@geneis.com.cn> 
Program Date: 2018-08-08
      Modify: 
 Description: This script is used to BLAST on split query parallelly. Only suit for BLAST program blastx, blastp, blastn or tblastn.
              
       Usage: 
        Options:
        --query     <FILE>  query file, FASTA format, nucleotide or amino acid sequence, required
        --database  <FILE>  database file, FASTA format, nucleotide or amino acid sequence, required

        --index     <STR>   prefix of output files, optional, default basename of query file
        --odir      <DIR>   output directory, optional                                                  [./]
        --cutnum    <INT>   queried sequence number per splited single file                             [200]
        --evalue    <FLOAT> expectation value, optional                                                 [1e-5]
        --qcov 	    <FLOAT> percent query coverage per hsp                                              [80]
        --xml               report BLAST alignment result as XML format, default BLAST standard format
        --notab             not convert alignment result to tabular format
        --verb              verbose, save intermediate result
        --short             short sequence aligement 
        Examples:
            perl $Script --query Maize.Known.longest_transcript.fa --database protein.sequences.v10.fa 
            perl $Script --query Bee.Unigene.fa --database protein.sequences.v10.fa --odir PPI/align_STRING --cutnum 100 --evalue 1e-10

USAGE
	print $usage;
	exit;
}


