require 'test_helper'

module Heytmux
  module PaneActions
    class KeysTest < HeytmuxTestBase
      def test_validate
        # Nested arrays are not allowed
        [{}, [[]]].each do |val|
          assert_raises(ArgumentError) { Keys.new.validate(val) }
        end
        ['foo', %w[foo bar], 1, nil].each do |val|
          Keys.new.validate(val)
        end
      end

      def test_process
        window_name = 'heytmux-keys-test'
        pane_index = 1
        matcher = -> { Tmux.list.select { |e| e[:window_name] == window_name } }

        assert(matcher.call.empty?)
        window_index = Tmux.create_window(window_name, 'pane',
                                          'pane-base-index' => pane_index)
        assert(matcher.call.any?)

        Keys.new.process(window_index, pane_index, %w[c-c exit enter])
        assert_retries([]) { matcher.call }
      end
    end
  end
end
