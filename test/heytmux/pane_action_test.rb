require 'test_helper'

class HeytmuxPaneActionTest < HeytmuxTestBase
  class IncompleteAction < Heytmux::PaneAction
  end

  def test_unimplemented_process
    assert_raises(NotImplementedError) do
      IncompleteAction.new.process(nil, nil, nil)
    end
  end

  def test_default_validate
    # Should not raise error
    IncompleteAction.new.validate(nil)
  end

  def test_paste_validation
    paste = Heytmux::PaneActions::Paste.new

    [nil, 'body', 1, 1.0, true, false].each do |body|
      paste.validate(body)
    end
    [[], {}].each do |body|
      assert_raises(ArgumentError) do
        Heytmux::PaneActions::Paste.new.validate(body)
      end
    end
  end
end
