package bdl.standrews.ac.uk;

import java.io.IOException;
import java.util.Map;
import java.util.TreeMap;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;



public class TopTenDriver {

	private static final Logger LOG = LoggerFactory.getLogger(TopTenDriver.class.getName());
	public static enum MAP_RED_CUSTOM {
		MAP_TIME_MILLIS,
		REDUCE_TIME_MILLIS
	};
	public static class SOTopTenMapper extends
			Mapper<Object, Text, NullWritable, Text> {
		
		// Our output key and value Writables
		private TreeMap<Integer, Text> repToRecordMap = new TreeMap<Integer, Text>();

		@Override
		public void map(Object key, Text value, Context context)
				throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			// Parse the input string into a nice map
			Map<String, String> parsed = MRDPUtils.transformXmlToMap(value
					.toString());
			if (parsed == null) {
				return;
			}

			String userId = parsed.get("Id");
			String reputation = parsed.get("Reputation");

			// Get will return null if the key is not there
			if (userId == null || reputation == null) {
				// skip this record
				return;
			}

			repToRecordMap.put(Integer.parseInt(reputation), new Text(value));

			if (repToRecordMap.size() > 50) {
				repToRecordMap.remove(repToRecordMap.firstKey());
			}
			long endTime = System.currentTimeMillis();
			long totalTime = endTime-startTime;
			context.getCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).increment(totalTime);
		}

		@Override
		protected void cleanup(Context context) throws IOException,
				InterruptedException {
			for (Text t : repToRecordMap.values()) {
				context.write(NullWritable.get(), t);
			}
		}
	}

	public static class SOTopTenReducer extends
			Reducer<NullWritable, Text, NullWritable, Text> {

		private TreeMap<Integer, Text> repToRecordMap = new TreeMap<Integer, Text>();

		@Override
		public void reduce(NullWritable key, Iterable<Text> values,
				Context context) throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			for (Text value : values) {
				Map<String, String> parsed = MRDPUtils.transformXmlToMap(value
						.toString());

				repToRecordMap.put(Integer.parseInt(parsed.get("Reputation")),
						new Text(value));

				if (repToRecordMap.size() > 50) {
					repToRecordMap.remove(repToRecordMap.firstKey());
				}
			}

			for (Text t : repToRecordMap.descendingMap().values()) {
				context.write(NullWritable.get(), t);
			}
			long endTime = System.currentTimeMillis();
			long totalTime = endTime-startTime;
			context.getCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).increment(totalTime);
		}
	}

	public static void main(String[] args) throws Exception {
		Configuration conf = new Configuration();
		String[] otherArgs = new GenericOptionsParser(conf, args)
				.getRemainingArgs();
		if (otherArgs.length != 2) {
			System.err.println("Usage: TopTenDriver <in> <out>");
			System.exit(2);
		}

		Job job =  Job.getInstance(conf, "Top Ten Users by Reputation");
		job.setJarByClass(TopTenDriver.class);
		job.setMapperClass(SOTopTenMapper.class);
		job.setReducerClass(SOTopTenReducer.class);
		job.setNumReduceTasks(1);
		job.setOutputKeyClass(NullWritable.class);
		job.setOutputValueClass(Text.class);
		FileInputFormat.addInputPath(job, new Path(otherArgs[0]));
		FileOutputFormat.setOutputPath(job, new Path(otherArgs[1]));
		System.exit(job.waitForCompletion(true) ? 0 : 1);
		Counters counters = job.getCounters();
		LOG.info("MAPTIME", counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
		LOG.info("REDTIME", counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());
		System.out.println("MAPTIME "+counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
		System.out.println("REDTIME "+counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());
	}
}
