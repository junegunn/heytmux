# frozen_string_literal: true

module Heytmux
  module PaneActions
    # Waits for a certain regular expression pattern appears
    class Paste < PaneAction
      register :paste

      def validate(body)
        case body
        when Hash, Array
          raise ArgumentError, "Invalid command: #{body}"
        end
      end

      def process(window_index, pane_index, body)
        Tmux.paste(window_index, pane_index, yield(body))
      end
    end
  end
end
