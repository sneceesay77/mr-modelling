package bdl.standrews.ac.uk;

import java.io.IOException;
import java.util.Map;


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

import bdl.standrews.ac.uk.TopTenDriver.MAP_RED_CUSTOM;

public class DistinctUserDriver {
	private static final Logger LOG = LoggerFactory.getLogger(DistinctUserDriver.class.getName());
	public static enum MAP_RED_CUSTOM {
		MAP_TIME_MILLIS,
		REDUCE_TIME_MILLIS
	};
	public static class SODistinctUserMapper extends
			Mapper<Object, Text, Text, NullWritable> {

		private Text outUserId = new Text();

		@Override
		public void map(Object key, Text value, Context context)
				throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			// Parse the input into a nice map.
			Map<String, String> parsed = MRDPUtils.transformXmlToMap(value.toString());

			// Get the value for the UserId attribute
			String userId = parsed.get("UserId");

			// If it is null, skip this record
			if (userId == null) {
				return;
			}

			// Otherwise, set our output key to the user's id
			outUserId.set(userId);

			// Write the user's id with a null value
			context.write(outUserId, NullWritable.get());
			long endTime = System.currentTimeMillis();
			long totalTime = endTime-startTime;
			context.getCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).increment(totalTime);
		}
	}

	public static class SODistinctUserReducer extends
			Reducer<Text, NullWritable, Text, NullWritable> {

		@Override
		public void reduce(Text key, Iterable<NullWritable> values,
				Context context) throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			// Write the user's id with a null value
			context.write(key, NullWritable.get());
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
			System.err.println("Usage: UniqueUserCount <in> <out>");
			System.exit(2);
		}

		Job job = Job.getInstance(conf, "StackOverflow Distinct Users");
		job.setJarByClass(DistinctUserDriver.class);
		job.setMapperClass(SODistinctUserMapper.class);
		job.setCombinerClass(SODistinctUserReducer.class);
		job.setReducerClass(SODistinctUserReducer.class);
		job.setOutputKeyClass(Text.class);
		job.setNumReduceTasks(4);
		job.setOutputValueClass(NullWritable.class);
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
