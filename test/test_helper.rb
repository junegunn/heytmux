$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]
)
SimpleCov.start
require 'heytmux'
require 'minitest/autorun'

class HeytmuxTestBase < Minitest::Test
  Tmux = Heytmux::Tmux

  def setup
    assert ENV['TMUX'], 'You have to be on tmux'
  end

  def query(window_index, pane_index, format = '#{pane_title}')
    # XXX: It takes a little while for the pane title to change
    Tmux.query(window_index, pane_index, format)
  end

  TIMEOUT = 10

  def assert_retries(expected)
    timeout = Time.now + TIMEOUT
    loop do
      sleep 0.2
      actual = yield
      break if expected == actual
      flunk("Expected: #{expected}, actual: #{actual}") if Time.now > timeout
    end
  end
end
