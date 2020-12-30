# script_v3
1、blast_v2.0
blast 本地化流程

2、depth.pl
根据samtools depth的结果统计覆盖度，计算没有覆盖的区域。
help:
  perl depth.pl <sample.depth> <target.bed> <windows_size> <output> <wait_depth>
  sample.depth :samtools出来的结果
  target.bed :目标区域
  windows_size: 窗口大小，统计窗口内平均深度
  output：输出目录
  wait_depth:  超过该深度，输出到wairt文件
  
3、Transform_excel.py 
拆分或合并excel
python  Transform_excel.py  Merge --help
python  Transform_excel.py  Split --help

4、diff_lib.py
对比两个文本文件

5、diff_lib_v2.py
对比两个excel 文件

6、login20.sh
  自动登录(切换)服务器脚本

