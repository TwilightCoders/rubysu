require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter
]

SimpleCov.start do
  add_filter '/spec'
  add_group "LibEXEC", "/libexec"
end

# require 'pry'
require 'sudo'

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  config.example_status_persistence_file_path = 'spec/results.txt'
  config.run_all_when_everything_filtered = true

  # config.formatter = :progress
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
