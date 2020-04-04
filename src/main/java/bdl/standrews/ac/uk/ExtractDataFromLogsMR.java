package bdl.standrews.ac.uk;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Scanner;




public class ExtractDataFromLogsMR {
	
	public static final int SPLIT_SIZE = 128;
	
	public void readReduceData(){
		
	}
	
	public void transformReduceLogs(String fileName, PrintWriter out) throws FileNotFoundException{
		Scanner in = new Scanner(new FileInputStream(fileName));
		
		ArrayList<String> firstReducer = new ArrayList<String>();
		ArrayList<String> secondReducer = new ArrayList<String>();
		ArrayList<Integer> elapsedTime = new ArrayList<Integer>();
		
		in.nextLine(); //Skip first line
		int mapSelectivity = 0;
		out.println("Transformed Data");
		
		int seen = 0;
		while(in.hasNextLine()){
			String line = in.nextLine().trim();
			String operation = "Map Phase";
			//59
			//Map input records=1342177
			//Map output records=1342177
			//MAP_TIME_MILLIS=5698
			if(line.trim().length() > 10){
				
				String parts[] = line.split("=");
				if(parts[0].equalsIgnoreCase("Reduce input records") && seen == 0){
					firstReducer.add(line.trim());
					firstReducer.add(in.nextLine().trim());
					seen++;
				}else if(parts[0].equalsIgnoreCase("Reduce input records")){
					secondReducer.add(line.trim());
					secondReducer.add(in.nextLine().trim());
				}else if(parts[0].equalsIgnoreCase("REDUCE_TIME_MILLIS")){
					elapsedTime.add(Integer.parseInt(parts[1]));
				}
				

				
			}else if(line.trim().length() < 10 && elapsedTime.size() > 0){
				Collections.sort(elapsedTime);
				int sum  = 0;
				for(int i = 0; i < elapsedTime.size()-2; i++){
					sum+=elapsedTime.get(i);
				}
				long timeTaken = sum/2;
				
//				for(Integer i : elapsedTime){
//					System.out.println(i);
//				}
				int size = elapsedTime.size();
				out.println(size);
				out.println("REDUCE_TIME_MILLIS="+((elapsedTime.get(size - 1))+timeTaken));
				for(String i : firstReducer){
					out.println(i);
				}
				out.println("REDUCE_TIME_MILLIS="+((elapsedTime.get(size - 2))+timeTaken));
				for(String j : secondReducer){
					out.println(j);
				}
				seen = 0;
				//System.out.println("----------------------------------------------");
				firstReducer = new ArrayList<String>();
				secondReducer = new ArrayList<String>();
				elapsedTime = new ArrayList<Integer>();
			}else if(mapSelectivity < 100){
				//System.out.println("Incremnting MapSelectivity");
				mapSelectivity+=10;
			}
			
		}
		Collections.sort(elapsedTime);
		int sum  = 0;
		for(int i = 0; i < elapsedTime.size()-2; i++){
			sum+=elapsedTime.get(i);
		}
		long timeTaken = sum/2;
		int size = elapsedTime.size();
		out.println(size);
		out.println("REDUCE_TIME_MILLIS="+((elapsedTime.get(size - 1))+timeTaken));
		for(String i : firstReducer){
			out.println(i);
		}
		out.println("REDUCE_TIME_MILLIS="+((elapsedTime.get(size - 1))+timeTaken));
		for(String j : secondReducer){
			out.println(j);
		}
		in.close();
		

	}

	public void readData(String fileName, PrintWriter out) throws FileNotFoundException{
		Scanner in = new Scanner(new FileInputStream(fileName));
		
		in.nextLine(); //Skip first line
		int mapSelectivity = 0;
		System.out.println("Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize");
		int lineCount = 0;
		long mapInputRecords = 0, mapOutputRecords = 0, duration = 0;
		while(in.hasNextLine()){
			String line = in.nextLine().trim();
			String operation = "Reduce Phase";
			//59
			//Map input records=1342177
			//Map output records=1342177
			//MAP_TIME_MILLIS=5698
			if(line.trim().length() > 10){
				String parts[] = line.split("=");
				if(parts[0].equalsIgnoreCase("Map input records") || parts[0].equalsIgnoreCase("Reduce input records")){
					mapInputRecords = Long.parseLong(parts[1]);
				}else if(parts[0].equalsIgnoreCase("Map Output records") || parts[0].equalsIgnoreCase("Reduce Output records")){
					mapOutputRecords = Long.parseLong(parts[1]);
				}else if(parts[0].equalsIgnoreCase("MAP_TIME_MILLIS") || parts[0].equalsIgnoreCase("REDUCE_TIME_MILLIS")){
					duration = Long.parseLong(parts[1]);
				}
	
				int inputDataSize = getTotalInputData(fileName);
				
				
				int numberOfMappers = getNumberOfMappers(fileName, SPLIT_SIZE);
				
				if(lineCount == 2){
//				System.out.println(operation+","+duration +","+mapSelectivity+","+mapInputRecords+","+mapOutputRecords+","+
//				numberOfMappers+","+inputDataSize);
				out.println(operation+","+duration +","+mapSelectivity+","+mapInputRecords+","+mapOutputRecords+","+numberOfMappers+","+inputDataSize);
				 lineCount = 0;
				 
				}else{
					lineCount++;
				}
				
			}else if(mapSelectivity < 100){
				System.out.println("Incremnting MapSelectivity");
				mapSelectivity+=10;
			}
			
		}
		in.close();
		

	}
	
	public int getTotalInputData(String f) throws NumberFormatException{
		//String fileName = f.split("/")[1].replaceAll("MR", "");
		//File name following this format reducedata/out/filenameMR.txt
		String fileName = f.split("/")[2].replaceAll("MR", "");
		//System.out.println(fileName);
		return Integer.parseInt(fileName.split("\\.")[0].substring(4, fileName.split("\\.")[0].length()));
	}
	
	public int getTotalDataProcessed(long fileSize, double mapSelectivity){
		return (int) (fileSize * mapSelectivity);
	}
	
	public long getMapInputRecord(long fileSize){
		return (fileSize * 1048576L)/100;
	}
	
	public long getMapOutputRecord(long fileSize, double mapSelectivity){
		return (long)(getMapInputRecord(fileSize) * (mapSelectivity/100));
	}
	
	public int getNumberOfMappers(String fileName, int splitSize){
		return (int)Math.ceil((double)getTotalInputData(fileName)/splitSize);
	}
	
	public int getNumberOfReducers(){
		return 2;
	}
	
	
	public static void main(String args[]) throws FileNotFoundException{
		PrintWriter out = null;
		PrintWriter outFinal = new PrintWriter(new File("reducedata/out/allOut.csv"));
		outFinal.println("Operation,Duration,MapSelectivity,RedInputRec,RedOutputRec,Reducers,DataSize");
		ExtractDataFromLogsMR dataFromLogs = new ExtractDataFromLogsMR();
		//System.out.println(dataFromLogs.getTotalDataProcessed(args[0], 0.1)* 1048576);
		for(int i=0; i<args.length; i++){
			//out = new PrintWriter(new File("reducedata/out/"+args[i]));
			//dataFromLogs.transformReduceLogs("reducedata/"+args[i], out);
			//out.close();
		}
		
		for(int i=0; i<args.length; i++){
			dataFromLogs.readData("reducedata/out/"+args[i], outFinal);
		}
		outFinal.close();
		
		
	}
	


}
