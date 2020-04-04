package bdl.standrews.ac.uk;



import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;



public class AverageDriver {
	
	private static final Logger LOG = LoggerFactory.getLogger(AverageDriver.class.getName());
	public static enum MAP_RED_CUSTOM {
		MAP_TIME_MILLIS,
		REDUCE_TIME_MILLIS
	};
	public static class SOAverageMapper extends
			Mapper<Object, Text, IntWritable, CountAverageTuple> {

		private IntWritable outHour = new IntWritable();
		private CountAverageTuple outCountAverage = new CountAverageTuple();

		private final static SimpleDateFormat frmt = new SimpleDateFormat(
				"yyyy-MM-dd'T'HH:mm:ss.SSS");

		@SuppressWarnings("deprecation")
		@Override
		public void map(Object key, Text value, Context context)
				throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			// Parse the input string into a nice map
			Map<String, String> parsed = MRDPUtils.transformXmlToMap(value
					.toString());

			// Grab the "CreationDate" field,
			// since it is what we are grouping by
			String strDate = parsed.get("CreationDate");

			// Grab the comment to find the length
			String text = parsed.get("Text");

			// .get will return null if the key is not there
			if (strDate == null || text == null) {
				// skip this record
				return;
			}

			try {
				// get the hour this comment was posted in
				Date creationDate = frmt.parse(strDate);
				outHour.set(creationDate.getHours());

				// get the comment length
				outCountAverage.setCount(1);
				outCountAverage.setAverage(text.length());

				// write out the user ID with min max dates and count
				context.write(outHour, outCountAverage);
				long endTime = System.currentTimeMillis();
				long totalTime = endTime-startTime;
				context.getCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).increment(totalTime);

			} catch (ParseException e) {
				System.err.println(e.getMessage());
				return;
			}
		}
	}

	public static class SOAverageReducer
			extends
			Reducer<IntWritable, CountAverageTuple, IntWritable, CountAverageTuple> {
		private CountAverageTuple result = new CountAverageTuple();

		@Override
		public void reduce(IntWritable key, Iterable<CountAverageTuple> values,
				Context context) throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			float sum = 0;
			float count = 0;

			// Iterate through all input values for this key
			for (CountAverageTuple val : values) {
				sum += val.getCount() * val.getAverage();
				count += val.getCount();
			}

			result.setCount(count);
			result.setAverage(sum / count);

			context.write(key, result);
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
			System.err.println("Usage: AverageDriver <in> <out>");
			System.exit(2);
		}
		Job job = Job.getInstance(conf, "StackOverflow Average Comment Length");
		job.setJarByClass(AverageDriver.class);
		job.setMapperClass(SOAverageMapper.class);
		job.setCombinerClass(SOAverageReducer.class);
		job.setReducerClass(SOAverageReducer.class);
		job.setOutputKeyClass(IntWritable.class);
		job.setOutputValueClass(CountAverageTuple.class);
		FileInputFormat.addInputPath(job, new Path(otherArgs[0]));
		FileOutputFormat.setOutputPath(job, new Path(otherArgs[1]));
		System.exit(job.waitForCompletion(true) ? 0 : 1);
		Counters counters = job.getCounters();
		LOG.info("MAPTIME", counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
		LOG.info("REDTIME", counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());
		System.out.println("MAPTIME "+counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
		System.out.println("REDTIME "+counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());
	}

	public static class CountAverageTuple implements Writable {
		private float count = 0f;
		private float average = 0f;

		public float getCount() {
			return count;
		}

		public void setCount(float count) {
			this.count = count;
		}

		public float getAverage() {
			return average;
		}

		public void setAverage(float average) {
			this.average = average;
		}

		//@Override
		public void readFields(DataInput in) throws IOException {
			count = in.readFloat();
			average = in.readFloat();
		}

		//@Override
		public void write(DataOutput out) throws IOException {
			out.writeFloat(count);
			out.writeFloat(average);
		}

		@Override
		public String toString() {
			return count + "\t" + average;
		}
	}
}
