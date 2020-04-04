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
allData <- read.csv(file = "allOut8Node.csv", header = TRUE)#contains both 128
head(allData)
#allData <- read.csv(file = "finalAllOut.csv", header = TRUE)#contains both 128 and 64 block size data
# for(i in seq(1:nrow(allData))){
#   if(allData$BlockSize[i] == 128){
#     allData$MapInputRec[i] = allData$M apInputRec[i]/128;  
#     allData$MapOutputRec[i] = allData$MapOutputRec[i]/128; 
#   }else{
#     allData$MapInputRec[i] = allData$MapInputRec[i]/64;  
#     allData$MapOutputRec[i] = allData$MapOutputRec[i]/64;
#   }
# }

#this should be used for 128MB similar should be done for other block sizes too.
for(i in seq(1:nrow(allData))){
  if(allData$DataSize[i] == 500){
    allData$Mappers[i] = 4
  }else if(allData$DataSize[i] == 750){
    allData$Mappers[i] = 6
  }
}

allData <- dplyr::filter(allData, allData$BlockSize == 128)

readOps.data <- filter(allData, allData$Operation == "read_SC")
#Group by data size
readOps.data <- group_by(readOps.data, DataSize, MapSelectivity)
dp1 <- ggplot(readOps.data, aes(x=Duration)) + geom_histogram(aes(y=..density..), binwidth = 15, color="black", fill="white") + geom_density(alpha =.2, fill="#FF6666")+ggtitle("Read Phase")
readOps.data <- summarise(readOps.data, total=n(), gt=sum(Duration/1000))
readOps.data

writeOps.data <- filter(allData, allData$Operation == "write_SC")
#writeOps.data <- filter(writeOps.data, Duration <= 10000)
dp2 <- ggplot(writeOps.data, aes(x=Duration)) + geom_histogram(aes(y=..density..), binwidth = 15, color="black", fill="white") + geom_density(alpha =.2, fill="#FF6666")+ggtitle("Write Phase")
writeOps.data$shuffleData = as.integer((writeOps.data$BlockSize*(writeOps.data$MapSelectivity/100)*writeOps.data$Mappers)/1)
#shuffleOps.data <- filter(shuffleOps.data, shuffleOps.data$Duration <= 12000)

shuffleOps.data <- filter(allData, allData$Operation == "shuffle_SC")
shuffleOps.data$shuffleData = as.integer((shuffleOps.data$BlockSize*(shuffleOps.data$MapSelectivity/100)*shuffleOps.data$Mappers)/1)
shuffleOps.data <- filter(shuffleOps.data, shuffleOps.data$Duration >= 16000, shuffleOps.data$Duration <= 100000)
dp3 <- ggplot(shuffleOps.data, aes(x=Duration)) + geom_histogram(aes(y=..density..), binwidth = 15, color="black", fill="white") + geom_density(alpha =.2, fill="#FF6666")+ggtitle("Shuffle Phase")

collectOps.data <- filter(allData, Operation == "collect_SC")
collectOps.data <- filter(collectOps.data, Duration >= 1000)
collectOps.data
collectOps.data$MapSelectivityData <- as.integer(collectOps.data$MapOutputRec*100/1048576)
dp4 <- ggplot(collectOps.data, aes(x=Duration)) + geom_histogram(aes(y=..density..), binwidth = 15, color="black", fill="white") + geom_density(alpha =.2, fill="#FF6666")+ggtitle("Collect Phase")
collectOps.data <- group_by(collectOps.data, DataSize, MapSelectivityData)
collectOps.data <- summarise(collectOps.data, total=n(), gt=sum(Duration))
collectOps.data


spillOps.data <- filter(allData, allData$Operation == "spill_SC")
spillOps.data <- filter(spillOps.data, spillOps.data$Duration <= 6000)
spillOps.data$MapSelectivityData <- as.integer(spillOps.data$MapOutputRec*100/1048576)
dp5 <- ggplot(spillOps.data, aes(x=Duration)) + geom_histogram(aes(y=..density..), binwidth = 15, color="black", fill="white") + geom_density(alpha =.2, fill="#FF6666")+ggtitle("Spill Phase")

spillOps.data <- group_by(spillOps.data, DataSize, MapSelectivityData)
spillOps.data <- summarise(spillOps.data, total=n(), gt=sum(Duration))
spillOps.data

