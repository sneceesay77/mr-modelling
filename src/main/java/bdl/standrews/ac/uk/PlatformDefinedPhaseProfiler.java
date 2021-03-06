package bdl.standrews.ac.uk;

/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/** A generic program executed to profile the the different stages of the MapReduce farmework.
 *  The generic phase COUNTERS are in the modified MapReduce source and this file also contains few counters.*/

import java.io.IOException;
import java.util.Iterator;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.examples.terasort.TeraInputFormat;
import org.apache.hadoop.examples.terasort.TeraOutputFormat;
import org.apache.hadoop.fs.Path;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.Counters.Counter;
import org.apache.hadoop.mapred.MapTask;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.ReduceContext;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.TaskCounter;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PlatformDefinedPhaseProfiler {
	private static final Logger LOG = LoggerFactory.getLogger(MapTask.class.getName());

	public static enum MAP_RED_CUSTOM {
		MAP_TIME_MILLIS, REDUCE_TIME_MILLIS, TOTAL_RUNNING_MILLIS
	};

	public static class PlatformDefinedMapper extends Mapper<Object, Text, Text, Text> {

		public void map(Object key, Text value, Context context) throws IOException, InterruptedException {

			context.write(value, new Text(""));

		}

		@Override
		public void run(Context context) throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			setup(context);

			Configuration conf = context.getConfiguration();

			int splitSize = Integer.parseInt(conf.get("splitsize"));
			double selectivity = Double.parseDouble(conf.get("selectivity"));

			long totalRows = Utility.getNumberOfRows(splitSize);

			long rows = 0;
			// LOG.info("Total Records in input file "+totalRows);
			int threshold = (int) (selectivity * totalRows);
			// LOG.info("Total Records to process "+threshold);

			while (context.nextKeyValue()) {
				// LOG.info("Rows processed so far "+rows);

				if (rows++ <= threshold) {
					map(context.getCurrentKey(), context.getCurrentValue(), context);
					// LOG.info("Total Number of rows Generated by Teragen "+
					// rows +" ====== "+threshold);
				}

			}

			cleanup(context);
			long endTime = System.currentTimeMillis();
			long totalTime = endTime - startTime;
			context.getCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).increment(totalTime);
		}
	}

	public static class PlatformDefinedReducer extends Reducer<Text, Text, Text, Text> {

		public void reduce(Text key, Text values, Context context) throws IOException, InterruptedException {

			context.write(key, values);

		}

		public void run(Context context) throws IOException, InterruptedException {
			long startTime = System.currentTimeMillis();
			setup(context);
			while (context.nextKey()) {
				reduce(context.getCurrentKey(), context.getValues(), context);
			}
			cleanup(context);
			long endTime = System.currentTimeMillis();
			long totalTime = endTime - startTime;
			context.getCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).increment(totalTime);
		}
	}

	public static void main(String[] args) throws Exception {
		Configuration conf = new Configuration();
		String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
		conf.set("splitsize", otherArgs[2]);
		conf.set("selectivity", otherArgs[3]);

		if (args.length < 2) {
			System.err.println("Usage: PlatformDefinedPhaseProfiler <in>  <out> splitsize selectivity");
			System.exit(2);
		}
		Job job = Job.getInstance(conf, "PlatformDefinedPhaseProfiler");
		job.setJarByClass(PlatformDefinedPhaseProfiler.class);
		job.setMapperClass(PlatformDefinedMapper.class);
		// job.setCombinerClass(PlatformDefinedReducer.class);
		job.setReducerClass(PlatformDefinedReducer.class);
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(Text.class);
		job.setInputFormatClass(TeraInputFormat.class);
		job.setOutputFormatClass(TeraOutputFormat.class);
		FileInputFormat.addInputPath(job, new Path(otherArgs[0]));
		FileOutputFormat.setOutputPath(job, new Path(otherArgs[1]));
		long startTime = System.currentTimeMillis();
		int status = job.waitForCompletion(true) ? 0 : 1;
		long endTime = System.currentTimeMillis();
		long totalTime = endTime - startTime;
		Counters counters = job.getCounters();
		counters.findCounter(MAP_RED_CUSTOM.TOTAL_RUNNING_MILLIS).increment(totalTime);
//		System.out.println("Total Job Running Time = "+totalTime);
//		LOG.info("Total Job Running Time (MS) = "+totalTime);
//		LOG.info("Time taken by Mapper "+ counters.findCounter(MAP_RED_CUSTOM.MAP_TIME_MILLIS).getValue());
//		LOG.info("Time taken by Reducer "+ counters.findCounter(MAP_RED_CUSTOM.REDUCE_TIME_MILLIS).getValue());

		System.exit(status);
	}
}
