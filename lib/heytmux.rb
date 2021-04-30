# frozen_string_literal: true

require 'set'

# Hey tmux!
module Heytmux
  DEFAULT_LAYOUT = ->(num_panes) { num_panes <= 3 ? 'even-vertical' : 'tiled' }
  DEFAULT_OPTIONS = {
    'automatic-rename'   => 'off',
    'allow-rename'       => 'off',
    'pane-base-index'    => 0,
    'pane-border-status' => 'bottom',
    'pane-border-format' => '#{pane_title}'
  }.freeze

  WINDOWS_KEY = 'windows'
  LAYOUT_KEY = 'layout'
  PANES_KEY = 'panes'
  ITEMS_KEY = 'items'
  ITEM_PAT = /{{ *item *}}/i
  ITEM_INDEX_PAT = /{{ *item\.index *}}/i
  ENV_PAT = /{{ *\$([a-z0-9_]+) *(?:\| *(.*?) *)?}}/i

  EXPECT_SLEEP_INTERVAL = 0.5
  EXPECT_TIMEOUT = 60
end

require 'heytmux/version'
require 'heytmux/validations'
require 'heytmux/pane_action'
require 'heytmux/pane_actions/paste'
require 'heytmux/pane_actions/expect'
require 'heytmux/pane_actions/sleep'
require 'heytmux/pane_actions/keys'
require 'heytmux/tmux'
require 'heytmux/core'
