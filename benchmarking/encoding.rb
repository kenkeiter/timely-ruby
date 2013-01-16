require "benchmark"
require "timely"

unless RUBY_PLATFORM =~ /java/i
  require 'hiredis'
  timely = Timely::Connection.new(:driver => :hiredis)
else
  timely = Timely::Connection.new
end

NUM_ITERATIONS = (ARGV.shift || 10000).to_i
series = (0...8).map{65.+(rand(26)).chr}.join

def benchmark_time(desc, &block)
  elapsed = Benchmark.realtime do
    block.call
  end
  puts "#{desc}: #{elapsed * 1000} milliseconds"
end

NUM_ITERATIONS.times do |i|
  timely.set(series, i, :value => i, :position_lat => i * 10, :position_long => i * 1.5 )
end

benchmark_time("Select 'value' from range(2500s..7000s) as JSON objects (#{NUM_ITERATIONS} records)") do
  timely.range(series, "json.object", 2500, 7000, "value")
end
benchmark_time("Select 'value' from range(2500s..7000s) as JSON arrays (#{NUM_ITERATIONS} records)") do
  timely.range(series, "json.array", 2500, 7000, "value")
end
benchmark_time("Select 'value' from members as JSON objects (#{NUM_ITERATIONS} records)") do
  timely.members(series, "json.object", "value")
end
benchmark_time("Select 'value' from members as JSON arrays (#{NUM_ITERATIONS} records)") do
  timely.members(series, "json.array", "value")
end