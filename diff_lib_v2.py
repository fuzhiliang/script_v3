#!/usr/bin/env python3
#coding=utf-8
""" Command line interface to difflib.py providing diffs in four formats:

* ndiff:    lists every line and highlights interline changes.
* context:  highlights clusters of changes in a before/after format.
* unified:  highlights clusters of changes in an inline format.
* html:     generates side by side comparison with change highlights.
能对比两个excel
150个字符自动换行
"""

import sys, os, difflib, argparse
import smtplib,time
from email.mime.text import MIMEText
from email.header import Header
import pandas as pd
#from smtplib import SMTP_SSL

from datetime import datetime, timezone

def Split (excel,ori_tag,outdir):

    sheet_list = pd.read_excel(excel,sheet_name = None, index_col = 0 ,keep_default_na=False,
                               header = None)
    sep="\t"
    suffix=".txt"
    name=os.path.basename(excel)
    diff_file=os.path.join(outdir , ori_tag+"_"+name+suffix)

    if os.path.exists(outdir):
        if os.path.exists(diff_file):
            os.remove(diff_file)
    else:
        os.mkdir(outdir)
    for num in sheet_list:
        time.sleep(0.1)
        list=[[''],[num]]
        test=pd.DataFrame(list,index= ['','sheet:'] )
        test.to_csv(diff_file, mode='a',
                               encoding = 'utf-8',sep = sep,header = False )
        sheet_list[num].to_csv(diff_file, mode='a',
                               encoding = 'utf-8',sep = sep,header = False )
    return diff_file 

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
    receiver = ["fuzhl4317@berryoncology.com"]

    #邮件的正文内容
    #mail_content = "你好，<p>这是使用python登录qq邮箱发送HTML格式邮件的测试：</p><p><a href='http://www.yiibai.com'>易百教程</a></p>"
    #mail_content ="您好，<p>项目%s的阳性参考品与数据库%s结果不一致，请检查：</p>" %(fromfile,tofile)
    dir=os.path.dirname(os.path.abspath(fromfile))
    mail_content ="您好，<p> %s </p><p>文件 %s 与 %s 对比结果：</p>" %(dir,fromfile,tofile)
    mail_content+=diff
    #邮件标题
    mail_title = '两个文件对比的邮件'

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
    parser.add_argument('-mail', action='store_true', default=False,
                        help='mail different html 设置显示差异的上下文行数')
    parser.add_argument('fromfile')
    parser.add_argument('tofile')
    options = parser.parse_args()

    n = options.lines
    fromfile = options.fromfile
    tofile = options.tofile
    outdir=os.path.join(os.path.dirname(os.path.abspath(tofile)),"temp")

    fromdate = file_mtime(fromfile)
    todate = file_mtime(tofile)
    try:
        with open(fromfile) as ff:
            fromlines = ff.readlines()
        with open(tofile) as tf:
            tolines = tf.readlines()
    except:
        fromfile=Split(fromfile,"ori",outdir)
        tofile=Split(tofile,"tag",outdir)
        with open(fromfile) as ff:
            fromlines = ff.readlines()
        with open(tofile) as tf:
            tolines = tf.readlines()

    if options.u: 
        diff = difflib.unified_diff(fromlines, tolines, fromfile, tofile, fromdate, todate, n=n)
    elif options.n:
        diff = difflib.ndiff(fromlines, tolines)
    elif options.m:
        diff = difflib.HtmlDiff(wrapcolumn=150).make_file(fromlines,tolines,fromfile,tofile,context=options.c,numlines=n)
    else:
        diff = difflib.context_diff(fromlines, tolines, fromfile, tofile, fromdate, todate, n=n)

    if options.mail and options.m :
        mail(diff,fromfile,tofile)

    sys.stdout.writelines(diff)


if __name__ == '__main__':
    main()

