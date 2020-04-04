#BigData Application Performance Pridiction and Cluster Recommendation
#Date : 28.05.18
library(ggplot2)
library(dplyr)
library(gridExtra)
dev.off()
options(scipen=0)
setwd("/home/sc306/Dropbox/SA/ClusterBenchMarking/hadoop/ClusterBenchmarking")
readOps.data <- read.csv(file = "readData.csv", header = TRUE)
#readOps.data <- filter(readOps.data, readOps.data$Duration <= 1500)


writeOps.data <- read.csv(file = "writeData.csv", header = TRUE)
writeOps.data$shuffleData = as.integer((writeOps.data$DataSize*(writeOps.data$MapSelectivity/100)*writeOps.data$Mappers)/8)
#shuffleOps.data <- filter(shuffleOps.data, shuffleOps.data$Duration <= 12000)

shuffleOps.data <- read.csv(file = "shuffleData.csv", header = TRUE)
shuffleOps.data$shuffleData = as.integer((shuffleOps.data$DataSize*(shuffleOps.data$MapSelectivity/100)*shuffleOps.data$Mappers)/8)
shuffleOps.data <- filter(shuffleOps.data, shuffleOps.data$Duration <= 12000)


collectOps.data <- read.csv(file = "collectData.csv", header = TRUE)
collectOps.data$MapSelectivityData <- as.integer(collectOps.data$MapOutputRec*100/1048576)


spillOps.data <- read.csv(file = "spillData.csv", header = TRUE)
spillOps.data$MapSelectivityData <- as.integer(spillOps.data$MapOutputRec*100/1048576)
#spillOps.data <- filter(spillOps.data, spillOps.data$Duration <= 15000)

mergeOps.data <- read.csv(file = "mergeData.csv", header = TRUE)
mergeOps.data$MapSelectivityData <- as.integer(mergeOps.data$MapOutputRec*100/1048576)
mergeOps.data <- filter(mergeOps.data, mergeOps.data$Duration <= 150)

mapPhase.data <- read.csv(file = "mapdata/allOut.csv", header = TRUE)
summary(mapPhase.data)

reducePhase.data <- read.csv(file = "reducedata/out/allOut.csv", header = TRUE)
summary(reducePhase.data)
#head(readOps.data)



p1<-ggplot(readOps.data, aes(x=readOps.data$MapSelectivity, y=readOps.data$Duration)) + geom_point()+geom_smooth(method=lm)+labs(x="Map Selectivity(%)",y="Time(ms)")+ggtitle("Read Operation")
p4<-ggplot(collectOps.data, aes(x=collectOps.data$MapSelectivityData, y=collectOps.data$Duration)) + geom_point()+geom_smooth(method=lm)+labs(x="Map Selectivity(%)",y="Time(ms)")+ggtitle("Collect Operation")
p5<-ggplot(spillOps.data, aes(x=spillOps.data$MapSelectivityData, y=spillOps.data$Duration)) + geom_point()+geom_smooth(method=lm)+labs(x="Map Selectivity(%)",y="Time(ms)")+ggtitle("Spill Operation")
p6<-ggplot(mergeOps.data, aes(x=mergeOps.data$MapSelectivityData, y=mergeOps.data$Duration)) + geom_point()+geom_smooth(method=lm)+labs(x="Map Selectivity(%)",y="Time(ms)")+ggtitle("Merge Operation")

p2<-ggplot(writeOps.data, aes(x=writeOps.data$shuffleData, y=writeOps.data$Duration)) + geom_point()+geom_smooth(method=lm)+labs(x="Map Selectivity(%)",y="Time(ms)")+ggtitle("Write Operation")
p3<-ggplot(shuffleOps.data, aes(x=shuffleOps.data$shuffleData, y=shuffleOps.data$Duration)) + geom_point()+geom_smooth(method=lm)+labs(x="Map Selectivity(%)",y="Time(ms)")+ggtitle("Shuffle Operation")

p7<-ggplot(mapPhase.data, aes(x=mapPhase.data$MapSelectivity, y=mapPhase.data$Duration)) + geom_point()+geom_smooth(method=lm)+labs(x="Map Selectivity(%)",y="Time(ms)")+ggtitle("Map Phase")
p8<-ggplot(reducePhase.data, aes(x=reducePhase.data$MapSelectivity, y=reducePhase.data$Duration)) + geom_point()+geom_smooth(method=lm)+labs(x="Map Selectivity(%)",y="Time(ms)")+ggtitle("Reduce Phase")

#Both approaces works, however multiplot function implementation shoud be copied and pasted from 
#multiplot(p1, p2, p3, p4,p5,p6, cols=2)
grid.arrange(p1, p4, p5, p6,p3,p2,p7,p8, ncol=2, top="Different Operations")
grid.arrange(p1, p4, p5, p6,p3,p2, ncol=2, top="Different Operations")


lmRead <- lm(readOps.data$Duration~readOps.data$DataSize)
summary(lmRead)

lmCollect <- lm(collectOps.data$Duration~collectOps.data$MapSelectivity+collectOps.data$Mappers)
summary(lmCollect)

lmSpill <- lm(spillOps.data$Duration~spillOps.data$MapSelectivity+spillOps.data$Mappers)
summary(lmSpill)

lmMerge <- lm(mergeOps.data$Duration~mergeOps.data$MapSelectivity+mergeOps.data$Mappers)
summary(lmMerge)



lmShuffle <- lm(shuffleOps.data$Duration~shuffleOps.data$MapSelectivity+shuffleOps.data$Mappers+shuffleOps.data$DataSize)
summary(lmShuffle)

lmWrite <- lm(writeOps.data$Duration~writeOps.data$MapSelectivity+writeOps.data$Mappers)
summary(lmWrite)

lmMap <- lm(mapPhase.data$Duration~mapPhase.data$MapSelectivity)
summary(lmMap)

lmReduce <- lm(reducePhase.data$Duration~reducePhase.data$MapSelectivity+reducePhase.data$DataSize)
summary(lmReduce)  





# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}
