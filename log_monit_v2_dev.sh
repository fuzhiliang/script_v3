#!/bin/sh
DATE_DIR=$(date +%Y%m%d)
DATE=`date +%Y年%m月%d日%H时%M分%S秒`
DATE_F=`date +%Y%m%d%H%M%S`
HOST=`/bin/hostname`
IP=`/sbin/ifconfig|grep "inet addr"|grep "Bcast"|cut -d":" -f2|awk -F" " '{print $1}'`
log_dir=${PWD}/log
project=${PWD##*/}
echo $project;
if [ ! -d $log_dir ];then
  echo "Error: Log directory does not exist!"
  exit 0
fi

for i in `find  germline/ -name *.sh.[eo]*`; do 
	name=${i##*/} 
	cp  $i  $log_dir/${name/.sh./_}$DATE_F.txt  
done

cd $log_dir

if [ -d $log_dir/error_log ];then
  rm -fr $log_dir/error_log
fi
mkdir $log_dir/error_log

error_flag="error|Traceback|'not exist'|'can’t find'|'Segmentation fault'|'command not found'|'Died'"

FILE=(*_e[0-9]*.txt)
name=(${FILE[@]%_e[0-9]*.txt})
uname=($(echo ${name[@]}|sed 's/ /\n/g' |sort |uniq))
#echo ${uname[*]}
#.o文件比有报错的.e文件数量大1，说明运行成功了

 
for ((i=0; i<=${#uname[@]}-1; i++ )); do
	o=(${uname[$i]}_o[0-9]*.txt)
	e=$(/bin/grep -E -i "$error_flag" ${uname[$i]}_e*.txt |awk -F: '{print $1}'|sort |uniq|wc -l)
	#echo o:${#o[@]}
	#echo e:$e
	if [ ${#o[@]} -gt $e ];then
		echo "${uname[$i]}">>$log_dir/error_log/Success_task.xls
	else
		file=$(/bin/grep -E -i -l "$error_flag" ${uname[$i]}_e*.txt|tail -1)
		#file=(${uname[$i]}_e*.txt)
		cp $file $log_dir/error_log/
		ERROR_MESSAGE=$(/bin/grep -A5  -E -i  "$error_flag" ${file})

		echo "$log_dir/$file:
	$ERROR_MESSAGE 

################################
		"
	fi
done>$log_dir/error_log/$project.Fail.task.xls
echo "$DATE:log error check done!"

###检查全阴性样本


#SnvIndel.xls CNV.xls fusion.combined.xls
#awk 'NR==1{for(i=1;i<NF;i++){if($i~/_vaf/){a[i]=$i}}}NR>1{for(i in a ){if ($i>=0.01){print a[i]"\t"$1"\t"$2"\t"$(i-1)"\t"$i}}}' hotspots.new.xls ##获取大于0.01的热点

cd $log_dir/../

if [ ! -s hotspots.new.xls ];then
  echo "Error: hotspots.new.xls does not exist!"
  exit 0
fi

cutoff=$(grep -wq -E 'P$' info.txt && echo 0.001 || echo 0.01)
echo cutoff=$cutoff
awk -v cutoff=$cutoff 'NR==1{for(i=1;i<NF;i++){if($i~/_vaf/){a[i]=$i}}}NR>1{for(i in a ){if ($i>=cutoff){print a[i]"\t"$1"\t"$2"\t"$(i-1)"\t"$i}}}' hotspots.new.xls|while read sample b
do 
	a=$(cat SnvIndel.xls CNV.xls fusion.combined.xls | grep -w ${sample%%_vaf} |wc -l)
	if [ $a -ne 0 ];then
		echo -e "$sample\t$b\tpositive" >>$log_dir/error_log/hotspots.new.ge.$cutoff.xls
	else
		echo -e  "Warning：$sample\t$b\tnegative"
	fi
done >>$log_dir/error_log/$project.Fail.task.xls
echo "$DATE:Hotspot examination of negative samples done!"

###检查内置阳性参考品
if [ -d "./silico_results" ]; then
	project_dir=${PWD}
	panel=\$panel$(sed 's/\s\+/\n/g' $project_dir/run.sh |grep -A 1  panel |tail -n 1)
	pn=$(sed 's/\s\+/\n/g' $project_dir/run.sh |grep -A 1  panel |tail -n 1)
	echo panel: $panel 
	echo "
	cd $project_dir/silico_results
	source /share/work2/fuzhl4317/script/positive_dataset/config
	sh /share/work2/fuzhl4317/script/positive_dataset/diff_positivedata_check_capsmat_pipeline.sh  ${panel} $project_dir/silico_results
	">$project_dir/silico_results/check.sh

	sh $project_dir/silico_results/check.sh
	cd $project_dir
	echo "$DATE:positive sample check done!"
	b=$(/bin/find ${PWD} -path '*positive_check*' -name *.diff.v1.xls)
	echo -e  "$DATE_F\ncp -r ${b%/*}/test_head/  /share/work2/fuzhl4317/script/positive_dataset/$pn" >>/share/work2/fuzhl4317/script/positive_dataset/cp.log 
fi


###检查结果在$project_dir/silico_results/positive_check/$project.diff.v1.xls

a="$log_dir/error_log/$project.Fail.task.xls"
#b=$(/bin/find ${PWD} -path '*positive_check*' -name *.diff.v1.xls)
cmd="perl /share/work2/fuzhl4317/script/log_monit_mail_v1_dev.pl "
if [ -s $a  ]; then
	echo mail $a
	cmd+=" -a $a "
fi

if [ -s $b  ]; then
	echo mail $b
	cmd+=" -b $b"
fi
echo "$cmd" >$log_dir/../monit.sh

[[ -s $a || -s $b  ]] &&  $cmd || echo "check log error and positive sample done, No error message." 

