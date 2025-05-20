# frozen_string_literal: true

module Heytmux
  # Base class for pane actions. To implement a new type of action that is
  # applied to a designated pane, one should write a class that derives from
  # this class. Use register class method to associate the class with one or
  # more labels.
  class PaneAction
    # Validation method to be overridden. Throw ArgumentError if body is
    # invalid.
    def validate(_body)
      nil
    end

    # Defines the behavior of the action. Should be implemented by the
    # subclasses. When the method is called, a block is passed that is for
    # replacing {{ item }} in the body. One may or may not want to use it on
    # body depending on the use case.
    def process(_window_index, _pane_index, _body)
      raise NotImplementedError
    end

    class << self
      # Registers a PaneAction class with the label
      def register(*labels, klass)
        instance = klass.new
        (@actions ||= {}).merge!(
          labels.to_h { |label| [label, instance] }
        )
      end

      # Finds PaneAction class for the label
      def for(label)
        @actions[label.to_sym]
      end

      def inherited(klass)
        def klass.register(*labels)
          PaneAction.register(*labels, self)
        end
      end
    end
  end
end
