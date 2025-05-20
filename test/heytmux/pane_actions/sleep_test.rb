# frozen_string_literal: true

require 'test_helper'

module Heytmux
  module PaneActions
    class SleepTest < HeytmuxTestBase
      def test_validate
        [-1, 'string', 0].each do |val|
          assert_raises(ArgumentError) { Sleep.new.validate(val) }
        end
        [1, '1'].each do |val|
          Sleep.new.validate(val)
        end
      end

      def test_process
        sleep_time = 0.1
        started = Time.now
        Sleep.new.process(nil, nil, sleep_time)
        assert Time.now - started > sleep_time
      end
    end
  end
end
