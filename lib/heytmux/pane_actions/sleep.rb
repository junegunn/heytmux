# frozen_string_literal: true

module Heytmux
  module PaneActions
    # Sleeps for the given duration
    class Sleep < PaneAction
      register :sleep

      def validate(body)
        raise ArgumentError, 'Sleep expects positive number' if body.to_f <= 0
      end

      def process(_window_index, _pane_index, body)
        sleep(body.to_f)
      end
    end
  end
end