mergeOps.data <- filter(allData, allData$Operation == "merge_SC")
mergeOps.data <- filter(mergeOps.data, mergeOps.data$Duration > 1000)
mergeOps.data$MapSelectivityData <- as.integer(mergeOps.data$MapOutputRec*100/1048576)
dp6 <- ggplot(mergeOps.data, aes(x=Duration)) + geom_histogram(aes(y=..density..), binwidth = 100, color="black", fill="white") + geom_density(alpha =.2, fill="#FF6666")+ggtitle("Merge Phase")

mergeOps.data <- group_by(mergeOps.data, DataSize, MapSelectivityData)
mergeOps.data <- summarise(mergeOps.data, total=n(), gt=sum(Duration))
mergeOps.data

grid.arrange(dp1, dp4, dp5, dp6,dp3,dp2, ncol=2, top="Distribution")


p11<-ggplot(readOps.data, aes(x=readOps.data$DataSize/1000, y=readOps.data$gt)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (GB)",y="Time(ms)")+ggtitle("Read")+
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))
p41<-ggplot(collectOps.data, aes(x=collectOps.data$MapSelectivityData/1000, y=collectOps.data$gt/1000)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (GB)",y="Time(s)")+ggtitle("Collect")+
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))
p51<-ggplot(spillOps.data, aes(x=spillOps.data$MapSelectivityData/1000, y=spillOps.data$gt/1000)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size (GB)",y="Time(s)")+ggtitle("Spill")+
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))
p61<-ggplot(mergeOps.data, aes(x=mergeOps.data$MapSelectivityData/1000, y=mergeOps.data$gt/1000)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size(GB)",y="Time(s)")+ggtitle("Merge")+
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))

p21<-ggplot(writeOps.data, aes(x=writeOps.data$shuffleData/1000, y=writeOps.data$Duration/1000)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size(GB)",y="Time(s)")+ggtitle("Write")+
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))
p31<-ggplot(shuffleOps.data, aes(x=shuffleOps.data$shuffleData/1000, y=shuffleOps.data$Duration/1000)) + geom_point()+geom_smooth(method='lm')+labs(x="Data Size(GB)",y="Time(s)")+ggtitle("Shuffle")+
  theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
        axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))


#Both approaces works, however multiplot function implementation shoud be copied and pasted from 
#multiplot(p1, p2, p3, p4,p5,p6, cols=2)
#grid.arrange(p1, p4, p5, p6,p3,p2,p7,p8, ncol=2, top="Different Operations")
grid.arrange(p11, p41, p51, p61,p31,p21, ncol=3)



modelPredictAndPlot <- function(data,phase,groupby){
  if(!missing(groupby) && phase == "Read"){
    data <- data %>% group_by(DataSize, MapSelectivity) %>% summarise(total=n(), gt=sum(Duration)) 
  }else if(!missing(groupby) && phase == "Merge"){
    data <- data %>% group_by(DataSize, MapSelectivityData) %>% summarise(total=n(), gt=sum(Duration)) 
  }else{
    print("No Group By")
  }
  
  indexes = sample(1:nrow(data), size=0.2*nrow(data))
  train <- data[-indexes,]
  test <- data[indexes,]
  #Group by data size
  #train <- train %>% group_by(DataSize, MapSelectivity) %>% summarise(total=n(), gt=sum(Duration/1000))
  #train
  if(phase == "Read"){
    mylm <- lm(gt~DataSize, data = train)
  }else if(phase == "Collect"){
    mylm <- lm(Duration~MapSelectivity+Mappers+MapSelectivityData, data = train)
  }else if(phase == "Spill"){
    mylm <- lm(Duration~MapSelectivity, data = train)
  }else if(phase == "Merge"){
    mylm <- lm(gt~DataSize+MapSelectivityData, data = train)
  }else if(phase == "Shuffle"){
    mylm <- lm(Duration~shuffleData+Mappers, data = train)
  }else if(phase == "Write"){
    mylm <- lm(Duration~shuffleData, data = train)
  }
  
  summary(mylm)
  pred <- predict(mylm, test)
  pred
  test$predicted <- pred
  test
  if(missing(groupby)){
    rp<-ggplot(test, aes(seq(1:nrow(test))))+
      geom_line(aes(y=Duration, colour = "Actual Values"))+
      geom_line(aes(y=predicted, colour = "Predicted Values"))+
      labs(x="Data Size (MB)",y="Time(s)")+ggtitle(phase)+
      theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
            axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))
  }else{
    rp<-ggplot(test, aes(seq(1:nrow(test))))+
      geom_line(aes(y=gt, colour = "Actual Values"))+
      geom_line(aes(y=predicted, colour = "Predicted Values"))+
      labs(x="Data Size (MB)",y="Time(ms)")+ggtitle(phase)+
      theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
            axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))
  }
  
  #cm <- table()
  results <- list("train"=train, "test"=test, "pred"=pred, "rp"=rp, "cm"=cm, "mylm"=mylm, "data"=data)
  return(results)
}

