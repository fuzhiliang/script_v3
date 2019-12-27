#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use Cwd;

my $pwd = getcwd();

my($qsub_opt,@allJobs,$qsubDir,$shell);

use vars qw($opt_d $opt_l $opt_q $opt_N $opt_P $opt_n $opt_b $opt_m $opt_s $opt_r $opt_h);
getopts("d:l:q:N:P:n:b:m:s:r:h");

if($opt_h or @ARGV == 0){
    &usage();
    exit;
}

# 生成目录$qsubDir, 用于存放任务输出信息等
$shell = shift;

my $shell_name = (split /\//,$shell)[-1];
$qsubDir = $opt_d || (split /\//,$shell)[-1]."_qsub";
`rm -rf $qsubDir` if(-e $qsubDir);
`mkdir $qsubDir`;
`rm $shell.log` if(-e "$shell.log");
`rm $shell.error` if(-e "$shell.error");
`rm $shell.finished` if(-e "$shell.finished");

$opt_q||="all.q";
# 根据参数生成投递任务命令
$opt_l = $opt_l || "vf=1G";
$qsub_opt = "qsub -cwd -S /bin/bash -l $opt_l ";
$qsub_opt .= "-q $opt_q " if($opt_q);
$qsub_opt .= "-P $opt_P " if($opt_P);
$qsub_opt .= "-l h=$opt_n" if($opt_n);
$opt_N = $opt_N || "work";

# 默认每个sh文本放1个命令, 最大同时任务30
# 每隔120秒扫描任务状态, 最大尝试投递次数1
my $lines = $opt_b || 1;
my $maxJob = $opt_m || 30;
my $sleepTime = $opt_s || 120;
my $max_try = 2;
$max_try = 3 if(!$opt_r);
#all.q\@sge_c17
# 根据$shell文档生成并行运行的命令文档
my $split_number;
open IS,$shell or die "can\'t open shell.sh: $shell\n";
while(<IS>){
    chomp;
    next if (/^\s*$/);
    $split_number++;
    my $num = 1;
    open OUTS,">$qsubDir/$opt_N\_$split_number.sh" or die "can\'t open split shell: $qsubDir/$opt_N\_$split_number.sh\n";
    print OUTS $_;
    while($num < $lines){
        $num++;
        last if(eof(IS));
        chomp(my $command = <IS>);
        print OUTS "\n$command";
    }
    print OUTS "\n echo this-work-is-complete\n";
    close OUTS;
    push @allJobs,"$qsubDir/$opt_N\_$split_number.sh";
}
close IS;

&qsub_and_wait();

# 如果最大允许同时投递任务数目$maxJob小于总投递任务$split_number, 则投递$maxJob个任务, 不然投递$split_number个
# 每隔$sleepTime时间查看任务状态, 如果在跑任务数目小于$sub_num, 则继续投递任务
# 将所有任务的运行结果写入$shell.log
sub qsub_and_wait{
    chomp(my $user = `whoami`);

    my(%runJob,%error,@wait);
    my $sub_num = $maxJob > $split_number ? $split_number : $maxJob;
    @wait = (1..$split_number);

    my $qnum = 0;
    while(@wait and $qnum < $sub_num){
        my $i = shift @wait;
        print "$qsub_opt -o $qsubDir/$opt_N\_$i.sh.o -e $qsubDir/$opt_N\_$i.sh.e -N $opt_N\_$i\_$shell_name $qsubDir/$opt_N\_$i.sh\n";
        chomp(my $qmess = `$qsub_opt -o $qsubDir/$opt_N\_$i.sh.o -e $qsubDir/$opt_N\_$i.sh.e -N $opt_N\_$i\_$shell_name $qsubDir/$opt_N\_$i.sh`);
        if($qmess =~ /^[Yy]our\sjob\s(\d+)\s\(\".*\"\)\shas\sbeen\ssubmitted.?$/){
            $runJob{$1} = "$qsubDir/$opt_N\_$i.sh";
            $qnum++;
        }else{
            unshift @wait,$i;
        }
    }

    while(@wait or keys %runJob){
        sleep($sleepTime);
        &check_job($user,\%error,\@wait,\%runJob);
        $qnum = keys %runJob;
        while(@wait and $qnum < $sub_num){
            my $i = shift @wait;
            print "$qsub_opt -o $qsubDir/$opt_N\_$i.sh.o -e $qsubDir/$opt_N\_$i.sh.e -N $opt_N\_$i\_$shell_name $qsubDir/$opt_N\_$i.sh\n";
            chomp(my $qmess = `$qsub_opt -o $qsubDir/$opt_N\_$i.sh.o -e $qsubDir/$opt_N\_$i.sh.e -N $opt_N\_$i\_$shell_name $qsubDir/$opt_N\_$i.sh`);
            if($qmess =~ /^[Yy]our\sjob\s(\d+)\s\(\".*\"\)\shas\sbeen\ssubmitted.?$/){
                $runJob{$1} = "$qsubDir/$opt_N\_$i.sh";
                $qnum++;
            }else{
                unshift @wait,$i;
            }
        }
    }

    open OUTL,">>$shell.log" or die "can\'t open shell.log\n";
    if(keys %error){
        print OUTL "There are some job can't run finish, check the shell and qsub again\n";
        for(sort {$a cmp $b} keys %error){
            print OUTL "$_\n";
        }
    }else{
        print OUTL "All jobs are finished correctly\n";
    }
    close OUTL;
}

# 检查投递任务的状态, 运行qstat -xml -u $userName, 获得当前并行任务的ID, 名字, 状态, 队列
# 如果状态为Eqw,T,跑的节点是dead状态, 则撤销这个任务, 如果错误次数少于最大限度, 则重新投递
# 对于已经停止的任务, 如果是完成了, 则从正在跑的任务名单剔除, 不然且在错误次数少于最大限度时,重新加入等待名单
sub check_job{
    my($userName,$error,$wait,$run) = @_;
    my %dead;
    &dead_nodes(\%dead);
    my %running;
    my $qsub_stat = `qstat -xml -u $userName`;
    while($qsub_stat =~ /<JB_job_number>(\d+?)<\/JB_job_number>.*?
            <JB_name>(.+?)<\/JB_name>.*?
            <state>(.+?)<\/state>.*?
            <queue_name>(.*?)<\/queue_name>
            /gxs){
        my ($jbnum, $jbname, $jbstat, $jbqueue) = ($1, $2, $3, $4);
        if($jbname =~ /$opt_N\_(\d+)/){
            my $num = $1;
            my $split_shell = $$run{$jbnum};
            if($jbstat eq "Eqw" or $jbstat eq "T" or ($jbqueue =~ /^.+@(.+)\.local$/ and exists $dead{$1})){
                $$error{$split_shell}++;
                `qdel $jbnum`;
                `echo $split_shell has not finished! >>$shell.error`;
                if($$error{$split_shell} < $max_try){
                    `rm $split_shell.[oe]`;
                    unshift @$wait,$num;
                    `echo $split_shell has been reqsub >>$shell.error`;
                }
                delete $$run{$jbnum};
            }
            $running{$jbnum} = undef;
        }
    }

    foreach my $id (sort {$a <=> $b} keys %$run){
        my $split_shell = $$run{$id};
        if(!exists $running{$id}){
            delete $$run{$id};
            chomp(my $log = `tail -1 $split_shell.o`);
            if($log eq "this-work-is-complete"){
                delete($$error{$split_shell});
                `echo $split_shell is finished! >> $shell.finished`;
            }else{
                `echo $split_shell has not finished! >>$shell.error`;
                $$error{$split_shell}++;
                if($$error{$split_shell} < $max_try){
                    `rm $split_shell.[oe]`;
                    my $num = $1 if($split_shell =~ /$opt_N\_(\d+)\.sh/);
                    unshift @$wait,$num;
                    `echo $split_shell has been reqsub >>$shell.error`;
                }
            }
        }
    }
}

# 运行qhost命令, 如果某个节点的LOAD  MEMUSE  SWAPUS MEMTOT SWAPTO其中一个为-, 则将这个节点设置为undef
sub dead_nodes{
    my $dead = shift;
    chomp(my @nodeMess = `qhost`);
    shift @nodeMess for(1..3);
    foreach(@nodeMess){
        my @temp = split;
        my $node_name = $temp[0];
        $dead->{$node_name} = undef if($temp[3]=~/-/ || $temp[5]=~/-/ || $temp[7]=~/-/ || $temp[4]=~/-/ || $temp[6]=~/-/);
    }
}

# 输出帮助信息
sub usage{
    print <<EOD;
usage: perl $0 [options] shell.sh
    Options:
        -d  qsub script and log dir, default ./shell.sh_qsub/  # 生成这个目录, 保存拆分的小任务以及任务的输出信息等
        -l  the qsub -l option argument: vf=xxG[,p=xx,...] (default vf=1G)  # qsub的-l参数的内存,cpu部分, 输入形式为vf=xxG[,p=xx,...]
        -q  queue list, default all availabile queues  # qsub的-q参数, 指定任务的投递节点
        -N  set the prefix tag for qsubed jobs, default work  # 指定拆分后小任务的前缀
        -P  project_name, default not  # qsub的-P参数, 指定任务的项目名
        -n  compute node, default all availabile nodes  # qsub的-l参数的节点部分
        -b  set number of lines to form a job, default 1  # 指定每个拆分后sh文档有几个小任务
        -m  set the maximum number of jobs to throw out, default 30  # 指定可同时提交任务的最大数目
        -s  set interval time of checking by qstat, default 120 seconds  # 指定每隔多长时间检查任务的状态
        -r  mark to reqsub the job which was finished error, max reqsub 10 times, default not  # # 指定每个sh任务可错投递次数
        -h  show this help  # 显示帮助信息
EOD
}
