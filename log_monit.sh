#!/bin/sh
DATE_DIR=$(date +%Y%m%d)
DATE=`date +%Y年%m月%d日%H时%M分%S秒`
HOST=`/bin/hostname`
IP=`/sbin/ifconfig|grep "inet addr"|grep "Bcast"|cut -d":" -f2|awk -F" " '{print $1}'`
log_dir=${pwd -P }/log

if [ ! -d $log_dir ];then
  echo "Error: Log directory does not exist!"
  exit 0
fi

cd $log_dir

if [ ! -d $log_dir/error_log ];then
  mkdir $log_dir/error_log
fi
error_flag="error|Traceback|'not exist'|'can’t find'|'Segmentation fault'|'command not found'"
echo "" >$log_dir/error_log/log_mail.list
FILE=(*_e[0-9]*.txt)
name=(${FILE[@]%_e[0-9]*.txt})



for FILE in $(ls *_e[0-9]*.txt)
do
  name=${FILE%%_e*.txt}
  NUM=$(grep -E -i $error_flag  $FILE|wc -l)
#   ERROR_MESSAGE=$(/bin/grep -E -i "error|Traceback" $FILE)
   if [ $NUM -ne 0 ];then
      cat $log_dir/error_log/${name}.runtimes 2>/dev/null
      b=$?
      if [ $b -ne 0 ];then  ## 第一次运行b=1
        echo "jobs第1次运行,无需报警！"
        touch $log_dir/error_log/${name}.runtimes
      else
        cp $log_dir/${name}_e*.txt $log_dir/error_log/
        error_num=$(/bin/grep -E -i "error|Traceback" $log_dir/${name}_e*.txt|wc -l)
        error_run_num=$(/bin/grep -E -i "error|Traceback" $log_dir/${name}_e*.txt |awk -F: '{print $1}'|sort |uniq|wc -l)
        error_tail=$(/bin/grep -E -i "error|Traceback" $log_dir/${name}_e*.txt |awk -F: '{print $1}'|tail -n 1 )
        if [ $error_run_num -gt 2 ];then
          grep -wq $name $log_dir/error_log/log_mail.list
          c=$?
          if [ $c -ne 0 ];then
            ERROR_MESSAGE=$(/bin/grep -E -i "error|Traceback" $error_tail)
            echo "$name第$error_run_num次运行报错，$error_run_num次运行总共出现$error_num次运行错误,发邮件
错误日志：
  $error_tail
错误信息：
  $ERROR_MESSAGE
"
            echo "$name">>$log_dir/error_log/log_mail.list
            #/opt/log_error_script/sendemail.sh wangshibo@test.com "大数据平台etl服务器${HOSTNAME}的SDB任务日志里出现error了" "告警主机：${HOSTNAME} \n告警IP：${IP} \n告警时间：${DATE} \n告警等级：严重 \n告警人员：王士博 \n告警详情：SDB的任务日志里出现error了，抓紧解决啊！ \n当前状态: PROBLEM \n告警日志文件：/data/etluser/LOG/SDB/$DATE_DIR/$FILE \n\n\n------请看下面error报错信息------- \nerror信息：\n$ERROR_MESSAGE"
          fi
        else
          echo "$name*.txt日志中error报错信息在第$error_run_num次运行报错"
        fi
      fi
   else
    echo "$FILE 日志里没有error报错"
   fi
done