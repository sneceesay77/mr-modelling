#BigData Application Performance Pridiction and Cluster Recommendation
#Date : 28.05.18
library(ggplot2)
library(dplyr)
library(gridExtra)
library(caret)
library(grid)
library(ggpubr)
# dev.off()
options(scipen=999)
setwd("/home/sc306/Dropbox/SA/ClusterBenchMarking/hadoop/ClusterBenchmarking")
#setwd("/cs/home/sc306/Dropbox/SA/ClusterBenchMarking/hadoop/ClusterBenchmarking/")
allData <- read.table(file = "jobmodelling.txt", header = TRUE)#contains both 128
head(allData)

allData$DataSize = allData$Input_data_size/1048576


p0=ggplot(allData[1:39,], aes(x=allData[1:39,]$DataSize, y=allData[1:39,]$Duration.s.)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (MB)",y="Time(s)")+ggtitle("WC 5MB to 1GB")+
theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
      axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))

firstSet <- allData[1:20,]
p1=ggplot(firstSet, aes(x=firstSet$DataSize, y=firstSet$Duration.s.)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (MB)",y="Time(s)")+ggtitle("WC 5MB to 100MB")

secondSet <- allData[21:39,]
secondSet
p2=ggplot(secondSet, aes(x=secondSet$DataSize, y=secondSet$Duration.s.)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (MB)",y="Time(s)")+ggtitle("WC 50MB to 1GB")+
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))


thirdSet <- allData[40:nrow(allData),]
p3=ggplot(thirdSet, aes(x=thirdSet$DataSize, y=thirdSet$Duration.s.)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (MB)",y="Time(s)")+ggtitle("WC 1GB to 10GB") +
theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))


sortData <- read.table(file = "hadoopsort.txt", header = TRUE)#contains both 128
sortData <- filter(sortData, sortData$Duration.s. < 100)
sortData$DataSize = sortData$Input_data_size/1048576
p4 <- ggplot(sortData, aes(x=sortData$DataSize, y=sortData$Duration.s.)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (MB)",y="Time(s)")+ggtitle("Sort 10MB to 1GB") +
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))



teraSort <- read.table(file = "hadoopterasort.txt", header = TRUE)#contains both 128
teraSort <- filter(teraSort, teraSort$Duration.s. < 500)
teraSort$DataSize = teraSort$Input_data_size/1048576
p5 = ggplot(teraSort, aes(x=teraSort$DataSize, y=teraSort$Duration.s.)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (MB)",y="Time(s)")+ggtitle("TSort 100MB to 10GB") +
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))



grid.arrange(p1,p3,p2,p0,p4,p5, ncol=2, top="Data")
grid.arrange(p4,p5,p2,p0, ncol=2, top="Data")
grid.arrange(p0, ncol=1, top="Data")
options(digits=2)
options(scipen=999)
S_d <- 1
M_t <- 1
iterations = 10
variables = 1

output <- matrix(ncol=variables, nrow=iterations)

for(i in 1:iterations){
  S_d <- S_d + 2
  M_t <- M_t + 2
  output[i,] <- (10.45*S_d) + (579.48*M_t) + 6144.6
  
}

output
output <- data.frame(output)
output$sequence <- seq(1:10)

plot(output$sequence, output$output)
 