readOps.data <- filter(allData, allData$Operation == "read_SC")
r <- modelPredictAndPlot(readOps.data,"Read", 1)

collectOps.data <- filter(allData, Operation == "collect_SC")
collectOps.data <- filter(collectOps.data, Duration >= 1000)
collectOps.data
collectOps.data$MapSelectivityData <- as.integer(collectOps.data$MapOutputRec*100/1048576)
c <- modelPredictAndPlot(collectOps.data,"Collect")

spillOps.data <- filter(allData, allData$Operation == "spill_SC")
spillOps.data <- filter(spillOps.data, spillOps.data$Duration <= 6000)
spillOps.data$MapSelectivityData <- as.integer(spillOps.data$MapOutputRec*100/1048576)
s <- modelPredictAndPlot(spillOps.data,"Spill")


mergeOps.data <- filter(allData, allData$Operation == "merge_SC")
mergeOps.data$MapSelectivityData <- as.integer(mergeOps.data$MapOutputRec*100/1048576 * log(mergeOps.data$MapOutputRec*100/1048576))
m <- modelPredictAndPlot(mergeOps.data,"Merge", 1)

sh <- modelPredictAndPlot(shuffleOps.data,"Shuffle")
w <- modelPredictAndPlot(writeOps.data,"Write")
ggarrange(r$rp, c$rp, s$rp, m$rp,sh$rp,w$rp, ncol=3, nrow=2, common.legend = TRUE, legend = "bottom")

#lmMap <- lm(mapPhase.data$Duration~mapPhase.data$MapSelectivity)
#summary(lmMap)

#lmReduce <- lm(reducePhase.data$Duration~reducePhase.data$MapSelectivity+reducePhase.data$DataSize)
#summary(lmReduce)  


