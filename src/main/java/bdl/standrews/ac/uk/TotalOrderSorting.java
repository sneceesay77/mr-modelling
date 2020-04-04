package bdl.standrews.ac.uk;

import java.io.IOException;
import java.util.Map;


import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.mapreduce.lib.partition.InputSampler;
import org.apache.hadoop.mapreduce.lib.partition.TotalOrderPartitioner;
import org.apache.hadoop.util.GenericOptionsParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class TotalOrderSorting {
	private static final Logger LOG = LoggerFactory.getLogger(TotalOrderSorting.class.getName());
	public static enum MAP_RED_CUSTOM {
		MAP_TIME_MILLIS,
		REDUCE_TIME_MILLIS
	};

	public static class LastAccessDateMapper extends
			Mapper<Object, Text, Text, Text> {

		private Text outkey = new Text();

		@Override
		public void map(Object key, Text value, Context context)
				throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			// Parse the input string into a nice map
			Map<String, String> parsed = MRDPUtils.transformXmlToMap(value
					.toString());

			String date = parsed.get("LastAccessDate");
			if (date != null) {
				outkey.set(date);
				context.write(outkey, value);
			}
			long endTime = System.currentTimeMillis();
			long totalTime = endTime-startTime;
			context.getCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).increment(totalTime);
		}
	}

	public static class ValueReducer extends
			Reducer<Text, Text, Text, NullWritable> {
		
		@Override
		public void reduce(Text key, Iterable<Text> values, Context context)
				throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			for (Text t : values) {
				context.write(t, NullWritable.get());
			}
			long endTime = System.currentTimeMillis();
			long totalTime = endTime-startTime;
			context.getCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).increment(totalTime);
			
		}
		
	}

	@SuppressWarnings({ "unchecked", "rawtypes" })
	public static void main(String[] args) throws Exception {
		Configuration conf = new Configuration();
		String[] otherArgs = new GenericOptionsParser(conf, args)
				.getRemainingArgs();
		if (otherArgs.length != 3) {
			System.err
					.println("Usage: TotalOrderSorting <user data> <out> <sample rate>");
			System.exit(1);
		}

		Path inputPath = new Path(otherArgs[0]);
		Path partitionFile = new Path(otherArgs[1] + "_partitions.lst");
		Path outputStage = new Path(otherArgs[1] + "_staging");
		Path outputOrder = new Path(otherArgs[1]);
		double sampleRate = Double.parseDouble(otherArgs[2]);

		FileSystem.get(new Configuration()).delete(outputOrder, true);
		FileSystem.get(new Configuration()).delete(outputStage, true);
		FileSystem.get(new Configuration()).delete(partitionFile, true);

		// Configure job to prepare for sampling
		Job sampleJob = Job.getInstance(conf, "TotalOrderSortingStage");
		sampleJob.setJarByClass(TotalOrderSorting.class);

		// Use the mapper implementation with zero reduce tasks
		sampleJob.setMapperClass(LastAccessDateMapper.class);
		sampleJob.setNumReduceTasks(0);

		sampleJob.setOutputKeyClass(Text.class);
		sampleJob.setOutputValueClass(Text.class);

		TextInputFormat.setInputPaths(sampleJob, inputPath);

		// Set the output format to a sequence file
		sampleJob.setOutputFormatClass(SequenceFileOutputFormat.class);
		SequenceFileOutputFormat.setOutputPath(sampleJob, outputStage);

		// Submit the job and get completion code.
		int code = sampleJob.waitForCompletion(true) ? 0 : 1;
		Counters counters = sampleJob.getCounters();
		LOG.info("MAPTIME", counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
		LOG.info("REDTIME", counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());
		System.out.println("MAPTIME "+counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
		System.out.println("REDTIME "+counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());

		if (code == 0) {
			Job orderJob = Job.getInstance(conf, "TotalOrderSortingStage");
			orderJob.setJarByClass(TotalOrderSorting.class);

			// Here, use the identity mapper to output the key/value pairs in
			// the SequenceFile
			orderJob.setMapperClass(Mapper.class);
			orderJob.setReducerClass(ValueReducer.class);

			// Set the number of reduce tasks to an appropriate number for the
			// amount of data being sorted
			orderJob.setNumReduceTasks(10);

			// Use Hadoop's TotalOrderPartitioner class
			orderJob.setPartitionerClass(TotalOrderPartitioner.class);

			// Set the partition file
			TotalOrderPartitioner.setPartitionFile(orderJob.getConfiguration(),
					partitionFile);

			orderJob.setOutputKeyClass(Text.class);
			orderJob.setOutputValueClass(Text.class);
			orderJob.setNumReduceTasks(10);
			// Set the input to the previous job's output
			orderJob.setInputFormatClass(SequenceFileInputFormat.class);
			SequenceFileInputFormat.setInputPaths(orderJob, outputStage);

			// Set the output path to the command line parameter
			TextOutputFormat.setOutputPath(orderJob, outputOrder);

			// Set the separator to an empty string
			orderJob.getConfiguration().set(
					"mapred.textoutputformat.separator", "");

			// Use the InputSampler to go through the output of the previous
			// job, sample it, and create the partition file
			InputSampler.writePartitionFile(orderJob,
					new InputSampler.RandomSampler(sampleRate, 10000));

			// Submit the job
			code = orderJob.waitForCompletion(true) ? 0 : 2;
	
			LOG.info("MAPTIME", counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
			LOG.info("REDTIME", counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());
			System.out.println("MAPTIME "+counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
			System.out.println("REDTIME "+counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());
		}

		// Cleanup the partition file and the staging directory
		FileSystem.get(new Configuration()).delete(partitionFile, false);
		FileSystem.get(new Configuration()).delete(outputStage, true);

		System.exit(code);
	}
}
