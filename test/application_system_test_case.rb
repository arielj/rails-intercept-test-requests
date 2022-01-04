require "test_helper"
require_relative "support/interceptor"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Interceptor

  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  def after_setup
    start_intercepting
    super
  end

  def before_teardown
    stop_intercepting
    super
  end
end