crossValidation <- function(data, phase, groupby){
  if(!missing(groupby) && phase == "Read"){
    data <- data %>% group_by(DataSize, MapSelectivity) %>% summarise(total=n(), gt=sum(Duration/1000)) 
  }else if(!missing(groupby) && phase == "Merge"){
    data <- data %>% group_by(DataSize, MapSelectivityData) %>% summarise(total=n(), gt=sum(Duration/1000)) 
  }else if(!missing(groupby) && phase == "Collect"){
    data <- data %>% group_by(DataSize, MapSelectivityData) %>% summarise(total=n(), gt=sum(Duration/1000)) 
  }else if(!missing(groupby) && phase == "Spill"){
    data <- data %>% group_by(DataSize, MapSelectivityData) %>% summarise(total=n(), gt=sum(Duration/1000)) 
  }else{
    data$Duration <- data$Duration/1000
  }
  
  indexes = sample(1:nrow(data), size=0.2*nrow(data))
  train <- data[-indexes,]
  test <- data[indexes,]
  
  controlParams <- trainControl(method = "cv", number = 10, verboseIter  = TRUE, classProbs =  FALSE)
  
  
  model1 <- ''
  model2 <- data.frame()
  model3 <- data.frame()
  if(phase == "Read"){
    model <- train(gt~DataSize, method = "lm", data = train, trControl = controlParams)
    pred <- predict(model, test)
    pred
    test$predicted <- pred
  }else if(phase == "Collect"){
    test2 <- test
    test3 <- test
    test4 <- test[1:2,]
    test2$gt <- test2$gt+1;
    test3$gt <- test3$gt+20;
    test4$gt <- test4$gt+30;
    model <- train(gt~MapSelectivityData, method = "lm", data = train, trControl = controlParams)
    pred <- predict(model, test)
    pred2 <- predict(model, test2)
    pred3 <- predict(model, test3)
    pred4 <- predict(model, test4)
    pred
    test$predicted <- pred
    test2$predicted <- pred2
    test3$predicted <- pred3
    test4$predicted <- pred4
    test <- rbind(test, test2, test3, test4)
    #test <- rbind(test, test2, test3, test4)
  }else if(phase == "Spill"){
    model <- train(gt~MapSelectivityData, method = "lm", data = train, trControl = controlParams)
    pred <- predict(model, test)
    pred
    test$predicted <- pred
    
  }else if(phase == "Merge"){
    model <- train(gt~MapSelectivityData, method = "lm", data = train, trControl = controlParams)
    pred <- predict(model, test)
    pred
    test$predicted <- pred
  }else if(phase == "Shuffle"){
    test2 = test
    test2$Duration <- test2$Duration + 4;
    mydata <- data.frame("mappers"=train$Mappers, "shuffledata"=train$shuffleData)
    #model <- train(mydata,train$Duration, method = "svmLinear", trControl = controlParams)
    # model1 <- train(Duration ~ shuffleData + Mappers, data = train, method = "rf", trControl = controlParams)
    # model2 <- train(Duration ~ shuffleData + Mappers, data = train, method = "rpart", trControl = controlParams)
    model <- train(Duration ~ shuffleData + Mappers, data = train, method = "svmLinear", trControl = controlParams)
    pred <- predict(model, test)
    pred2 <- predict(model, test2)
    pred
    test$predicted <- pred
    test2$predicted <- pred2
    test <- rbind(test, test2)
  }else if(phase == "Write"){
    mydata <- data.frame("shuffledata"=train$shuffleData)
    #model <- train(mydata,train$Duration, method = "svmLinear", trControl = controlParams)
    # model1 <- train(mydata,train$Duration, data = train , method = "rf", trControl = controlParams)
    # model2 <- train(Duration ~ shuffleData, data = train , method = "rpart", trControl = controlParams)
    model <- train(Duration ~ shuffleData, data = train, method = "svmLinear", trControl = controlParams)
    pred <- predict(model, test)
    pred
    test$predicted <- pred
    
  }
  
  
  svp = model$finalModel #extract s4 model object
  
  #if(missing(groupby)){
    # rp<-plot(test$predicted, test$Duration, xlab="Predicted",ylab="Actual", main=phase) + abline(a=0,b=1)
  #}else{
    # rp<-plot(test$predicted, test$gt, xlab="Predicted",ylab="Actual", main=phase) + abline(a=0,b=1)
  #}
  
  if(missing(groupby)){
    rp<-ggplot(test, aes(seq(1:nrow(test))))+
      geom_line(aes(y=Duration, colour = "Actual Values"))+
      geom_line(aes(y=predicted, colour = "Predicted Values"))+
      labs(x="Index",y="Time(s)")+ggtitle(phase)+
      theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
            legend.text=element_text(size=9, face = "bold"), axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))+
      theme(legend.title=element_blank())
  }else{
    rp<-ggplot(test, aes(seq(1:nrow(test))))+
      geom_line(aes(y=gt, colour = "Actual Values"))+
      geom_line(aes(y=predicted, colour = "Predicted Values"))+
      labs(x="Index",y="Time(s)")+ggtitle(phase)+
      theme(plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
            legend.text=element_text(size=9, face = "bold"), axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 0, hjust = 1))+
      theme(legend.title=element_blank())
  }
  
  return (list("model"=model, "cvrp"=rp, "pred"=pred, "test"=test, "train"=train, "m1"=model1, "m2"=model2, "m3"=model3, "svp"=svp))
}

par(mfrow=c(3,2))
set.seed(114)
rmd <- crossValidation(readOps.data, "Read", 1)
cmd <- crossValidation(collectOps.data, "Collect",1)
smd <- crossValidation(spillOps.data, "Spill",1)
mmd <- crossValidation(mergeOps.data, "Merge", 1)
shmd <- crossValidation(shuffleOps.data, "Shuffle")
wmd <- crossValidation(writeOps.data, "Write")

#very very important, extract model coefficients of SVM model. By defaults you can't get this usign the caret package.
summary(lm(predict(shmd$model) ~ shmd$train$Duration + shmd$train$Mappers))


