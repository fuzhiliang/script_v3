#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin '$Bin';
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use File::Path qw( mkpath );
use Mail::Sender;
use Encode;
use lib $Bin;

my ($attachment , $help);
GetOptions(
	"a|attachment=s"	=>	\$attachment,
	"help"	=>	\$help,
);
my $user=$ENV{'USER'};

#my $mail_list = 'wangluxi746@berrygenomics.com,ybshi@berrygenomics.com,wangzhiqiong915@berrygenomics.com,zoujianing911@berrygenomics.com,yujun001@berrygenomics.com,baijian488@berrygenomics.com,wangruiru153@berrygenomics.com,chenxiaoyan712@berrygenomics.com';
#my $mail_list = 'wangluxi746@berryoncology.com,ybshi@berryoncology.com,yujun001@berryoncology.com,zoujianing911@berryoncology.com,wangzhiqiong915@berryoncology.com,baijian488@berryoncology.com,wangruiru153@berryoncology.com,chenxiaoyan712@berryoncology.com';
#my $mail_list = 'donghansheng041@berryoncology.com,ybshi@berryoncology.com,yujun001@berryoncology.com,baijian488@berryoncology.com,wangruiru153@berryoncology.com,chenxiaoyan712@berryoncology.com,wangluxi746@berryoncology.com,zhangwj3075@berryoncology.com,oncology_labreport@berryoncology.com,dingj3639@berryoncology.com'; #donghansheng 20181126
#my $mail_list = 'donghansheng041@berryoncology.com';
#my $mail_list = "$user\@berryoncology.com";
#$mail_list .= ',liuw4318@berryoncology.com';
my $mail_list = 'donghansheng041@berryoncology.com,wun3623@berryoncology.com,yangrutao796@berryoncology.com,wangzhenbo637@berryoncology.com,xingh3223@berryoncology.com,xufl3252@berryoncology.com,wujq3870@berryoncology.com,wangzx3872@berryoncology.com,jiangdzh3403@berryoncology.com,liuw4318@berryoncology.com,tiany4342@berryoncology.com,fuzhl4317@berryoncology.com';
#$mail_list = "$user\@berryoncology.com";
print "mail to:\n $mail_list\n";
if ($help){
	&help;
	exit;
}

my $sender=Mail::Sender->new({
    smtp =>'mail.berryoncology.com',
    #from =>'chenxiaoyan712@berryoncology.com',
    from =>'fuzhl4317@berryoncology.com', #donghansheng 20181126
    auth =>'LOGIN',
    #authid =>'chenxiaoyan712@berryoncology.com',
    authid =>'fuzhl4317@berryoncology.com',
    #authpwd =>'Dong123456'   
    authpwd =>'Licaiqin66'		}
    #authpwd =>'berry2012'}
) or die "Can't send mail.\n";

#my $subject = encode('gb2312','标题');
my $msg = encode('GB2312','正文');

my $subject = basename($attachment);
$subject =~ s/\.Fail\.task\.xls$//;
#my $msg = 'This mail sent by automatic analysis pipeline. Please find the attachment report.';
#$ENV{'USER'}
$msg = "Hi $user:\n\tMaybe project failed due to an internal error. Please check the error log for details..\n$attachment\n";
$sender->MailFile({
    to	=>	$mail_list,
    subject	=>	"$subject result error log",
	charset	=>	"GB2312",
	file	=>	$attachment,
    msg	=> $msg
});

$sender->Close();
print "Mail sent!\n";

sub help{
print << "EOF!";
#===============================================================================
#
#         FILE: log_monit_mail_v1.pl
#
#        USAGE: ./log_monit_mail_v1.pl -a log
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Wang Ruiru (wangrr), wangruiru\@berrygenomics.com
# ORGANIZATION: Berry Genomics
#      VERSION: 1.0
#      CREATED: 11/21/17 15:19:27
#     REVISION: ---
#===============================================================================
EOF!
}



