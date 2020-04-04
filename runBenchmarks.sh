#!/bin/bash
dataSize=(500 750 1024 1536 2048 2560 3072 4096 4608 5120)
for i in "${dataSize[@]}"
do
   mapSelectivity=(0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1)
   for j in "${mapSelectivity[@]}"
   do
	echo $j
	#hadoop jar target/ClusterBenchmarking-0.0.1-SNAPSHOT.jar bdl.standrews.ac.uk.PlatformDefinedPhaseProfiler -D mapreduce.input.fileinputformat.split.maxsize=67108864 input$i output 64 $j  
   done
done
