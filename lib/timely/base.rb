require 'monitor'

require 'bundler/setup'

require 'redis/errors'
require 'redis/connection'
require 'redis/client'

unless RUBY_PLATFORM =~ /java/i
  HIREDIS_AVAILABLE = true
  require 'hiredis'
else
  HIREDIS_AVAILABLE = false
end

module Timely

  class Connection

    DEFAULTS = {
      :port => 8990
    }

    DEFAULTS[:driver] = :hiredis if HIREDIS_AVAILABLE

    attr :client

    def self.current
      @current ||= Connection.new
    end

    def self.current=(connection)
      @current = connection
    end

    include MonitorMixin

    def initialize(options = {})
      options = DEFAULTS.merge(options)
      @client = Redis::Client.new(options)
      super() # Monitor#initialize
    end

    def synchronize
      mon_synchronize { yield(@client) }
    end

    # Run code with the client reconnecting
    def with_reconnect(val=true, &blk)
      synchronize do |client|
        client.with_reconnect(val, &blk)
      end
    end

    # Run code without the client reconnecting
    def without_reconnect(&blk)
      with_reconnect(false, &blk)
    end

    # Ping the server.
    #
    # @return [String] `PONG`
    def ping
      synchronize do |client|
        client.call([:ping])
      end
    end

    # Get info about the server.
    #
    # @return [Hash]
    def info
      synchronize do |client|
        client.call([:info]) do |reply|
          if reply.kind_of?(Array)
            Hash[reply]
          else
            reply
          end
        end
      end
    end

    # Check if a series exists.
    #
    # @return [Bool]
    def exists(series_name)
      synchronize do |client|
        client.call([:exists, series_name], &_boolify)
      end
    end

    # Determine which dimensions are set for a particular series and sample.
    #
    # @return [Array]
    def dimensions(series_name, time)
      synchronize do |client|
        client.call([:dimensions, series_name, time]) do |reply|
          if reply.kind_of?(String)
            reply.split(" ")
          else
            reply
          end
        end
      end
    end

    # Select dimensions from each record in a series, and return them using the 
    # codec specified in the format argument.
    def members(series_name, format, *dimensions)
      synchronize do |client|
        client.call([:members, series_name, format, dimensions].flatten!) do |reply|
          if reply.kind_of?(Array)
            reply.each_slice(dimensions.length).to_a
          else
            if format == 'native'
              [[reply]]
            else
              reply
            end
          end
        end
      end
    end

    # Select dimensions from each record within a given time range, and return 
    # them using the codec specified in the format argument.
    def range(series_name, format, from, to, *dimensions)
      synchronize do |client|
        client.call([:range, series_name, format, from, to, dimensions].flatten!) do |reply|
          if reply.kind_of?(Array)
            reply.each_slice(dimensions.length).to_a
          else
            if format == 'native'
              [[reply]]
            else
              reply
            end
          end
        end
      end
    end

    # Given a series and time, select the specified dimensions and return them.
    def get(series_id, time, *dimensions)
      synchronize do |client|
        client.call([:get, series_id, time, dimensions].flatten!) do |reply|
          if reply.kind_of?(Array)
            reply
          else
            [reply]
          end
        end
      end
    end

    # Set the specified dimensions for a series and time. If the time series 
    # does not exist, create it.
    def set(series_id, time, dimensions = {})
      synchronize do |client|
        client.call([:set, series_id, time, dimensions.to_a].flatten!, &_boolify)
      end
    end

    # Delete a series by name.
    def delete_series(series_name)
      synchronize do |client|
        client.call([:delseries, series_name], &_boolify)
      end
    end

    # Delete a sample within a series by name and time.
    def delete_member(series_name, time)
      synchronize do |client|
        client.call([:delseries, series_name, time], &_boolify)
      end
    end
    

    #######
    private
    #######

    # Commands returning 1 for true and 0 for false may be executed in a pipeline
    # where the method call will return nil. Propagate the nil instead of falsely
    # returning false.
    def _boolify
      lambda { |value|
        value == 1 if value
      }
    end

    def _hashify
      lambda { |array|
        hash = Hash.new
        array.each_slice(2) do |field, value|
          hash[field] = value
        end
        hash
      }
    end

    def _floatify(str)
      if (inf = str.match(/^(-)?inf/i))
        (inf[1] ? -1.0 : 1.0) / 0.0
      else
        Float str
      end
    end

  end

end