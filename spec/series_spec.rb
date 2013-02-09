require 'spec_helper'

# Obligatory fixtures.

class TestSeries
  include Timely::Series

  dimension :value
  dimension :position_lat, lazy: true
  dimension :position_long, lazy: true

end

class TestSeriesSubclass < TestSeries; end

# Tests

describe Timely::Series do

  before :each do
    @series_name = random_series_name
    @series = TestSeries.new(@series_name)
  end

  it "should not fetch lazy dimensions by default" do
    t = Time.now
    @series.add(t, :value => 1, :position_lat => 2, :position_long => 3).should be_true
    result = @series.get(t)
    result.keys.include?(:position_lat).should be_false
    result.keys.include?(:position_long).should be_false
    result.keys.include?(:value).should be_true
    result = @series.get(t, :include => [:value, :position_lat, :position_long])
    result.keys.include?(:position_lat).should be_true
    result.keys.include?(:position_long).should be_true
    result.keys.include?(:value).should be_true
  end

  it "should allow the creation of samples" do
    t = Time.now
    @series.add(t, :value => 1, :position_lat => 2, :position_long => 3).should be_true
    record = @series.get(t)
    record[:value].to_i.should == 1
  end

  it "should allow the removal of samples" do
    t = Time.now
    @series.add(t, :value => 10).should be_true
    @series.remove(t).should be_true
    @series.all.should be_empty
  end

  it "should allow the destruction of the series" do
    @series.destroy.should be_true
    expect{@series.get(1)}.to raise_error(Redis::CommandError) 
  end

  it "should allow retrieval of single records by timestamp" do
    t = Time.now
    @series.add(t, :value => 1).should be_true
    record = @series.get(t)
    record[:value].to_i.should == 1
  end

  it "should allow retrieval of all records" do
    t0 = Time.now
    t0_ms = (t0.to_f * 1000).round
    t1 = Time.now + 1
    t1_ms = (t1.to_f * 1000).round
    @series.add(t0, :value => 1).should be_true
    @series.add(t1, :value => 2).should be_true
    @series.all(:include => [:value]).should == [
      {:time => t0_ms.to_s, :value => "1"}, 
      {:time => t1_ms.to_s, :value => "2"}
    ]
    @series.all(:include => [:value], :codec => 'json.array').should == "[[#{t0_ms},\"1\"],[#{t1_ms},\"2\"]]"
  end

  it "should allow retrieval of a range of records" do
    t0 = Time.now
    t1 = Time.now + 1
    @series.add(t0, :value => 1).should be_true
    @series.add(t1, :value => 2).should be_true
    @series.all(:range => t0..t1).length.should == 2
  end

  it "should properly generate a key for the series" do
    @series.key_for_series.should == @series_name
  end

end