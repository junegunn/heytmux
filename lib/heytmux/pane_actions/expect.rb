# frozen_string_literal: true

require 'English'

module Heytmux
  module PaneActions
    # Pastes the command onto the pane
    class Expect < PaneAction
      register :expect

      def validate(body)
        raise ArgumentError, 'Expect condition is empty' if body.to_s.empty?
      end

      def process(window_index, pane_index, body)
        regex = Regexp.compile(yield(body))
        wait_until do
          content = Tmux.capture(window_index, pane_index)
          raise 'Failed to capture pane content' unless $CHILD_STATUS.success?
          content =~ regex
        end
      end

      private

      def wait_until
        timeout = Time.now + EXPECT_TIMEOUT
        loop do
          sleep EXPECT_SLEEP_INTERVAL
          return if yield
          raise 'Timed out' if Time.now > timeout
        end
      end
    end
  end
end
