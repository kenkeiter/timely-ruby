require 'rspec'
require 'timely'

def random_series_name
  (0...20).map{ ('a'..'z').to_a[rand(26)] }.join
end