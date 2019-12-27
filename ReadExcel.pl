#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Encode;
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel; 
use Text::Iconv;
use Spreadsheet::XLSX; 
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $converter = Text::Iconv -> new ("utf-8", "windows-1251");
my $BEGIN_TIME=time();
my $version="1.0.0";


#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($fIn,$key,$od);
GetOptions(
				"help|?" =>\&USAGE,
				"i:s"=>\$fIn,
				"od:s"=>\$od,
				) or &USAGE;
&USAGE unless ($fIn and $od);
mkdir $od unless -d $od;
$fIn = ABSOLUTE_DIR($fIn);
$od = ABSOLUTE_DIR($od);

my $basename = basename($fIn);
my @type = split/\./,$basename;
my $type = pop (@type);
if ($type eq "xls") {
	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse("$fIn");
	if ( !defined $workbook ) {
		#goto &no_parse($fIn);
		&NOPARSE($fIn);
		#die $parser->error(), ".\n";
	}

	for my $worksheet ( $workbook->worksheets() ) {
		my $True_sheet = $worksheet->get_name();
#	    print $True_sheet,"\n";die;
		open (OUT,">$od/$True_sheet") or die $!;
		my $Val;
		my ( $row_min, $row_max ) = $worksheet->row_range();
		my ( $col_min, $col_max ) = $worksheet->col_range();
        next if ($col_max <0 || $row_max <0);   # next when this sheet is empty. by fuzl at 2016-03-02

		for my $row ( $row_min .. $row_max ) {
			for my $col ( $col_min .. $col_max ) {
				my $cell = $worksheet->get_cell( $row, $col );
				next unless $cell;
				$Val.=$cell->value()."\t";
			}
			$Val=~s/\t$/\n/;
		}
		print OUT $Val;
		close OUT;
		system "rm $od/$True_sheet" unless (-s "$od/$True_sheet");
	}
}elsif ($type eq "xlsx") {
	my $excel = Spreadsheet::XLSX -> new("$fIn",$converter);
	if ( !defined $excel ) {
		#goto &no_parse($fIn);
		&NOPARSE($fIn);
		#print "Check your excel\n";die;
	}
	for my $worksheet ( @{$excel->{Worksheet}} ) {
		my $True_sheet = $worksheet->{Name};
		my $Val;
        next if ($worksheet->{MaxRow} ==0 && $worksheet->{MaxCol} ==0);   # next when this sheet is empty. by fuzl at 2016-03-02
		$worksheet->{MaxRow} ||= $worksheet->{MinRow};
	#	print "$worksheet->{MaxRow}\n$worksheet->{MinRow}\n";die;
		for my $row ( $worksheet->{MinRow} .. $worksheet->{MaxRow} ) {
			$worksheet->{MaxCol} ||= $worksheet->{MinCol};
			for my $col ( $worksheet->{MinCol} .. $worksheet->{MaxCol} ) {
				my $cell = $worksheet->{Cells}[$row][$col];
				next unless $cell;
				$Val.=$cell->{Val}."\t";
			}
			$Val=~s/\t$/\n/;
		}
		open (OUT,">$od/$True_sheet") or die $!;
		print OUT $Val;
		close OUT;
		system "rm $od/$True_sheet" unless (-s "$od/$True_sheet");
	}
}else {&USAGE;}
`sed -ri 's/\\s\+\$//g' $od/*`;
#`cp $Bin/readme.txt $od`;


sub NOPARSE {
    # convert \s+ to \t globle 
    # rename file 
    # goto &no_parse($fIn);
    my $new_path = "$od/$basename";
    $new_path =~s/xls(x)?$/txt/i;
    `sed -r 's/\\r/\\n/g' $fIn > $new_path`;
    `sed -ri 's/\\s\+/\\t/g' $new_path`;
#    `cp -f $Bin/readme.txt $od`;
    exit (0);
}


#######################################################################################
#print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
################################################################################################################

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

################################################################################################################

sub max{#&max(lists or arry);
	#求列表中的最大值
	my $max=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$max=$max>$temp?$max:$temp;
	}
	return $max;
}

################################################################################################################

sub min{#&min(lists or arry);
	#求列表中的最小值
	my $min=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$min=$min<$temp?$min:$temp;
	}
	return $min;
}

################################################################################################################

sub revcom(){#&revcom($ref_seq);
	#获取字符串序列的反向互补序列，以字符串形式返回。ATTCCC->GGGAAT
	my $seq=shift;
	$seq=~tr/ATCGatcg/TAGCtagc/;
	$seq=reverse $seq;
	return uc $seq;			  
}

################################################################################################################

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}


sub USAGE {#
	my $usage=<<"USAGE";
ProgramName:
Version:	$version
Contact:	Evan.Fu <fuzl\@geneis.cn> 
Program Date:   2019.01.26
Usage:
  Options:
  -i   <file>  input Excel file,forced 

  -od   <dir>  output dir,forced
  
  -h         Help

USAGE
	print $usage;
	exit;
}
