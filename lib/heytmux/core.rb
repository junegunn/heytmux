# frozen_string_literal: true

# Core functions of Heytmux
module Heytmux
  module_function

  def replace_env_vars(raw_input)
    raw_input.gsub(ENV_PAT) do
      name = Regexp.last_match[1]
      default = Regexp.last_match[2]
      ENV.fetch(name, default) ||
        raise(ArgumentError, "Missing environment variable: #{name}")
    end
  end

  # Processes spec struct
  def process!(root_spec, focus)
    # Find window indexes
    windows, root_options = interpret_root_spec(root_spec, Tmux.list)
    root_layout = root_options.delete(LAYOUT_KEY)

    # Create windows if not found (no :index)
    found_windows, new_windows = create_if_missing(windows, :index) do |window|
      create_first_pane(window)
    end

    # Process panes in windows
    threads = (found_windows + new_windows).flat_map.with_index do |window, idx|
      process_window!(window, root_options, root_layout, focus && idx.zero?)
    end
    threads.each(&:join)
  end

  # Kills windows specified in the input
  def kill!(root_spec)
    windows, = interpret_root_spec(root_spec, Tmux.list)
    windows.map { |w| w[:index] }.compact.sort.reverse.each do |index|
      Tmux.kill(index)
    end
  end

  # Executes tasks to the window
  def process_window!(window, root_options, root_layout, focus)
    index, panes, options, layout =
      window.values_at(:index, :panes, :options, :layout)
    layout ||= root_layout

    # Set additional options
    Tmux.set_window_options(index, root_options.merge(options))

    # Split panes
    found_panes, new_panes = create_if_missing(panes, :index) do |pane|
      pane_index =
        split_and_select_layout(index,
                                pane[:title],
                                layout || DEFAULT_LAYOUT[panes.length])
      pane.merge(index: pane_index)
    end

    # Select layout when it's explicitly given
    Tmux.select_layout(index, layout) if layout && new_panes.empty?

    # Focus window
    Tmux.select_window(index) if focus

    # Execute commands
    (found_panes + new_panes).map do |pane|
      Thread.new { process_command!(index, pane) }
    end
  end

  # Finds appropriate PaneActions for the commands and processes them
  def process_command!(window_index, pane)
    pane_index, item, commands = pane.values_at(:index, :item, :command)
    [*commands].compact.each do |command|
      label, body = command.is_a?(Hash) ? command.first : [:paste, command]
      PaneAction.for(label).process(window_index, pane_index, body) do |source|
        string = source.to_s
        item ? string.gsub(ITEM_PAT, item) : string
      end
    end
  end

  # Groups entities by the group key and extracts unique, sorted indexes and
  # returns stateful indexer that issues index number for the given group key
  def indexer(entities, group_key, index_key)
    indexes =
      Hash[entities.group_by { |e| e[group_key] }
                   .map { |g, es| [g, es.map { |e| e[index_key] }.sort.uniq] }]
    ->(group) { indexes.fetch(group, []).shift }
  end
  private_class_method :indexer

  # Interprets root spec for workspace
  def interpret_root_spec(root_spec, all_panes)
    window_indexer = indexer(all_panes, :window_name, :window_index)
    windows = window_specs(root_spec).map do |window|
      interpret_window_spec(window, all_panes, window_indexer)
    end
    [windows, root_options(root_spec)]
  end

  def window_specs(root_spec)
    # The list of window specs can be specified under top-level 'windows' keys,
    # or it can be given as the top-level array.
    windows = root_spec.is_a?(Array) ? root_spec : root_spec[WINDOWS_KEY]
    windows.map do |window|
      window.is_a?(String) ? { window => {} } : window
    end
  end
  private_class_method :window_specs

  def root_options(root_spec)
    if root_spec.is_a?(Array)
      {}
    else
      root_spec.dup.tap { |copy| copy.delete(WINDOWS_KEY) }
    end
  end
  private_class_method :root_options

  # Interprets spec for a window
  def interpret_window_spec(window, all_panes, window_indexer)
    name, spec = window.first
    spec = { PANES_KEY => spec } if spec.is_a?(Array)
    index = window_indexer[name]
    existing_panes = all_panes.select { |h| h[:window_index] == index }
    pane_indexer = indexer(existing_panes, :pane_title, :pane_index)

    spec = spec.dup || {}
    layout = spec.delete(LAYOUT_KEY)
    items = spec.delete(ITEMS_KEY)
    items = items ? items.map { |item| Regexp.escape(item.to_s) } : ['\0']
    panes = spec.delete(PANES_KEY) || []
    panes = panes.flat_map do |pane|
      interpret_and_expand_pane_spec(pane, items, pane_indexer)
    end

    { name: name, index: index, panes: panes, layout: layout, options: spec }
  end

  def interpret_and_expand_pane_spec(pane, items, pane_indexer)
    title, command = pane.is_a?(Hash) ? pane.first : [pane.tr("\n", ' '), pane]
    if title =~ ITEM_PAT
      items.map do |item|
        title_sub = title.gsub(ITEM_PAT, item.to_s)
        { title: title_sub, command: command,
          item: item.to_s, index: pane_indexer[title_sub] }
      end
    else
      [{ title: title, command: command, index: pane_indexer[title] }]
    end
  end

  # Checks if there are entities without the required_field and creates them
  # with the given block. Returns two arrays of found and created entities.
  def create_if_missing(entities, required_field)
    found, missing = entities.partition { |e| e[required_field] }
    [found, missing.map { |e| yield e }]
  end
  private_class_method :create_if_missing

  # Creates a new tmux window and sets the title of its first pane.
  # Returns the index of the new window.
  def create_first_pane(window)
    name, panes = window.values_at(:name, :panes)
    pane_title = panes.map { |pane| pane[:title] }.first
    new_index = Tmux.create_window(name, pane_title, DEFAULT_OPTIONS)
    if pane_title
      panes = panes.dup
      panes[0] = panes[0].dup.tap do |pane|
        pane[:index] = DEFAULT_OPTIONS['pane-base-index']
      end
    end
    window.merge(index: new_index, panes: panes)
  end

  # To avoid 'pane too small' error, we rearrange panes after every split
  def split_and_select_layout(window_index, pane_title, layout)
    Tmux.split_window(window_index, pane_title).tap do
      Tmux.select_layout(window_index, layout)
    end
  end
  private_class_method :split_and_select_layout
end
