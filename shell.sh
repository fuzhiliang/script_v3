#!/bin/sh
function die
{
  echo $@
  exit 1
}

if [ -n "$2" ]; then
    echo "包含第二个参数"
else
    die "sh $0 run.sh 10 " 
fi

Nproc=$2

#$$是进程pid
Pfifo="/tmp/$$.fifo"
mkfifo $Pfifo

#以999为文件描述符打开管道,<>表示可读可写
exec 999<>$Pfifo
rm -f $Pfifo

#向管道中写入Nproc行,作为令牌
for((i=1; i<=$Nproc; i++)); do
    echo
done >&999

#echo '' > out
#echo '' > ooo
#filenames=`less $1`
#echo $filenames
mkdir ./tmp_${1##*/}/
k=1
cat $1 | while read filename; do
#从管道中取出1行作为token，如果管道为空，read将会阻塞
#man bash可以知道-u是从fd中读取一行
    read -u999

    {
    #所要执行的任务
       echo "$filename" > ./tmp_${1##*/}/$k.sh && `sh ./tmp_${1##*/}/$k.sh` && {
            echo "$filename done"
	    #if [ -f "./tmp_${1##*/}/$k.sh.error" ] ;then
		#`rm  ./tmp_${1##*/}/$k.sh.error`
	    #fi
	    #touch ./tmp_${1##*/}/$k.sh.finish 
        } || {
            echo "$filename error"
	    #touch ./tmp_${1##*/}/$k.sh.error
        }
	
        sleep 2
    #归还token
        echo >&999
    }&
((k++))

done

#等待所有子进程结束
wait 

#关闭管道
exec 999>&-

#echo `$awk '{count[$0]++}END{for(name in count)print name}' out > ooo; awk 'END{print NR}' ooo`


