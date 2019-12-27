library(grid)
library(futile.logger)
library(VennDiagram)
args<-commandArgs(T)
#args[1]="1101424.paste"
#args[1]="1100615.paste"
#args[1]="1205209.paste"

data=read.table(args[1])
a=args[2]
b=args[3]
c=args[4]
A <-data[,as.numeric(a)];
B <-data[,as.numeric(b)];
C <-data[,as.numeric(c)];
futile.logger::flog.threshold(futile.logger::ERROR, name = "VennDiagramLogger")
venn.plot <- venn.diagram (
  #数据列表
  x = list(
    AZ = A,
    covaris = B,
    NVZ = C
  ),
  #filename ="1.tiff", #保存路径
  filename =NULL,#保存路径
  height = 600,
  width = 600,
  resolution =300,
  #imagetype="png",
  col = "transparent", #指定图形的圆周边缘颜色 transparent 透明
  fill = c("cornflowerblue", "green", "darkorchid1"), #填充颜色
  alpha = 0.25,#透明度
  label.col = c("orange", "white", "darkorchid4", "white",
                "white", "darkgreen", "white"),
  cex = 0.75,#每个区域label名称的大小
  fontfamily = "serif",#字体
  fontface = "bold",#字体格式
  cat.col = c("darkblue", "darkgreen", "darkorchid4"),#分类颜色
  cat.cex = 0.7, #每个分类名称大小
  cat.pos = c(100, 260, 0), #
  cat.dist = c(0.07, 0.07, 0.05), #
  cat.fontfamily = "serif",#分类字体
  rotation.degree =180,#旋转角度
  margin = 0.1#在网格单元中给出图周围空白量的编号
);
#可以不保存查看图片，但是效果不佳（命令如下，但是需要首先把filename设置为（filename=NULL））
pdf(paste(args[1],".pdf",sep=""));
grid.draw(venn.plot);
dev.off();