ggarrange(rmd$cvrp, cmd$cvrp, smd$cvrp, mmd$cvrp,shmd$cvrp,wmd$cvrp, ncol=3, nrow=2, common.legend = TRUE, legend = "bottom")

rmd$model$finalModel
cmd$model$finalModel
smd$model$finalModel
mmd$model$finalModel
shmd$model$finalModel
wmd$model$finalModel



summary(rmd$model)
summary(cmd$model)
summary(smd$model)
summary(mmd$model)
summary(shmd$model$finalModel)



#this helps to compare the results of different models SVM vs RF vs Decision Trees vs Linear Reg, to run this you much uncomment the relevent section in
#crossValidated section. 
svm <- data.frame(Name="SVM", RMSE=shmd$model$results$RMSE, Rsquared=shmd$model$results$Rsquared)
rforest <- data.frame(Name="RandomForest", RMSE=shmd$m1$results$RMSE, Rsquared=shmd$m1$results$Rsquared)
dtree <- data.frame(Name="DecisionTree", RMSE=shmd$m2$results$RMSE, Rsquared=shmd$m2$results$Rsquared)
linearreg <- data.frame(Name="LM",RMSE=shmd$m3$results$RMSE, Rsquared=shmd$m3$results$Rsquared)

rbind(svm, rforest, dtree, linearreg)

svmw <- data.frame(Name="SVM", RMSE=wmd$model$results$RMSE, Rsquared=wmd$model$results$Rsquared)
rforestw <- data.frame(Name="RandomForest", RMSE=wmd$m1$results$RMSE, Rsquared=wmd$m1$results$Rsquared)
dtreew <- data.frame(Name="DecisionTree", RMSE=wmd$m2$results$RMSE, Rsquared=wmd$m2$results$Rsquared)
linearregw <- data.frame(Name="LM",RMSE=wmd$m3$results$RMSE, Rsquared=wmd$m3$results$Rsquared)

rbind(svmw, rforestw, dtreew, linearregw)



#First calculates the number of M/R rounds for each job.
#This is based on the number of task and the number of containers
#The framework may launch all the containers sometimes few. So we are 
#taking an average here. This cluster is configured to run 1 container per
#host so making it a total of 8 contianers but we are going for 4 containers. 
runPrediction <- function(data, maponly=0){
  #read <- predict(rmd$model, data) * 4
  MAX_RUNNING_CONTAINERS = 8
  customred = 0;
  read <- (data$Mappers/MAX_RUNNING_CONTAINERS) * 1024
  collect <- (data$Mappers/MAX_RUNNING_CONTAINERS) * predict(cmd$model, data)
  if(collect < 0) 
    collect = 0
  spill <- (data$Mappers/MAX_RUNNING_CONTAINERS) * predict(smd$model, data)
  merge <- (data$Mappers/MAX_RUNNING_CONTAINERS) * predict(mmd$model, data)
  shuffle <- predict(shmd$model, data)
  write <- predict(wmd$model, data)
  
  if(data$NumOfReducers > MAX_RUNNING_CONTAINERS){
    shuffle <-  (data$NumOfReducers/MAX_RUNNING_CONTAINERS) * predict(shmd$model, data)
    write <-  (data$NumOfReducers/MAX_RUNNING_CONTAINERS) * predict(wmd$model, data)
  }
  
  
  if(data$Mappers > 0){
    custommap <- (data$MapTime)/(data$Mappers/MAX_RUNNING_CONTAINERS)
  }
  if(data$NumOfReducers > 0){
    customred <- (data$ReduceTime)/(data$NumOfReducers)
  }
  
  if(maponly == 1){
    totaltime <- (read+collect+spill+merge+write+custommap)/1000
  }else{
    totaltime <- (read+collect+spill+merge+shuffle+write+custommap+customred)/1000
  }
  
  return (list("totaltime"=totaltime, "read"=read, "spill"=spill, "collect"=collect, "merge"=merge, "shuffle"=shuffle, "write"=write, "custommap"=custommap, "customred"=customred))
}

