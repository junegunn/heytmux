# frozen_string_literal: true

require 'shellwords'
require 'tempfile'

module Heytmux
  # Tmux integration
  module Tmux
    module_function

    def tmux(*args)
      args = args.flatten.map { |a| Shellwords.escape(a.to_s) }
      command = "tmux #{args.join(' ')}"
      (@mutex ||= Mutex.new).synchronize do
        puts command if ENV['HEYTMUX_DEBUG']
        `#{command}`.chomp
      end
    end

    def list
      labels = %i[window_index window_name pane_index pane_title]
      delimiter = '::::'
      list = tmux(%w[list-panes -s -F],
                  labels.map { |label| "\#{#{label}}" }.join(delimiter))
      list.each_line.map do |line|
        labels.zip(line.chomp.split(delimiter)).to_h.tap do |h|
          h[:window_index] = h[:window_index].to_i
          h[:pane_index] = h[:pane_index].to_i
        end
      end
    end

    def create_window(window_name, pane_title, window_options)
      tmux(%w[new-window -d -P -F #{window_index} -n],
           window_name).to_i.tap do |index|
        set_window_options(index, window_options)
        if pane_title
          base_index = window_options.fetch('pane-base-index', 0)
          set_pane_title(index, base_index, pane_title)
        end
      end
    end

    def paste(window_index, pane_index, keys)
      file = Tempfile.new('heytmux')
      file.puts keys
      file.close

      tmux(%w[load-buffer -b heytmux], file.path,
           %w[; paste-buffer -d -b heytmux],
           target(window_index, pane_index))
    ensure
      file.unlink
    end

    # Applies a set of window options
    def set_window_options(window_index, opts)
      args = opts.flat_map do |k, v|
        [';', 'set-window-option', target(window_index),
         k, { true => 'on', false => 'off' }.fetch(v, v)]
      end.drop(1)
      tmux(*args) if args.any?
    end

    # Splits the window and returns the index of the new pane
    def split_window(window_index, pane_title)
      tmux(%w[split-window -P -F #{pane_index} -d],
           target(window_index)).to_i.tap do |pane_index|
        set_pane_title(window_index, pane_index, pane_title)
        tmux('select-pane', target(window_index, pane_index))
      end
    end

    # Sets the title of the pane
    def set_pane_title(window_index, pane_index, title)
      # The space at the beginning is for preventing it from being added to
      # shell history
      paste(window_index, pane_index,
            %( sh -c "printf '\\033]2;#{title}\\033\\';clear"))
    end

    # Selects window layout
    def select_layout(window_index, layout)
      tmux('select-layout', target(window_index), layout)
    end

    # Selects window
    def select_window(window_index)
      tmux('select-window', target(window_index))
    end

    # Queries tmux
    def query(*indexes, print_format)
      tmux(%w[display-message -p -F], print_format, target(*indexes))
    end

    # Kills window
    def kill(index)
      tmux('kill-window', target(index))
    end

    # Captures pane content
    def capture(window_index, pane_index)
      file = Tempfile.new('heytmux')
      file.close
      tmux('capture-pane', target(window_index, pane_index),
           ';', 'save-buffer', file.path)
      File.read(file.path).strip
    ensure
      file.unlink
    end

    # Returns target identifier for tmux commands
    def target(*indexes)
      ['-t', ':' + indexes.join('.')]
    end
  end
end
