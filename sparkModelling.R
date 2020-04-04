#BigData Application Performance Pridiction and Cluster Recommendation
#Date : 28.05.18
library(ggplot2)
library(dplyr)
library(gridExtra)
library(caret)
library(grid)
library(ggpubr)
library(e1071)
library(randomForest)
library(caTools)

# dev.off()
options(scipen=999)
setwd("/home/sc306/Dropbox/SA/ClusterBenchMarking/hadoop/ClusterBenchmarking/dfwc/")
allDataOriginal <- read.table(file = "kmeans.report", header = TRUE)#contains both 128

allDataOriginal$DataSizeMB <- round((allDataOriginal$Input_data_size/1048576))
allDataOriginal$DataSizeGB <- allDataOriginal$Input_data_size/1073741824

allDataOriginal <- select(allDataOriginal, Duration.s., NumEx, ExCore, ExMem, LevelPar, DataSizeMB, DataSizeGB)

#Do some data preprocessing

allDataOriginal$ExMem = as.integer(gsub("g", "", allDataOriginal$ExMem))

head(allDataOriginal)
str(allDataOriginal)
allDataOriginal = filter(allDataOriginal, allDataOriginal$Duration.s. <= 3000)

summary(allDataOriginal)

#allDataOriginal$NumEx = factor(allDataOriginal$NumEx)
#allDataOriginal$ExCore = factor(allDataOriginal$ExCore)
#allDataOriginal$ExMem = factor(allDataOriginal$ExMem)
#allDataOriginal$DriverMem = factor(allDataOriginal$DriverMem)


generatePlot <- function(originalData, filterbyCol, filterByVal, title, color){
  
  #xval = seq(min(filteredData$DataSizeMB), nrow(filteredData), by = (max(filteredData$DataSizeMB)/nrow(filteredData)))
  #p<-ggplot(filteredData, aes(x=filteredData$DataSizeMB, y=filteredData$Duration.s.)) + geom_point()+geom_smooth(method='auto')+labs(x="Data Size (MB)",y="Time(s)")+ggtitle(title)
  p <- '';
  if(missing(color)){
    filteredData = originalData %>%  filter(originalData[[filterbyCol]] == filterByVal)
    p<-ggplot(filteredData, aes(x=filteredData$DataSizeMB, y=filteredData$Duration.s.)) + geom_point()+labs(x="Data Size (MB)",y="Time(s)")+ggtitle(title)+
      theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
            axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))
  }else{
    f = originalData %>%  filter(originalData[[filterbyCol]] == filterByVal)
    p<-ggplot(f, aes(x=seq(1:nrow(f)), y=f$Duration.s.,  colour=factor(f[[color]]))) + geom_point()+labs(x="Observation Index",y="Time(s)", color="Num Executor")+ggtitle(title)+
      theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
            axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))
  }
  return(p)
}

p01 <- generatePlot(allDataOriginal, "DataSizeMB", 443, "500MB", "NumEx")
p02 <- generatePlot(allDataOriginal, "DataSizeMB", 3830, "4GB", "NumEx")
p03 <- generatePlot(allDataOriginal, "DataSizeMB", 7661, "8GB", "NumEx")
p04 <- generatePlot(allDataOriginal, "DataSizeMB", 9576, "9GB", "NumEx")
p05 <- generatePlot(allDataOriginal, "DataSizeMB", 11491, "11GB", "NumEx")

ggarrange(p01,p02,p03,p04,p05, ncol=2, nrow=3, common.legend = TRUE, legend = "bottom")

p1<-generatePlot(allDataOriginal, "NumEx", 4, "4 Executors", "DataSizeMB")
p2<-generatePlot(allDataOriginal, "NumEx", 8, "8 Executors", "DataSizeMB")
p3<-generatePlot(allDataOriginal, "NumEx", 16, "16 Executors", "DataSizeMB")
p4<-generatePlot(allDataOriginal, "NumEx", 24, "24 Executors", "DataSizeMB")
p5<-generatePlot(allDataOriginal, "NumEx", 32, "32 Executors", "DataSizeMB")

ggarrange(p1,p2,p3,p4,p5, ncol=2, nrow=3, common.legend = TRUE, legend = "bottom")

p6<-generatePlot(allDataOriginal, "ExCore", 2, "2 Cores", "DataSizeMB")
p7<-generatePlot(allDataOriginal, "ExCore", 4, "4 Cores", "DataSizeMB")
p8<-generatePlot(allDataOriginal, "ExCore", 6, "6 Cores", "DataSizeMB")
p9<-generatePlot(allDataOriginal, "ExCore", 8, "8 Cores", "DataSizeMB")

ggarrange(p6,p7,p8,p9, ncol=2, nrow=3, common.legend = TRUE, legend = "bottom")

p10<-generatePlot(allDataOriginal, "ExMem", 2, "2GB", "DataSizeMB")
p11<-generatePlot(allDataOriginal, "ExMem", 4, "4GB", "DataSizeMB")
p12<-generatePlot(allDataOriginal, "ExMem", 6, "6GB", "DataSizeMB")
p13<-generatePlot(allDataOriginal, "ExMem", 8, "8GB", "DataSizeMB")

