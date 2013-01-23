require "benchmark"
require "timely"

unless RUBY_PLATFORM =~ /java/i
  require 'hiredis'
  timely = Timely::Connection.new(:driver => :hiredis)
else
  timely = Timely::Connection.new
end

ITERATIONS = 100

Benchmark.bm(42) do |x|
  series_name = (0...8).map{65.+(rand(26)).chr}.join

  x.report "Insert 10k records" do
    10_000.times do |i|
      timely.set(series_name, i, :value => i)
    end
  end

  x.report "(#{ITERATIONS} x) Fetch 10k records as JSON objects" do
    ITERATIONS.times do |_|
      timely.members(series_name, "json.object", "value")
    end
  end

  x.report "(#{ITERATIONS} x) Fetch 10k records as JSON arrays" do
    ITERATIONS.times do |_|
      timely.members(series_name, "json.array", "value")
    end
  end

  x.report "(#{ITERATIONS} x) Fetch range (2500..7000) as JSON objects" do
    ITERATIONS.times do |_|
      timely.range(series_name, "json.object", 2500, 7000, "value")
    end
  end

  x.report "(#{ITERATIONS} x) Fetch range (2500..7000) as JSON arrays" do
    ITERATIONS.times do |_|
      timely.range(series_name, "json.array", 2500, 7000, "value")
    end
  end

end