require "benchmark"
require "timely"

unless RUBY_PLATFORM =~ /java/i
  require 'hiredis'
  timely = Timely::Connection.new(:driver => :hiredis)
else
  timely = Timely::Connection.new
end

NUM_ITERATIONS = (ARGV.shift || 365 * 10).to_i
series = (0...8).map{65.+(rand(26)).chr}.join

def benchmark_ops(desc, &block)
  elapsed = Benchmark.realtime do
    block.call
  end
  puts "#{desc}: #{(2 * NUM_ITERATIONS / 1000 / elapsed)} Kops"
end

def benchmark_time(desc, &block)
  elapsed = Benchmark.realtime do
    block.call
  end
  puts "#{desc}: #{elapsed * 1000} milliseconds"
end

benchmark_ops("SET #{NUM_ITERATIONS} records (1 dimension, individually)") do
  NUM_ITERATIONS.times do |i|
    timely.set(series, i, :value => i, :other_value => i - 1)
  end
end

benchmark_ops("GET #{NUM_ITERATIONS} records (1 dimension, individually)") do
  NUM_ITERATIONS.times do |i|
    timely.get(series, i, "value", "other_value")
  end
end

benchmark_time("MEMBERS (1 dimension, fetch all records)") do
  timely.members(series, "default", "value", "other_value")
end

benchmark_time("RANGE (1 dimension, fetch quarter of all records)") do
  timely.range(series, "default", (NUM_ITERATIONS / 4) * 3, NUM_ITERATIONS, "value", "other_value")
end