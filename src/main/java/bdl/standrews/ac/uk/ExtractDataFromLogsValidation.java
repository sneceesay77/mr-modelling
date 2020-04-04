package bdl.standrews.ac.uk;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

public class ExtractDataFromLogsValidation {
	
	public static final long ONE_MEGABYTE = 1048576;
	

	public HashMap<String, String> logToMap(String fileName) throws FileNotFoundException{
		Scanner in = new Scanner(new FileInputStream(fileName));
		
		HashMap<String, String> hm = new HashMap<String, String>();
		while(in.hasNextLine()){
			String line = in.nextLine();
			String[] keyval = line.split("=");
			if(keyval.length == 2){
				String key = keyval[0].trim();
				String value = keyval[1].trim();
				hm.put(key, value);
			}
			
			
		}
		in.close();	
		return hm;
	}
	
	/**
	 * These methods are calculated per tasks based. So we are getting the total log summary of a job and decomposed
	 * it to a single task configuration. Which we can use in our formulas and models to approximate the time it will take
	 * this job for a cluster.
	 * */
	
	public long getNumberOfMappers(HashMap<String, String> hm){
		return Long.parseLong(hm.get("Launched map tasks"));
	}
	
	public  int getNumberOfReducers(HashMap<String, String> hm){
		return Integer.parseInt(hm.get("Launched reduce tasks"));
	}
	
	//equivalent to block size
	public  long getInputDataDataSizePerMapper(HashMap<String, String> hm){
		String value = hm.get("HDFS: Number of bytes read");
		long inputSize = (Long.parseLong(value)/ONE_MEGABYTE)/getNumberOfMappers(hm);
		return inputSize;
	}
	
	public  double getOutputDataSizePerMapper(HashMap<String, String> hm){
		String value = hm.get("Map output bytes");
		double mapOutputMB = (Double.parseDouble(value)/ONE_MEGABYTE)/getNumberOfMappers(hm);
		return mapOutputMB;
	}
	
//	public  double getShuffledDataToEachReducer(HashMap<String, String> hm, double mapInput, double mapOutput){
//		long totalMaps = getNumberOfMappers(hm);
//		double totalReducers = getNumberOfReducers(hm);
//		//System.out.println("----"+mapInput+" "+(getMapSelectivity(mapInput,mapOutput))/100+"--"+totalMaps);
//		return ((mapInput * (getMapSelectivity(mapInput,mapOutput)/100) * totalMaps)/totalReducers);
//	}
	
	public  double getShuffledDataToEachReducer(HashMap<String, String> hm){
		String value = hm.get("Reduce shuffle bytes");
		double shuffleSize = (Double.parseDouble(value)/ONE_MEGABYTE);
		return shuffleSize;
	}
	
	public long getInputRecord(HashMap<String, String> hm, String key){
		return Long.parseLong(hm.get(key));
	}
	
	

	
	public double getMapSelectivity(double mapInput, double mapOutput){
		
		double ratio = mapOutput/mapInput;
		//System.out.println(mapOutput+"---"+mapInput+"--"+ratio);
		return ratio * 100.0;
	}
	
	public long getMapTime(HashMap<String, String> hm){
		return Long.parseLong(hm.get("MAP_TIME_MILLIS"));
	}
	
	public long getReduceTime(HashMap<String, String> hm){
		return Long.parseLong(hm.get("REDUCE_TIME_MILLIS"));
	}
	
	
	public static void main(String args[]) throws FileNotFoundException{
		ExtractDataFromLogsValidation ext = new ExtractDataFromLogsValidation();
		HashMap<String, String> hm = new HashMap<String, String>();
		hm = ext.logToMap("validationlogs/fullouter1.log");
		
		double mapInput = ext.getInputDataDataSizePerMapper(hm);
		double mapOutput = ext.getOutputDataSizePerMapper(hm);
		
		//StringBuilder sb = new StringBuilder();
		
		long inputDataSize = ext.getInputDataDataSizePerMapper(hm);
		double outputDataSize = ext.getOutputDataSizePerMapper(hm);
		long shuffledData =  Math.round(ext.getShuffledDataToEachReducer(hm));
		double mapSelectivity = ext.getMapSelectivity(mapInput, mapOutput);
		long numberOfMappers = ext.getNumberOfMappers(hm);
		long numberOfReducers = ext.getNumberOfReducers(hm);
		
		//System.out.println("MapInput,MapOutput,ShuffleData,MapSelectivity,NumMappers,NumReducers");
		System.out.println("MapInput : "+inputDataSize+"\nMapOutput : "+outputDataSize+"\nShuffleData : "+shuffledData+"\n"
				+ "MapSelectivity : "+mapSelectivity+"\nNumber of Mappers : "+numberOfMappers+"\n"
						+ "Number of Reducers : "+numberOfReducers+"\n"
								+ "Map Input Record : "+ext.getInputRecord(hm, "Map input records")
										+ "\nReduce Input Record : "+ext.getInputRecord(hm, "Reduce input records")
												+ "\nMapTime : "+ext.getMapTime(hm)+""
														+ "\nReduce Time : "+ext.getReduceTime(hm));


		
//		System.out.println(ext.getInputDataDataSizePerMapper(hm));
//		System.out.println(ext.getOutputDataSizePerMapper(hm));
//		System.out.println(Math.round(ext.getShuffledDataToEachReducer(hm, mapInput, mapOutput)));
//		System.out.println(Math.round(ext.getMapSelectivity(mapInput, mapOutput)));
//		System.out.println(ext.getNumberOfMappers(hm));
//		System.out.println(ext.getNumberOfReducers(hm));
		
//		for(Map.Entry<String, String> a : hm.entrySet()){
//			System.out.println(a.getKey());
//		}
		
		
	}
	


}
