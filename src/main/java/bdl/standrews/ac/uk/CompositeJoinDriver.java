package bdl.standrews.ac.uk;

import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.KeyValueTextInputFormat;
import org.apache.hadoop.mapreduce.lib.join.CompositeInputFormat;
import org.apache.hadoop.mapreduce.lib.join.TupleWritable;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;




public class CompositeJoinDriver {
	private static final Logger LOG = LoggerFactory.getLogger(WikipediaIndex.class.getName());
	public static enum MAP_RED_CUSTOM {
		MAP_TIME_MILLIS
	};
	public static class CompositeMapper extends
			Mapper<Object, TupleWritable, Text, Text> {

		@Override
		public void map(Object key, TupleWritable value,
				Context context)
				throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			// Get the first two elements in the tuple and output them
			context.write((Text) value.get(0), (Text) value.get(1));
			long endTime = System.currentTimeMillis();
			long totalTime = endTime-startTime;
			context.getCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).increment(totalTime);
		}
	}

	public static void main(String[] args) throws Exception {
		Configuration conf = new Configuration();
		String[] otherArgs = new GenericOptionsParser(conf, args)
				.getRemainingArgs();
	
		
		if (otherArgs.length != 4) {
			System.err
					.println("Usage: CompositeJoin <user data> <comment data> <out> [inner|outer]");
			System.exit(1);
		}

		Path userPath = new Path(otherArgs[0]);
		Path commentPath = new Path(otherArgs[1]);
		Path outputDir = new Path(otherArgs[2]);
		String joinType = otherArgs[3];
		if (!(joinType.equalsIgnoreCase("inner") || joinType
				.equalsIgnoreCase("outer"))) {
			System.err.println("Join type not set to inner or outer");
			System.exit(2);
		}
		
		// The composite input format join expression will set how the records
				// are going to be read in, and in what input format.
				conf.set("mapreduce.join.expr", CompositeInputFormat.compose(joinType,
						KeyValueTextInputFormat.class, userPath, commentPath));
		
		Job job = Job.getInstance(conf, "Composite Join");
		job.setJarByClass(CompositeJoinDriver.class);
		job.setMapperClass(CompositeMapper.class);
		job.setNumReduceTasks(0);

		// Set the input format class to a CompositeInputFormat class.
		// The CompositeInputFormat will parse all of our input files and output
		// records to our mapper.
		job.setInputFormatClass(CompositeInputFormat.class);

		

	
		
		//job.setOutputValueClass(Text.class);
		job.setOutputKeyClass(Text.class);
		FileInputFormat.addInputPath(job, new Path(otherArgs[0]));
		FileOutputFormat.setOutputPath(job, outputDir);
		System.exit(job.waitForCompletion(true) ? 0 : 1);
		Counters counters = job.getCounters();
		LOG.info("MAPTIME", counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
		System.out.println("MAPTIME "+counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
	
	}
}
