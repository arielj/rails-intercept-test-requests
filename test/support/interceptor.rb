# Doing this import from `lib` to share the Interceptor with both MiniTest and RSpec
# If the app has only one test framework, this file can have the Interceptor module directly
require_relative "../../lib/interceptor.rb"