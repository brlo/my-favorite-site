# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# # если консоль
# if Rails.const_defined? 'Console'
#   # pretty print in console by default for all objects
#   require 'amazing_print'
#   ::AmazingPrint.irb!
#   ::AmazingPrint.defaults = {
#     # если не нужно выровнивать как в xcode (по центру), то выставь -2 (отступ слева)
#     indent: -2,             # Number of spaces for indenting.
#     index:           false,   # Display array indices.
#     # html:          false,  # Use ANSI color codes rather than HTML.
#     # multiline:     true,   # Display in multiple lines.
#     # plain:         false,  # Use colors.
#     # raw:           false,  # Do not recursively format instance variables.
#     # sort_keys:     false,  # Do not sort hash keys.
#     # sort_vars:     true,   # Sort instance variables.
#     # limit:         false,  # Limit arrays & hashes. Accepts bool or int.
#     # ruby19_syntax: false,  # Use Ruby 1.9 hash syntax in output.
#     # class_name:    :class, # Method called to report the instance class name. (e.g. :to_s)
#     object_id:     false,   # Show object id.
#     # color: {
#     #   args:       :whiteish,
#     #   array:      :white,
#     #   bigdecimal: :blue,
#     #   class:      :yellow,
#     #   date:       :greenish,
#     #   falseclass: :red,
#     #   integer:    :blue,
#     #   float:      :blue,
#     #   hash:       :whiteish,
#     #   keyword:    :cyan,
#     #   method:     :purpleish,
#     #   nilclass:   :red,
#     #   rational:   :blue,
#     #   string:     :yellowish,
#     #   struct:     :whiteish,
#     #   symbol:     :cyanish,
#     #   time:       :greenish,
#     #   trueclass:  :green,
#     #   variable:   :cyanish
#   }
# end
