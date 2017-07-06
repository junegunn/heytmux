# frozen_string_literal: true

module Heytmux
  module PaneActions
    # Send keys using tmux send-keys command
    class Keys < PaneAction
      register :keys, :key

      def validate(body)
        body = body.is_a?(Array) ? body : [body]
        body.each do |key|
          unless Validations.valid_string?(key)
            raise ArgumentError, 'Keys must be given as a string or a list'
          end
        end
      end

      def process(window_index, pane_index, body)
        Tmux.tmux('send-keys', Tmux.target(window_index, pane_index), body)
      end
    end
  end
end