minmaxcount.log  <- data.frame(DataSize=16000, BlockSize=128, MapSelectivity=12, MapSelectivityData=15, Mappers=131, NumOfReducers=1, shuffleData=371, MapTime=465466, ReduceTime=55343)
top10.log  <- data.frame(DataSize=2755, BlockSize=128, MapSelectivity=1, MapSelectivityData=1, Mappers=22, NumOfReducers=1, shuffleData=1, MapTime=56629, ReduceTime=94)
leftouter.log  <- data.frame(DataSize=19000, BlockSize=128, MapSelectivity=103, MapSelectivityData=123, Mappers=163, NumOfReducers=18, shuffleData=20224, MapTime=632457, ReduceTime=5459050)
inner.log  <- data.frame(DataSize=19000, BlockSize=128, MapSelectivity=103, MapSelectivityData=131, Mappers=153, NumOfReducers=11, shuffleData=20224, MapTime=631384, ReduceTime=3148833)
qanda.log  <- data.frame(DataSize=30000, BlockSize=128, MapSelectivity=103, MapSelectivityData=131, Mappers=225, NumOfReducers=11, shuffleData=29722, MapTime=801975, ReduceTime=7318167)
invertedindex.log  <- data.frame(DataSize=12000, BlockSize=128, MapSelectivity=3, MapSelectivityData=4, Mappers=94, NumOfReducers=10, shuffleData=56, MapTime=240282, ReduceTime=14110)
fullouter.log  <- data.frame(DataSize=19000, BlockSize=128, MapSelectivity=103, MapSelectivityData=131, Mappers=153, NumOfReducers=11, shuffleData=20224, MapTime=623718, ReduceTime=2328480)
totalorder.log  <- data.frame(DataSize=2755, BlockSize=128, MapSelectivity=98, MapSelectivityData=98, Mappers=31, NumOfReducers=11, shuffleData=3069, MapTime=93046, ReduceTime=240370)
rightouter.log  <- data.frame(DataSize=19000, BlockSize=128, MapSelectivity=103, MapSelectivityData=110, Mappers=182, NumOfReducers=25, shuffleData=20224, MapTime=665268, ReduceTime=7476268)
distinct.log  <- data.frame(DataSize=16000, BlockSize=128, MapSelectivity=3, MapSelectivityData=4, Mappers=131, NumOfReducers=4, shuffleData=106, MapTime=287975, ReduceTime=11587)
grep.log  <- data.frame(DataSize=12000, BlockSize=128, MapSelectivity=0, MapSelectivityData=0, Mappers=94, NumOfReducers=4, shuffleData=11, MapTime=538574, ReduceTime=1384437)
shuffling.log  <- data.frame(DataSize=2755, BlockSize=128, MapSelectivity=93, MapSelectivityData=118, Mappers=22, NumOfReducers=4, shuffleData=2632, MapTime=118329, ReduceTime=69932)
average.log  <- data.frame(DataSize=16000, BlockSize=128, MapSelectivity=5, MapSelectivityData=6, Mappers=131, NumOfReducers=1, shuffleData=1, MapTime=469040, ReduceTime=22039)
median.log  <- data.frame(DataSize=16000, BlockSize=128, MapSelectivity=3, MapSelectivityData=4, Mappers=131, NumOfReducers=4, shuffleData=634, MapTime=470190, ReduceTime=50133)

runPrediction(minmaxcount.log)$totaltime
runPrediction(invertedindex.log)$totaltime
runPrediction(average.log)$totaltime
runPrediction(median.log)$totaltime
runPrediction(grep.log)$totaltime
runPrediction(top10.log)$totaltime
runPrediction(distinct.log)$totaltime
runPrediction(qanda.log)$totaltime
runPrediction(totalorder.log)$totaltime
runPrediction(shuffling.log)$totaltime
runPrediction(inner.log)$totaltime
runPrediction(leftouter.log)$totaltime
runPrediction(rightouter.log)$totaltime
runPrediction(fullouter.log)$totaltime


library(reshape2)

expdata <- read.csv(file = "experiment8node.csv", header = TRUE)
expdata1 <- read.csv(file = "experiment.csv", header = TRUE)
#expdata <- melt(expdata, id=c("Algorithm") 
expdata
expdata1

expdataS <- filter(expdata, Pattern=="Summerisation")
expdataF <- filter(expdata, Pattern=="Filtering")
expdataDO <- filter(expdata, Pattern=="Data Organisation")
expdataJ <- filter(expdata, Pattern=="Join")

