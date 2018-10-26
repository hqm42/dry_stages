# DryStages

Configurable, reusable, cached stages for optimzed code reuse and dry implementation of single-tack processing pipelines

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dry_stages'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dry_stages

## Usage

### Export example

First define some base class to implement the core stages and stage implementation of an export.
```ruby
require 'csv'

class Export
  include DryStages::Stages

  # define stages available in order of execution
  def_stage_def :format, :to
  def_stage_def :delivery, :send_to

  # define implementations of stages

  # The first stage gets its argument form `#input` (not yet defined)
  def_format_stage :string, -> (table) {
    table.to_s
  }

  # Stage implementation can take arguments passed at configuration time (**options)
  def_format_stage :csv, -> (table, **options) {
    CSV.generate(**options) do |csv|
      table.each do |row|
        csv << row
      end
    end
  }

  # second stage gets the result of the previous stages as first argument
  def_delivery_stage :stdout, -> (formated_export) {
    puts formated_export
  }

  # it also accepts options at configuration time
  def_delivery_stage :email, -> (formated_export, email_address:) {
    # TODO: deliver some nice email
    puts "sending email to #{email_address} with content:"
    puts formated_export
  }
end
```

Inherit from the `Export` base class to build any kind of export.
```ruby
class FibonacciExport < Export
  def initialize(n)
    @n = n

    # initialize is a good place to set default stage implementation
    to_csv
  end

  def input
    # https://stackoverflow.com/a/6420253
    fibonacci = Hash.new{ |h,k| h[k] = k < 2 ? k : h[k-1] + h[k-2] }

    (0...@n).map do |index|
      [index, fibonacci[index]]
    end
  end
end
```

Configure and `run!` the export.an usefull 
```ruby
# instanciate the export
fibonacci_export = FibonacciExport.new(10)

# configure export delivery
fibonacci_export.send_to_stdout

# run the export
fibonacci_export.run!

# outputs:
# 0,0
# 1,1
# 2,1
# 3,2
# 4,3
# 5,5
# 6,8
# 7,13
# 8,21
# 9,34

# reconfigure the export
fibonacci_export.send_to_email(email_address: 'mathematician@example.com')

# and run it again
fibonacci_export.run!

# outputs:
# sending email to mathematician@example.com with content:
# 0,0
# 1,1
# 2,1
# 3,2
# 4,3
# 5,5
# 6,8
# 7,13
# 8,21
# 9,34
```

Define another export and reuse the stage implemetations.
```ruby
class HugeReportingExport < Export
  def initialize(year:, month:)
    to_csv
    sent_to_email(email_address: 'manager@example.com')
  end
  
  def input
    # TODO
    []
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dry_stages. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
