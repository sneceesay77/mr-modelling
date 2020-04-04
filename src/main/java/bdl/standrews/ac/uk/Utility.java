package bdl.standrews.ac.uk;

import java.util.Random;

public class Utility {
	
	public static long getNumberOfRows(int splitSize){
		//1048576 bytes = 1 MB
		long sizeToBytes = splitSize * 1048576;
		long numRows = (int)sizeToBytes/100;
		return numRows;
	}
	
	public static int getTotalInputData(String fileName){
		return Integer.parseInt(fileName.split("\\.")[0].substring(4, fileName.split("\\.")[0].length()));
	}
	
	
	public static long getMapInputRecord(String fileSize){
		return (getTotalInputData(fileSize) * 1048576)/100;
	}
	
	public static long getMapOutputRecord(String fileSize, double mapSelectivity){
		return (long)(getMapInputRecord(fileSize) * (mapSelectivity/100));
	}
	
	public static void add(int a, int b) throws InterruptedException{
		//long start = System.currentTimeMillis();
		Thread.sleep(1000);
		//long end = System.currentTimeMillis();
		//System.out.println(end-start);
	}
	
	public static void generateMathSheet(int numberOfQuestions, String sign){
		Random r = new Random();
		for(int i =0; i<numberOfQuestions; i++){
			int high = 100;
			int low = 10;
			int firstNumber = r.nextInt(high-low)+low;
			int secondNumber = r.nextInt(low-1)+1;
			System.out.println(firstNumber+"  "+sign+"  "+secondNumber +"  = ");
		}
	}
	
	
	
	public static void main(String[] args) throws InterruptedException {
		
		//System.out.println(Utility.getNumberOfRows(64));
//		System.out.println(getTotalInputData("logs2048.txt"));
//		
//		System.out.println(getMapInputRecord("2048"));
		
//		long start = System.currentTimeMillis();
//		add(78999,89999);
//		System.out.println((long)System.currentTimeMillis() - start);
		
		generateMathSheet(20, "+");
	}

}
