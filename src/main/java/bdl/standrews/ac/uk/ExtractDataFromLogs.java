package bdl.standrews.ac.uk;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.util.Scanner;

public class ExtractDataFromLogs {
	
	public static final int SPLIT_SIZE = 128;
	

	public void readData(String fileName, PrintWriter out) throws FileNotFoundException{
		Scanner in = new Scanner(new FileInputStream(fileName));
		
		in.nextLine(); //Skip first line
		int mapSelectivity = 0;
		System.out.println("Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize,BlockSize");
		while(in.hasNextLine()){
			String line = in.nextLine().trim();
			
			if(line.trim().length() > 10){
				String parts[] = line.split(" ");
				String operation = parts[3];
				String duration = parts[4].split("=")[1];
				int inputDataSize = getTotalInputData(fileName);
				long mapInputRecords = getMapInputRecord(inputDataSize);
				long mapOutputRecords = getMapOutputRecord(inputDataSize, mapSelectivity);
				int numberOfMappers = getNumberOfMappers(fileName, SPLIT_SIZE);
				
				
				System.out.println(operation+","+duration +","+mapSelectivity+","+mapInputRecords+","+mapOutputRecords+","+
				numberOfMappers+","+inputDataSize+","+SPLIT_SIZE);
				out.println(operation+","+duration +","+mapSelectivity+","+mapInputRecords+","+mapOutputRecords+","+
						numberOfMappers+","+inputDataSize+","+SPLIT_SIZE);
			}else if(mapSelectivity < 100){
				mapSelectivity+=10;
			}
			
		}
		in.close();
		

	}
	
	public int getTotalInputData(String fileName) throws NumberFormatException{
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
		return getTotalInputData(fileName)/splitSize;
	}
	 
	public int getNumberOfReducers(){
		return 2;
	}
	
	
	public static void main(String args[]) throws FileNotFoundException{
		PrintWriter out = new PrintWriter(new File("allOut8Node.csv"));
		out.println("Operation,Duration,MapSelectivity,MapInputRec,MapOutputRec,Mappers,DataSize");
		ExtractDataFromLogs dataFromLogs = new ExtractDataFromLogs();
		//System.out.println(dataFromLogs.getTotalDataProcessed(args[0], 0.1)* 1048576);
		for(int i=0; i<args.length; i++){
			dataFromLogs.readData(args[i], out);
		}
		out.close();
		
		
	}
	


}
