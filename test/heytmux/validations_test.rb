# frozen_string_literal: true

require 'test_helper'
require 'English'

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
     { 'foo' => [{ 'pane2' => [{ 'expect' => 'pattern' }] },
                 { 'pane {{ item }}' => 'command',
                   'items' => [1, 2, 3] }] }].each do |spec|
      assert_nil Heytmux::Validations.validate_window(spec)
    end
  end

  def test_yaml_without_proper_quoting
    loaded = YAML.safe_load(['- window 1:',
                             '    items: [pane 1, pane 2]',
                             '    panes:',
                             '      - {{item}}:',
                             '      - {{item}}'].join($RS))
    assert_raises(ArgumentError) do
      Heytmux::Validations.validate_window(loaded.first)
    end
  end

  def test_validate_pane
    [
      nil,
      '',
      [],
      { 'foo' => 1, 'bar' => 2 },
      { 'foo' => 1, 'items' => 2 },
      { 'foo {{ item }}' => 1, 'items' => 2 },
      { 'foo' => 1, 'items' => [] },
      { 'foo' => 1, 'items' => [1, 2, 3] }
    ].each do |spec|
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
     ['foo', 'bar', { 'expect' => 'pattern' }]].each do |spec|
      assert_nil Heytmux::Validations.validate_commands(spec)
    end
    [[[]], ['not expected' => 'pattern']].each do |spec|
      assert_raises(ArgumentError) do
        Heytmux::Validations.validate_commands(spec)
      end
    end
  end
end
