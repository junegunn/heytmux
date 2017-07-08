require 'test_helper'

class HeytmuxValidationsTest < HeytmuxTestBase
  def test_validate
    # Invalid
    [1, '1', :foo, {},
     { 'windows' => 'foo' },
     { 'windows' => nil }].each do |spec|
      assert_raises(ArgumentError) { Heytmux::Validations.validate(spec) }
    end

    assert_nil Heytmux::Validations.validate('windows' => [])
    assert_nil Heytmux::Validations.validate([])
  end

  def test_validate_window
    ['',
     { 'foo' => 1, 'bar' => 2 },
     { 1 => 2 },
     [],
     { '' => {} },
     { 'foo' => 'bar' }].each do |spec|
      assert_raises(ArgumentError) do
        Heytmux::Validations.validate_window(spec)
      end
    end

    ['foo',
     { 'foo' => [] },
     { 'foo' => {} },
     { 'foo' => ['pane1', { 'pane2' => 'command' }] },
     { 'foo' => [{ 'pane2' => [{ 'expect' => 'pattern' }] }] }].each do |spec|
      assert_nil Heytmux::Validations.validate_window(spec)
    end
  end

  def test_validate_pane
    [nil, '', [], { 'foo' => 1, 'bar' => 2 }].each do |spec|
      assert_raises(ArgumentError) do
        Heytmux::Validations.validate_pane(spec)
      end
    end
    ['foo',
     { 'foo' => 'bar' },
     { 'foo' => [1, 2, 3] }].each do |spec|
      assert_nil Heytmux::Validations.validate_pane(spec)
    end
  end

  def test_validate_command
    [nil, [nil], '', 'foo',
     ['foo', 'bar', 'expect' => 'pattern']].each do |spec|
      assert_nil Heytmux::Validations.validate_commands(spec)
    end
    [[[]], ['not expected' => 'pattern']].each do |spec|
      assert_raises(ArgumentError) do
        Heytmux::Validations.validate_commands(spec)
      end
    end
  end
end
