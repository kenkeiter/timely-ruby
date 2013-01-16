#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--color"]
end

task :default => :spec

desc "Open an interactive Ruby (IRB) session preloaded with this library."
task :console do
  sh "irb -rubygems -r ./lib/timely.rb -I ./lib"
end

desc "Run benchmark suite against local Timely database instance."
task :benchmark do
  sh "ruby -I ./lib ./benchmarking/set_get.rb"
  sh "ruby -I ./lib ./benchmarking/encoding.rb"
end