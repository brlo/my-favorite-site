#!/usr/bin/env ruby

# gem install 'terser'
# gem install 'mini_racer'
require 'optparse'
require 'terser'

options = {}
::OptionParser.new do |opts|
  opts.banner = "Usage: bib_minify_js.rb [options]"

  opts.on('-i', '--input PATH', 'Input file path') { |v| options[:input_file] = v }
  opts.on('-o', '--output PATH', 'Output file path') { |v| options[:output_file] = v }

end.parse!

puts "Minify JS: #{options[:input_file]}"

# doc: https://docs.ruby-lang.org/en/master/Pathname.html
# require 'pathname'
# p Pathname.new($0).realpath()

File.open(options[:output_file], 'w') do |io|
  # doc: https://github.com/ahorek/terser-ruby
  io.write ::Terser.new(output: {comments: :none}).compile(::File.read(options[:input_file]))
end

puts "Done: #{options[:output_file]}"