expdataS1 <- filter(expdata1, Pattern=="Summerisation")
expdataF1 <- filter(expdata1, Pattern=="Filtering")
expdataDO1 <- filter(expdata1, Pattern=="Data Organisation")
expdataJ1 <- filter(expdata1, Pattern=="Join")



plotExperimentGraph <- function(data,title,start=4){
  expmelt <- select(data, Algorithm,Predicted,Actual)
  expmelt <- melt(expmelt, id="Algorithm")
  for (i in 1:nrow(expmelt)) {#len 8
    if(expmelt$variable[i] == "Actual"){
      expmelt$MeanErr[i] <- data$MeanErr[i-start]
    }else{
      expmelt$MeanErr[i] <- NA
    }
  }
  
  
  
  expmelt
  
  ggplot(expmelt, aes(x=Algorithm, y=value, fill=factor(variable)))+
    xlab("Algorithm") +
    ylab("Time(s)")+
    ggtitle(title)+
    geom_bar(position="dodge", stat="identity")+
    theme(legend.position = "left", plot.title = element_text(size = 12, face = "bold"), axis.text.y=element_text(size=11, face = "bold"),
          axis.title=element_text(size=12,face="bold"), axis.text.x = element_text(size = 11, face = "bold", angle = 45, hjust = 1), 
          legend.text=element_text(size=9, face = "bold"), text = element_text(size=9, face = "bold")) + guides(fill=guide_legend(title=""))
   
}

p1<-plotExperimentGraph(expdataS,"8 Node")
p2<-plotExperimentGraph(expdataS1, "Single Node")
ggarrange(p1,p2, ncol=2, nrow=1, common.legend = TRUE, legend = "bottom")

p3<-plotExperimentGraph(expdataF,"8 Node", start = 3)
p4<-plotExperimentGraph(expdataF1,"Single Node", start = 3)
ggarrange(p3,p4, ncol=2, nrow=1, common.legend = TRUE, legend = "bottom")

p5<-plotExperimentGraph(expdataDO,"8 Node", start = 3)
p6<-plotExperimentGraph(expdataDO1, "Single Node", start = 3)
ggarrange(p5,p6, ncol=2, nrow=1, common.legend = TRUE, legend = "bottom")

p7<-plotExperimentGraph(expdataJ,"8 Node", start=4)
p8<-plotExperimentGraph(expdataJ1,"Single Node", start=4)
ggarrange(p7,p8, ncol=2, nrow=1, common.legend = TRUE, legend = "bottom")



plotExperimentGraph(expdata)
plotExperimentGraph(expdata1)





#Plot with error bars
# plotExperimentGraph <- function(data,title,start=4){
#   expmelt <- select(data, Algorithm,Predicted,Actual)
#   expmelt <- melt(expmelt, id="Algorithm")
#   for (i in 1:nrow(expmelt)) {#len 8
#     if(expmelt$variable[i] == "Actual"){
#       expmelt$MeanErr[i] <- data$MeanErr[i-start]
#     }else{
#       expmelt$MeanErr[i] <- NA
#     }
#   }
#   
#   
#   
#   expmelt
#   
#   ggplot(expmelt, aes(x=Algorithm, y=value, fill=factor(variable)))+
#     xlab("Algorithm") +
#     ylab("Time(s)")+
#     ggtitle(title)+
#     theme(plot.title = element_text(size = 12, face = "bold"), axis.text=element_text(size=9, face = "bold"),
#           axis.title=element_text(size=9,face="bold"))+
#     geom_bar(position="dodge", stat="identity")+
#     geom_errorbar(aes(ymin=value-MeanErr, ymax=value+MeanErr), width=.2,
#                   position=position_dodge(.9)) +
#     guides(fill=guide_legend(title="")) +
#     theme(legend.text=element_text(size=12), text = element_text(size=12))
# }





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

grid_arrange_shared_legend <- function(...) {
  plots <- list(...)
  g <- ggplotGrob(plots[[1]] + theme(legend.position="bottom"))$grobs
  legend <- g[[which(sapply(g, function(x) x$name) == "guide-box")]]
  lheight <- sum(legend$height)
  grid.arrange(
    do.call(arrangeGrob, lapply(plots, function(x)
      x + theme(legend.position="none"))),
    legend,
    ncol = 1,
    top = "ABC",
    heights = unit.c(unit(1, "npc") - lheight, lheight))
}