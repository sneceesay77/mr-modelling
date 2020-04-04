package bdl.standrews.ac.uk;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

import org.apache.commons.lang.StringEscapeUtils;

public class MRDPUtils {
	// This helper function parses the stackoverflow into a Map for us.
	public static Map<String, String> transformXmlToMap(String xml) {
		Map<String, String> map = new HashMap<String, String>();
		try {
			// exploit the fact that splitting on double quote
			// tokenizes the data nicely for us
			String[] tokens = xml.trim().substring(5, xml.trim().length() - 3).split("\"");
			for (int i = 0; i < tokens.length - 1; i += 2) {
				String key = tokens[i].trim();
				String val = tokens[i + 1];
				map.put(key.substring(0, key.length() - 1), val);
			}
		} catch (StringIndexOutOfBoundsException e) {

		}
		return map;
	}
	
	public static void main(String[] args) throws FileNotFoundException {
		Scanner in = new Scanner(new File("SOinput/post.xml"));
		while(in.hasNextLine()){
			String line = in.nextLine();
			System.out.println(line);
//			Map<String, String> mp = transformXmlToMap(line);
//			for(Map.Entry<String, String> m : mp.entrySet()){
//				System.out.println(m.getKey()+"\t"+m.getValue());
//			}
		}
		in.close();
		
	}
}
