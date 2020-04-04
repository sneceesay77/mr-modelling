package bdl.standrews.ac.uk;

import java.io.*;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class DistributedGrep {
	private static final Logger LOG = LoggerFactory.getLogger(DistributedGrep.class.getName());

	public static enum MAP_RED_CUSTOM {
		MAP_TIME_MILLIS,
		REDUCE_TIME_MILLIS
	};

	public static class GrepMapper extends Mapper<Object, Text, Text, IntWritable> {

		public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			String txt = value.toString();
			String mapRegex = context.getConfiguration().get("mapregex");

			if (txt.matches(mapRegex)) {
				context.write(value, new IntWritable(1));
			}
			long endTime = System.currentTimeMillis();
			long totalTime = endTime - startTime;
			context.getCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).increment(totalTime);
		}
	}

	public static class GrepReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
		long startTime = System.currentTimeMillis();
		private IntWritable result = new IntWritable();

		public void reduce(Text key, Iterable<IntWritable> values, Context context)
				throws IOException, InterruptedException {
			int sum = 0;
			for (IntWritable val : values) {
				sum += val.get();
			}
			result.set(sum);
			context.write(key, result);
			long endTime = System.currentTimeMillis();
			long totalTime = endTime - startTime;
			context.getCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).increment(totalTime);
		}
	}

	public static void main(String[] args) throws Exception {
		Configuration conf = new Configuration();
		String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
		if (otherArgs.length != 3) {
			System.err.println("Usage: DistributedGrep <regex> <in> <out>");
			System.exit(2);
		}
		conf.set("mapregex", otherArgs[0]);

		Job job = Job.getInstance(conf, "Distributed Grep");
		job.setJarByClass(DistributedGrep.class);
		job.setMapperClass(GrepMapper.class);
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(Text.class);
		job.setReducerClass(GrepReducer.class);
	    job.setOutputValueClass(IntWritable.class);
	    job.setNumReduceTasks(4);
		//job.setNumReduceTasks(0); // Set number of reducers to zero
		FileInputFormat.addInputPath(job, new Path(otherArgs[1]));
		FileOutputFormat.setOutputPath(job, new Path(otherArgs[2]));
		System.exit(job.waitForCompletion(true) ? 0 : 1);
		Counters counters = job.getCounters();
		LOG.info("MAPTIME", counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
		System.out.println("MAPTIME " + counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
	}
}
