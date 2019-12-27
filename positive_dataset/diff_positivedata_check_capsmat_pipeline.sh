#!/bin/bash
#$1=/share/work2/fuzhl4317/project/capsmart_654gene/Int_ref_654gene_v3/test_down0.1_v2/positive_check_654_1_tissue

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ "$#" < "2" ]] ; then 
{
        echo "sh $0 $panel654_1  ${PWD} ${PWD}/positive_check"
        exit 0
}
fi

[ "$#" == "3" ] && outdir=$3 ||  outdir="$2/positive_check" 
echo "outdir: $outdir"
[  -d "$outdir" ] && rm -rf $outdir
cd $2 && source $BASEDIR/config

[ ${2##*/} == "silico_results" ] &&  cd $2/.. 

project=${PWD##*/} 
echo $project

mkdir $outdir && cd $outdir 
mkdir control
mkdir test test_head

[  -e "thesame" ] && rm -f thesame


echo "contol: $1"
echo "test: $2"

T_standard=$(grep  % $1/QC.xls.new|head -n 1 |cut -f 1)
N_standard=$(grep  % $1/QC_other.xls.new|head -n 1 |cut -f 1)
echo "参考标准样本名： $T_standard  $N_standard "
#T_test=Silico-stTA 
#N_test=Silico-stWA 
echo "此次分析中内参阳性样本名：$T_test  $N_test"
cd $outdir 
#特殊处理 chem_drug.xls
for i in `ls $1 `
do
        [ -e "$2/$i" ] && cp -f $2/$i  ./ ||  cp -f $2/*/$i  ./
        echo -e "$i" >>diff
        head -n 1 $1/$i >> diff
        if [ "$i" ==  "chem_drug.xls" ] 
        then
                awk -v name=$N_test 'NR==1{for(i=6;i<=NF;i++){if($i == name ){a=i}}}NR>1{print name"\t"$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$a }' chem_drug.xls >test2
                awk -v name=$N_standard 'NR==1{for(i=6;i<=NF;i++){if($i == name || $i == "N" ){a=i}}}NR>1{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$a }' $1/$i |sort >control/$i
                #sed -i -e "s/$N_standard\t$N_standard/$N_standard/" control/$i
                echo -e "sample\t药物\t基因\t位点\t作用\t结果解读\t等级\tN" > test_head/$i
        else
                grep -E "$T_standard|$N_standard" $1/$i |sort |cut -f 1-16 > control/$i
                grep -E "$T_test|$N_test" ./$i > test2
                head -n 1 $1/$i > test_head/$i
        fi
        sed  -i "s/$T_test/$T_standard/" test2
        sed  -i "s/$N_test/$N_standard/" test2
        
        cat  test2 >> test_head/$i
        
        sort test2 |cut -f 1-16 >test/$i

        diff -b -B -i control/$i test/$i  >>diff
        echo -e "\n\\n\n" >>diff

done

sed -i  's/\-\-\-/===/' diff
sed -i  "s/>\s$T_standard/> $T_test/" diff
sed -i  "s/>\s$N_standard/> $N_test/" diff

grep -E -A 5 -B 3 '[0-9][adc][0-9]' diff >$project.diff.v1.xls
