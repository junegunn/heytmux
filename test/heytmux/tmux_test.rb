require 'test_helper'

class HeytmuxTmuxTest < HeytmuxTestBase
  def test_tmux
    assert_match(/tmux [2-9]\.+[0-9]+|tmux master/, Tmux.tmux('-V'))
  end

  def test_list
    list = Tmux.list
    assert_instance_of Array, list
    list.all? do |e|
      assert_instance_of Hash, e
      assert_equal 4, e.length # 4 keys
    end
  end

  def test_window_lifecycle
    window_name = 'heytmux-test-window'
    pane_title1 = 'first pane'
    pane_title2 = 'second pane'
    base_index = 0

    # Create window
    prev_list = Tmux.list
    opt = 'synchronize-panes'
    window_index = Tmux.create_window(window_name,
                                      pane_title1,
                                      opt => true,
                                      'pane-base-index' => base_index)
    assert window_index.is_a?(Integer)

    # Check if the window is created with the right name and title
    refute(prev_list.any? { |e| e[:window_index] == window_index })
    assert(Tmux.list.any? { |e| e[:window_index] == window_index })
    assert_equal(opt + ' on',
                 Tmux.tmux(%w[show-window-options -t], window_index, opt))
    assert_retries("#{window_name}:#{pane_title1}") do
      query(window_index, base_index, '#{window_name}:#{pane_title}')
    end

    # Change window option
    Tmux.set_window_options(window_index, opt => false)
    assert_equal(opt + ' off',
                 Tmux.tmux(%w[show-window-options -t], window_index, opt))

    # Split window
    pane_index = Tmux.split_window(window_index, pane_title2)
    assert_retries(pane_title2) { query(window_index, pane_index) }

    # Close window and the window should not be found in the result of Tmux.list
    Tmux.kill(window_index)
    refute Tmux.list.map { |e| e[:window_index] }.include?(window_index)
  end
end
