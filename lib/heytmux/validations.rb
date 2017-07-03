# frozen_string_literal: true

module Heytmux
  # Validates workspace specification
  module Validations
    module_function

    # Validates spec struct and raises ArgumentError on error
    def validate(spec)
      windows = case spec
                when Hash
                  unless spec.key?(WINDOWS_KEY)
                    raise(ArgumentError, 'windows key is not found')
                  end
                  spec[WINDOWS_KEY]
                when Array then spec
                else
                  raise ArgumentError, "Not a valid spec: #{spec}"
                end

      unless windows.is_a?(Array)
        raise ArgumentError, 'windows must be given as a list'
      end
      windows.each { |window| validate_window(window) }
      nil
    end

    # Validates spec struct for a window and raises ArgumentError on error
    # - window_name
    # - window_name => [panes...]
    # - window_name => { 'panes' => [panes...], ... }
    def validate_window(window_spec)
      message = "Not a valid window spec: #{window_spec.inspect}"
      case window_spec
      when Hash
        unless single_spec?(window_spec, Hash, Array)
          raise ArgumentError, message
        end
        spec = window_spec.first.last
        spec = { PANES_KEY => spec } if spec.is_a?(Array)
        spec.fetch(PANES_KEY, []).each do |pane|
          validate_pane(pane)
        end
      else
        # Just the name
        raise ArgumentError, message unless valid_name?(window_spec)
      end
      nil
    end

    # - pane_name
    # - { pane_name => command_string }
    # - { pane_name => [commands...] }
    def validate_pane(pane_spec)
      message = "Not a valid pane spec: #{pane_spec.inspect}"
      case pane_spec
      when Hash
        raise ArgumentError, message unless single_spec?(pane_spec)
        validate_commands(pane_spec.first.last)
      else
        raise ArgumentError, message unless valid_name?(pane_spec)
      end
    end

    # - command_string
    # - [command_strings_or_hashes...]
    def validate_commands(commands)
      return if commands.is_a?(String)
      message = "Invalid command: #{commands.inspect}"
      case commands
      when Array
        hashes, strings = commands.partition { |command| command.is_a?(Hash) }
        hashes.each do |command|
          raise ArgumentError, message unless single_spec?(command)
          action, condition = command.first
          unless SUPPORTED_ACTIONS.include?(action)
            raise ArgumentError, "Unsupported action: #{action}"
          end
          raise ArgumentError, message unless valid_name?(condition)
          Regexp.compile(condition.to_s)
        end
        strings.each do |command|
          raise ArgumentError, message unless valid_name?(command)
        end
      else
        raise ArgumentError, message unless valid_name?(commands)
      end
      nil
    end

    # Checks if the given hash only contains one mapping from a string to
    # a hash
    def single_spec?(spec, *klasses)
      (key, value), second = spec.take(2)
      second.nil? && !key.to_s.empty? &&
        (klasses.empty? || klasses.any? { |k| value.is_a?(k) })
    end
    private_class_method :single_spec?

    def valid_name?(value)
      !(value.nil? || value.is_a?(Array) || value.to_s.empty?)
    end
    private_class_method :valid_name?
  end
end
