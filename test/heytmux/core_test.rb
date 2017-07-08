require 'test_helper'

class HeytmuxCoreTest < HeytmuxTestBase
  def test_that_it_has_a_version_number
    refute_nil ::Heytmux::VERSION
  end

  def test_replace_env_vars
    ENV['A'] = 'foo'
    ENV.delete 'B'
    assert_equal 'foo / bar',
                 Heytmux.replace_env_vars('{{ $A }} / {{ $B | bar }}')
    assert_raises(ArgumentError) do
      Heytmux.replace_env_vars('{{ $A }} / {{ $B }}')
    end
  end

  def test_stateful_indexer
    entities = [{ index: 1, title: 'foo' },
                { index: 2, title: 'bar' },
                { index: 3, title: 'foo' }]
    indexer = Heytmux.send(:indexer, entities, :title, :index)
    assert_equal 1, indexer['foo']
    assert_equal 3, indexer['foo']
    assert_nil indexer['foo']
    assert_equal 2, indexer['bar']
    assert_nil indexer['bar']
  end

  def test_interpret_pane_spec
    pane = { 'foo' => 'bar' }
    items = nil
    indexer = ->(_title) { nil }
    result = Heytmux.interpret_and_expand_pane_spec(pane, items, indexer)
    assert_equal([{ title: 'foo', command: 'bar', index: nil }], result)
  end

  def test_interpret_and_expand_pane_spec
    command = 'echo {{item}}'
    pane = { 'pane-{{ item }}' => command }
    items = %w[foo bar baz bar bar]
    indexes = { 'pane-foo' => [10], 'pane-bar' => [20, 30], 'pane-baz' => [] }
    indexer = ->(title) { indexes[title].shift }
    result = Heytmux.interpret_and_expand_pane_spec(pane, items, indexer)
    assert_equal(
      [{ title: 'pane-foo', item: 'foo', command: command, index: 10 },
       { title: 'pane-bar', item: 'bar', command: command, index: 20 },
       { title: 'pane-baz', item: 'baz', command: command, index: nil },
       { title: 'pane-bar', item: 'bar', command: command, index: 30 },
       { title: 'pane-bar', item: 'bar', command: command, index: nil }],
      result
    )
  end

  def test_create_if_missing
    entities = [{ index: nil, title: 'foo' },
                { index: 1, title: 'bar' },
                { index: nil, title: 'baz' }]
    new_index = 100
    found, created = Heytmux.send(:create_if_missing, entities, :index) do |e|
      e.merge(index: new_index)
    end
    assert_equal [{ index: 1, title: 'bar' }], found
    assert_equal [{ index: 100, title: 'foo' },
                  { index: 100, title: 'baz' }], created
  end

  def test_create_and_split
    window_name = 'heytmux-test-window'
    panes = [{ index: nil, title: 'foo', command: ':' },
             { index: nil, title: 'bar', command: ':' }]
    base_index = 0
    window = Heytmux.create_first_pane(name: window_name, panes: panes)
    window_index = window[:index]

    assert_equal base_index, window[:panes].first[:index]
    assert_nil window[:panes].last[:index]
    assert window_index.is_a?(Integer)

    assert_retries(panes.first[:title]) { query(window_index, base_index) }

    # window_index, pane_title, layout
    new_pane_name = 'bar'
    new_pane_index = Heytmux.send(:split_and_select_layout,
                                  window_index, new_pane_name, 'tiled')
    assert_equal base_index + 1, new_pane_index

    assert_retries(new_pane_name) { query(window_index, new_pane_index) }

    Tmux.kill(window_index)
  end

  def test_interpret_spec
    assert_equal [[], {}], Heytmux.interpret_root_spec([], [])

    spec = {
      'windows' => [
        'foo',
        { 'foo' => { 'panes' => ['foo2-1', 'foo2-3'], 'opt' => 'optval' } },
        { 'bar' => { 'panes' => ['bar-1'], 'layout' => 'tiled' } },
        { 'foo' => { 'panes' => [{ 'foo3-1' => 'echo foo3' }] } }
      ],
      'layout' => 'tiled',
      'foo' => 'bar'
    }
    list = [
      { window_index: 1, window_name: 'etc', pane_index: 1, pane_title: '' },
      { window_index: 2, window_name: 'foo', pane_index: 1, pane_title: 'foo-1' },
      { window_index: 3, window_name: 'bar', pane_index: 0, pane_title: 'bar-1' },
      { window_index: 3, window_name: 'bar', pane_index: 1, pane_title: 'bar-2' },
      { window_index: 4, window_name: 'foo', pane_index: 1, pane_title: 'foo2-1' },
      { window_index: 4, window_name: 'foo', pane_index: 2, pane_title: 'foo2-2' }
    ]
    windows, root_options = Heytmux.interpret_root_spec(spec, list)

    expected =
      [{ name: 'foo', index: 2, panes: [], layout: nil, options: {} },
       { name: 'foo', index: 4,
         panes: [{ title: 'foo2-1', command: 'foo2-1', index: 1 },
                 { title: 'foo2-3', command: 'foo2-3', index: nil }],
         layout: nil, options: { 'opt' => 'optval' } },
       { name: 'bar', index: 3,
         panes: [{ title: 'bar-1', command: 'bar-1', index: 0 }],
         layout: 'tiled', options: {} },
       { name: 'foo', index: nil,
         panes: [{ title: 'foo3-1', command: 'echo foo3', index: nil }],
         layout: nil, options: {} }]
    assert_equal expected, windows
    assert_equal({ 'layout' => 'tiled', 'foo' => 'bar' }, root_options)
  end

  # Basic integration test
  def test_process!
    spec = {
      'windows' => [
        'heytmux-test-1',
        { 'heytmux-test-2' =>
          { 'panes' => [{ 'heytmux-test2-1' => 'echo "foo"' },
                        { 'heytmux-test2-2' =>
                          ['sleep 0.5',
                           'echo "b"a"r"',
                           { 'expect' => '^bar$' }] }] } }
      ]
    }
    Heytmux.process!(spec, true)
    list = Tmux.list
    panes1 = list.select { |p| p[:window_name] == 'heytmux-test-1' }
    panes2 = list.select { |p| p[:window_name] == 'heytmux-test-2' }
    assert_equal 1, panes1.count
    assert_equal 2, panes2.count
    assert_retries(%w[heytmux-test2-1 heytmux-test2-2]) do
      panes2.map { |p| query(p[:window_index], p[:pane_index]) }
    end

    Heytmux.kill!(spec)
  end
end
