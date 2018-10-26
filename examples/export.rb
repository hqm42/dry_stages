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