ggarrange(p10, p11, p12, p13, ncol=2, nrow=3, common.legend = TRUE, legend = "bottom")

p14<-generatePlot(allDataOriginal, "LevelPar", 8, "8", "DataSizeMB")
p15<-generatePlot(allDataOriginal, "LevelPar", 16, "16", "DataSizeMB")
p16<-generatePlot(allDataOriginal, "LevelPar", 32, "32", "DataSizeMB")
p17<-generatePlot(allDataOriginal, "LevelPar", 64, "64", "DataSizeMB")

ggarrange(p14, p15, p16, p17, ncol=2, nrow=3, common.legend = TRUE, legend = "bottom")





##Perform some job level basic modelling

set.seed(123)
#Two third 20 for training and 10 for testing
split = sample.split(allDataOriginal$Duration.s., SplitRatio = 0.8)
training_set = subset(allDataOriginal, split == TRUE)
test_set = subset(allDataOriginal, split == FALSE)

#Now run the regression

fit = lm(Duration.s. ~ DataSizeGB + NumEx  + ExCore , data = training_set)
summary(fit)
y_pred <- predict(fit, newdata = test_set)
y_pred
predict(fit, data.frame("DataSizeGB" = 15, "NumEx" = 64, "ExCore" = 16, "ExMem" = 24))

ggplot(test_set) +
  geom_point(aes(seq(1:nrow(test_set)), Duration.s.), color='red')+
  #geom_line(aes(Level, predict(lin_reg, dataset)),color='blue')+
  geom_line(aes(seq(1:nrow(test_set)), predict(fit, test_set)), color='green')+
  ggtitle("SVR Model")+
  xlab("Index")+
  ylab("Time")


set.seed(123)
#Two third 20 for training and 10 for testing
# split = sample.split(dataset$Salary, SplitRatio = 0.8)
# training_set = subset(dataset, split == TRUE)
# test_set = subset(dataset, split == FALSE)

#SIGMA AND GAMMA are the same. 
grid_radial <- expand.grid(sigma = c(0,0.01, 0.02, 0.025, 0.03, 0.04,0.05, 0.06, 0.07,0.08, 0.09, 0.1, 0.25, 0.5, 0.75,0.9), C = c(0,0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 1, 1.5, 2,5))
set.seed(3233)
control <- trainControl(method="repeatedcv", number=10, repeats=3, search="grid")
svm.tune <- train(Duration.s.~ DataSizeGB + NumEx  + ExCore + ExMem, data=training_set[c(-5,-6)], method="svmRadial", tuneGrid=grid_radial, trControl=control)
print(svm.tune)
plot(svm.tune)

fit = svm(Duration.s. ~ DataSizeGB + NumEx  + ExCore, data=training_set, type = 'eps-regression', gamma = 0.001, cost= 1000)
print(fit)


#Do some svm tuning
tuneResult <- tune(svm, Duration.s. ~ DataSizeGB + NumEx  + ExCore, data=training_set, type = 'eps-regression',
                   ranges = list(epsilon = seq(0,0.10,0.001), cost = 2^(2:10))
)

print(tuneResult)
plot(tuneResult)

plot(fit, training_set)

summary(fit)

ggplot(test_set) +
  geom_point(aes(seq(1:nrow(test_set)), Duration.s.), color='red')+
  geom_line(aes(seq(1:nrow(test_set)), predict(fit, test_set)), color='green')+
  ggtitle("SVR Model")+
  xlab("Index")+
  ylab("Time")


predict(fit, data.frame("DataSizeGB" = 0.4, "NumEx" = 4, "ExCore" = 2, "ExMem" = 2))







set.seed(1234)

head(training_set)

control <- trainControl(method="repeatedcv", number=10, repeats=3, search="grid")
set.seed(12345)
tunegrid <- expand.grid(.mtry=c(1:4))
rf_random <- train(Duration.s.~ DataSizeGB + NumEx  + ExCore + ExMem, data=training_set[c(-5,-6)], method="rf", tuneGrid=tunegrid, trControl=control)
print(rf_random)
plot(rf_random)

fitrf <- randomForest(x = training_set[c(-1,-5,-6)], y = training_set$Duration.s., ntree = 1500)
summary(fitrf)
predict(rf_random$finalModel, data.frame("DataSizeGB" = 20000, "NumEx" = 32, "ExCore" = 4, "ExMem" = 8))

ggplot(test_set) +
  geom_line(aes(seq(1:nrow(test_set)), Duration.s.), color='red')+
  geom_line(aes(seq(1:nrow(test_set)), predict(rf_random, test_set[c(-1,-5,-6)])), color='green')+
  ggtitle("SVR Model")+
  xlab("Index")+
  ylab("Time")


predict(fitrf, data.frame("DataSizeGB" = 0.1, "NumEx" = 4, "ExCore" = 2, "ExMem" = 2))