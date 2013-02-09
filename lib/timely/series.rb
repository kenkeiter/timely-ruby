module Timely

  class SampleNotFound < IndexError; end

  # The Series module can be included into any Ruby class to turn it into a 
  # model for a Timely series.
  #
  # Usage:
  #
  #     class ExampleSeries
  #       include Timely::Series
  #       dimension :value
  #       dimension :position_lat, lazy: true
  #       dimension :position_long, lazy: true
  #     end
  #
  #     series = ExampleSeries.new("some_series")
  #     series.add(1, :value => 1)
  #     series.add(2, :value => 2, :position_lat => x, :position_long => y)
  #     series.get(1) # => {'time' => 1, 'value' => 1}
  #     series.all(:range => 1..2) # => [{...}, {...}]
  #     series.all(:range => 1..2, :include => [:position_lat, :position_long])
  #     series.all(:range => 1..2, :codec => 'json.object')
  #
  module Series

    module ClassMethods
      
      def dimensions(include_lazy = true)
        @dimensions ||= {}
        if !include_lazy
          return @dimensions.reject{|_, opts| opts[:lazy] }
        end
        return @dimensions
      end

      def dimension(name, opts = {})
        @dimensions ||= {}
        @dimensions[name] = opts
      end

      def inherited(subclass)
        @subclass.instance_variable_set(:@dimensions, self.dimensions)
      end

    end
    
    module InstanceMethods

      def initialize(id)
        @id = id
      end

      def add(time, attrs = {})
        valid_keys = self.class.dimensions.keys
        attrs.reject!{|k, _| !valid_keys.include?(k) }
        Timely.current.set(key_for_series, coerce_to_id(time), attrs)
      end

      def remove(time)
        Timely.current.delete_member(key_for_series, coerce_to_id(time))
      end

      def destroy
        Timely.current.delete_series(key_for_series)
      end

      def get(id_or_time, opts = {})
        if opts[:codec] && opts[:codec] != 'native'
          raise ArgumentError, "Cannot fetch single ID encoded."
        end
        opts[:include] ||= self.class.dimensions(false).keys
        result = Timely.current.get(key_for_series, coerce_to_id(id_or_time), *opts[:include])
        unless result.kind_of?(Array)
          raise SampleNotFound, "Sample was not found at index: #{id_or_time}."
        end
        opts[:include].insert(0, :time)
        return Hash[opts[:include].zip(result)]
      end

      def all(opts = {})
        opts[:codec] ||= 'native'
        opts[:include] ||= self.class.dimensions(false).keys
        opts[:range] ||= :all
        opts[:as] ||= (opts[:codec] == 'native') ? :hash : :raw
        if opts[:range] == :all
          result = Timely.current.members(key_for_series, opts[:codec], *opts[:include])
          return format_results(opts[:include], result, opts[:as])
        elsif opts[:range].kind_of?(Range)
          result = Timely.current.range(key_for_series, opts[:codec], 
            coerce_to_id(opts[:range].begin), coerce_to_id(opts[:range].end + 1), *opts[:include])
          return format_results(opts[:include], result, opts[:as])
        else
          raise ArgumentError, "Invalid query :range argument. Must be Range or :all."
        end
      end

      def key_for_series(*subkeys)
        if subkeys.length > 0
          return "#{@id}.#{subkeys.join('.')}"
        else
          return @id.to_s
        end
      end
      
      def coerce_to_id(value)
        if value.kind_of?(Time)
          return (value.to_f * 1000).round 
        else
          return value.to_i
        end
      end

      #######
      private
      #######

      def format_results(fields, results, format)
        if format == :array
          return results
        elsif format == :hash
          fields.insert(0, :time)
          return results.map do |result|
            Hash[fields.zip(result)]
          end
        elsif format == :raw
          return results
        end
      end

    end
    
    def self.included(receiver)
      receiver.send :extend, ClassMethods
      receiver.send :include, InstanceMethods
    end

  end

end