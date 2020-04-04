package bdl.standrews.ac.uk;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Map;
import java.util.Scanner;

import org.apache.commons.lang.StringEscapeUtils;
import org.apache.hadoop.io.Text;



public class TestInvertedIndex {
	public static String getWikipediaURL(String text) {

		int idx = text.indexOf("\"http://en.wikipedia.org");
		if (idx == -1) {
			return null;
		}
		int idx_end = text.indexOf('"', idx + 1);

		if (idx_end == -1) {
			return null;
		}

		int idx_hash = text.indexOf('#', idx + 1);

		if (idx_hash != -1 && idx_hash < idx_end) {
			return text.substring(idx + 1, idx_hash);
		} else {
			return text.substring(idx + 1, idx_end);
		}

	}
	
	public static void main(String[] args) throws FileNotFoundException {
		// Parse the input string into a nice map
					
					Scanner in = new Scanner(new File("test.xml"));
					Map<String, String> parsed = null;
					while(in.hasNextLine()){
						Text link = new Text();
						parsed = MRDPUtils.transformXmlToMap(in.nextLine());
						// Grab the necessary XML attributes
						String txt = parsed.get("Body");
						String posttype = parsed.get("PostTypeId");
						String row_id = parsed.get("Id");
						
						if (txt == null || (posttype != null && posttype.equals("1"))) {
							continue;
						}
						
						txt = StringEscapeUtils.unescapeHtml(txt.toLowerCase());
						
						System.out.println(getWikipediaURL(txt));
					}
					

					
	}


}
