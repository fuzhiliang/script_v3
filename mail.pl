#!/usr/bin/perl
use MIME::Lite;
 
# 接收邮箱，这里我设置为我的 QQ 邮箱，你需要修改它为你自己的邮箱
$to = '594380908@qq.com';
# 抄送者，多个使用逗号隔开
# $cc = 'test1@runoob.com, test2@runoob.com';
 
#发送者邮箱
$from = '594380908@qq.com';
#标题
$subject = '菜鸟教程 Perl 发送邮件测试';
$message = '这是一封使用 Perl 发送的邮件，使用了 MIME::Lite 模块，包含了附件。';
 
$msg = MIME::Lite->new(
                 From     => $from,
                 To       => $to,
                 Cc       => $cc,
                 Subject  => $subject,
                 Type     => 'multipart/mixed'   # 附件标记
                 );
 
 
$msg->attach (
              Type => 'TEXT',
              Data => $message
);# 指定附件信息
$msg->attach(Type        => 'TEXT',
             Path        => './',   # 当前目录下
             Filename    => 'nohup.out',
             Disposition => 'attachment'
            );
$msg->send;
print "邮件发送成功\n";