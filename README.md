# Timely

The Timely gem utilizes existing Redis libraries to allow high-volume queries to the Timely time series database. 

## Installation

Add this line to your application's Gemfile:

    gem 'timely', :git => 'https://github.com/kenkeiter/timely-ruby.git'

And then execute:

    $ bundle

## Usage

    require 'timely'

    Timely.current = Timely::Connection.new()

    Timely.current.ping # => "PONG"

    Timely.current.exists('series_id') # => false

    Timely.current.dimensions('series_id', 12345) # => list of dimensions for key at time

    # Fetch the given dimensions of a time series as native values.
    Timely.current.members('series_id', 'native', 'dimensions1', 'dimensions2') # => [{'dimensions1' => 'value', 'dimensions2' => 'value'}]

    # Fetch the given dimensions of a time series as a string of JSON objects.
    Timely.current.members('series_id', 'json.object', 'dimensions1', 'dimensions2') # => '[{"dimensions1": "value", "dimensions2": "value"}]'

    # Fetch the given dimensions of a time series as a string of JSON arrays.
    Timely.current.members('series_id', 'json.array', 'dimensions1', 'dimensions2') # => '[["value", "value"]]'

    # Fetch results within a range; follows the #members format.
    Timely.current.members('series_id', 'native', 123, 456, 'dimensions1')

    # Given a series and time, select the specified dimensions and return them.
    Timely.current.get(series_id, time, *dimensions)

    # Set the specified dimensions for a series and time. If the time series 
    # does not exist, create it.
    Timely.current.set(series_id, time, dimensions = {})

    # Delete a series by name.
    Timely.current.delete_series(series_name)

    # Delete a sample within a series by name and time.
    Timely.current.delete_member(series_name, time)