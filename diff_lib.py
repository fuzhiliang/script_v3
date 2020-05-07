#!/usr/bin/env python3
#coding=utf-8
""" Command line interface to difflib.py providing diffs in four formats:

* ndiff:    lists every line and highlights interline changes.
* context:  highlights clusters of changes in a before/after format.
* unified:  highlights clusters of changes in an inline format.
* html:     generates side by side comparison with change highlights.

"""

import sys, os, difflib, argparse
import smtplib
from email.mime.text import MIMEText
from email.header import Header
#from smtplib import SMTP_SSL

from datetime import datetime, timezone

def file_mtime(path):
    t = datetime.fromtimestamp(os.stat(path).st_mtime,
                               timezone.utc)
    return t.astimezone().isoformat()

def mail(diff,fromfile,tofile):
    #邮箱smtp服务器
    host_server = 'mail.berryoncology.com'
    #发件人的邮箱
    sender_mail = 'fuzhl4317@berryoncology.com'
    #收件人邮箱
    receiver = 'fuzhl4317@berryoncology.com'

    #邮件的正文内容
    #mail_content = "你好，<p>这是使用python登录qq邮箱发送HTML格式邮件的测试：</p><p><a href='http://www.yiibai.com'>易百教程</a></p>"
    #mail_content ="您好，<p>项目%s的阳性参考品与数据库%s结果不一致，请检查：</p>" %(fromfile,tofile)
    mail_content ="您好，<p>文件%s与%s对比结果：</p>" %(fromfile,tofile)
    mail_content+=diff
    #邮件标题
    mail_title = 'Maxsu的邮件'


    #ssl登录
    #smtp = SMTP_SSL(host_server)
    #set_debuglevel()是用来调试的。参数值为1表示开启调试模式，参数值为0关闭调试模式
    #smtp.set_debuglevel(1)
    #smtp.ehlo(host_server)
    #smtp.login(sender, pwd)

    msg = MIMEText(mail_content, "html", 'utf-8')
    msg["Subject"] = Header(mail_title, 'utf-8')
    msg["From"] = sender_mail
    msg["To"] = Header("接收者测试", 'utf-8') ## 接收者的别名

    smtp= smtplib.SMTP(host_server)
    smtp.sendmail(sender_mail, receiver, msg.as_string())
    smtp.quit()

def main():

    parser = argparse.ArgumentParser()
    parser.add_argument('-c', action='store_true', default=False,
                        help='Produce a context format diff (default) 是否只显示有差异行[否]')
    parser.add_argument('-u', action='store_true', default=False,
                        help='Produce a unified format diff 输出标准diff格式')
    parser.add_argument('-m', action='store_true', default=False,
                        help='Produce HTML side by side diff 生成html格式'
                             '(can use -c and -l in conjunction)')
    parser.add_argument('-n', action='store_true', default=False,
                        help='Produce a ndiff format diff 会标注差异位置')
    parser.add_argument('-l', '--lines', type=int, default=3,
                        help='Set number of context lines (default 3) 设置显示差异的上下文行数')
    parser.add_argument('-ma', '--mail', type=int, default=False,
                        help='mail different html 设置显示差异的上下文行数')
    parser.add_argument('fromfile')
    parser.add_argument('tofile')
    options = parser.parse_args()

    n = options.lines
    fromfile = options.fromfile
    tofile = options.tofile

    fromdate = file_mtime(fromfile)
    todate = file_mtime(tofile)
    with open(fromfile) as ff:
        fromlines = ff.readlines()
    with open(tofile) as tf:
        tolines = tf.readlines()

    if options.u: 
        diff = difflib.unified_diff(fromlines, tolines, fromfile, tofile, fromdate, todate, n=n)
    elif options.n:
        diff = difflib.ndiff(fromlines, tolines)
    elif options.m:
        diff = difflib.HtmlDiff().make_file(fromlines,tolines,fromfile,tofile,context=options.c,numlines=n)
    else:
        diff = difflib.context_diff(fromlines, tolines, fromfile, tofile, fromdate, todate, n=n)

    if options.ma and options.m:
        mail(diff,fromfile,tofile)

    sys.stdout.writelines(diff)


if __name__ == '__main__':
    main()