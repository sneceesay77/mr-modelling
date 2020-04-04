#!/bin/bash
echo "Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize" > readData.csv
echo "Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize" > writeData.csv
echo "Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize" > shuffleData.csv
echo "Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize" > collectData.csv
echo "Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize" > spillData.csv
echo "Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize" > mergeData.csv
cat allOut.csv | grep read_SC >> readData.csv
cat allOut.csv | grep write_SC >> writeData.csv
cat allOut.csv | grep shuffle_SC >> shuffleData.csv
cat allOut.csv | grep collect_SC >> collectData.csv
cat allOut.csv | grep spill_SC >> spillData.csv
cat allOut.csv | grep merge_SC >> mergeData.csv

