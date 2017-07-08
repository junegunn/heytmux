Hey tmux!
=========

[![travis-ci](https://travis-ci.org/junegunn/heytmux.svg?branch=master)](https://travis-ci.org/junegunn/heytmux)
[![Coverage Status](https://coveralls.io/repos/github/junegunn/heytmux/badge.svg?branch=master)](https://coveralls.io/github/junegunn/heytmux?branch=master)
[![Gem](https://img.shields.io/gem/v/heytmux.svg)](https://rubygems.org/gems/heytmux)

Tmux scripting made easy.

Installation
------------

Heytmux requires Ruby 2.0+ and tmux 2.3+.

#### As Ruby gem

```sh
gem install heytmux
```

- Installs `heytmux` executable

#### As Vim plugin

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'junegunn/heytmux'
```

- Registers `:Heytmux` command
- No need to install Gem if you only use Heytmux inside Vim
    - But if you want it to be globally available,
      `Plug 'junegunn/heytmux', { 'do': 'gem install heytmux' }`

Usage
-----

Create a YAML file that describes a desired tmux workspace.

```yaml
# workspace.yml
- first window:
    layout: tiled
    panes:
      - first pane: sleep 1
      - second pane: sleep 2
      - third pane: |
          sleep 3
          sleep 4

- second window:
    layout: even-vertical
    pane-border-status: top
    synchronize-panes: true
    panes:
      - pane 2-1: sleep 5
      - pane 2-2: sleep 6
```

Then run `heytmux workspace.yml`.

Instead of creating a new session from scratch, Heytmux looks at the current
session and only creates windows and panes that are not found. So you can
repeatedly run the same input file only to issue commands on the existing
panes.

Heytmux identifies windows and panes by their names and titles, so renaming
them can confuse Heytmux. Duplicate names are okay as long as you don't
reorder windows or panes of the same names.

More examples can be found [here](examples/).

Heytmux can read STDIN, so `cat workspace.yml | heytmux` is also
[valid][caat]. It may seem pointless, but it allows you to do `:w !heytmux`
with a visual selection in Vim.

[caat]: http://porkmail.org/era/unix/award.html

Step-by-step tutorial
---------------------

#### List of window names

In the simplest case, input file only has to contain the names of windows as
the top-level list. Create `workspace.yml` and add the following lines.

```yaml
- window 1
- window 2
- window 3
```

`heytmux workspace.yml` will create 3 windows with the given names. If you
re-run the same command, you'll notice Heytmux doesn't create more windows as
they already exist.

#### Windows and panes

Well, that was not particularly interesting. Let's split the windows and run
some commands.

First run `heytmux --kill workspace.yml` to kill the windows we just created,
and update your input file as follows:

```yaml
- window 1:
  - echo 1-1
  - echo 1-2
  - echo 1-3
- window 2:
  - echo 2-1
  - echo 2-2
- window 3:
  - sleep 3
```

Run Heytmux with it and you'll see that panes are created under the windows to
run those commands. If you rerun the same command, Heytmux will send them
again to the same panes. No new panes are created.

#### Pane titles

However, if you change a command on the input file (e.g. `echo 1-1` to
`sleep 1`) and run Heytmux, a new pane for the command will be created. That's
because Heytmux identifies windows and panes by their names and titles, and in
the above case, the title of a pane is implicitly set to the given command. So
changing the command changes the identifier of the pane, and Heytmux no longer
can find the previous pane.

To reuse the existing panes, you have to explictly name the panes. Update the
input file, close the windows (`heytmux --kill workspace.yml`), and rerun the
command.

```yaml
- window 1:
  - pane 1: sleep 1
  - pane 2: sleep 2
  - pane 3: sleep 3
- window 2:
  - pane 2-1: sleep 1
  - pane 2-2: |
      sleep 2
      sleep 3
```

Now, you can freely change the commands without worrying about getting extra
panes. You can also create and use input files for any subset of the panes.

```yaml
# In another file
- window 2:
  - pane 2: echo 'I slept 5 seconds!'
```

#### Window layout and options

What if we want to change the layout of the windows, or if we want to set some
window options of tmux? To do that, move the list of panes to `panes` under
each window entry, so you can specify additional settings.

```yaml
- window 1:
    layout: even-horizontal
    synchronize-panes: true
    pane-border-status: bottom
    panes:
      - pane 1: sleep 1
      - pane 2: sleep 2
      - pane 3: sleep 3
- window 2:
    layout: even-horizontal
    synchronize-panes: true
    pane-border-status: top
    panes:
      - pane 2-1: sleep 1
      - pane 2-2: |
          sleep 1
          sleep 2
```

#### Root layout and options

That's nice, but looks like we're repeating ourselves with the same options.
We can reorganize the input file as follows to define the root layout and
options that are applied to all windows.

```yaml
layout: even-horizontal
synchronize-panes: true
pane-border-status: bottom

windows:
  - window 1:
      panes:
        - pane 1: sleep 1
        - pane 2: sleep 2
        - pane 3: sleep 3
  - window 2:
      # Override root option
      pane-border-status: top
      panes:
        - pane 2-1: sleep 1
        - pane 2-2: |
            sleep 1
            sleep 2
```

#### Expanding panes with `{{ item }}`

The panes under `window 1` in the previous example are similar in their names
and commands, and this is a very common case. To avoid repetition, set `items`
list for a window, then panes with `{{ item }}` in their titles will be
expanded according to the list.

```yaml
# Equivalent to the previous example
- window 1:
    items: [1, 2, 3]
    panes:
      - pane {{item}}: sleep {{item}}
```

Note that you have to quote a pane title if it starts with `{{ item }}`.

This is often useful when you have to work with a series of log files or with
a set of servers.

```yaml
- servers:
    layout: tiled
    items:
      - west-host1
      - west-host2
      - east-host1
      - east-host2
    panes:
      - ssh user@{{item}} tail -f /var/log/server-{{item}}.log
```


#### Referring to environment variables

You can refer to environment variables using `{{ $ENV_VAR }}` syntax. For
default values, use `{{ $ENV_VAR | the-default-value }}` syntax. Heytmux will
not start if an environment variable is not defined and there's no default
value.

#### Expecting pattern

Sometimes it's not enough to just send lines of text at once. For example, the
following example will not work as expected.

```yaml
- servers:
  - server 1: |
      ssh server1
      {{ $MY_SSH_PASSWORD }}
      uptime
```

With `expect` construct, you can make Heytmux wait until a certain regular
expression pattern appears on the pane (a la [Expect][expect]).

[expect]: https://en.wikipedia.org/wiki/Expect

```yaml
- servers:
  - server 1:
    - ssh server1
    - expect: '[Pp]assword:'
    - {{ $MY_SSH_PASSWORD }}
    - uptime
```

#### Special commands

In addition to `expect`, Heytmux also supports `sleep` and `keys` commands.
`sleep` suspends the execution for a given time period. It's useful when the
shell on the target pane is non-interactive so you can't send `sleep` command
to it. `keys` command is for sending special keys, such as `c-c` (CTRL-C)
using `tmux send-keys` command. To send multiple keys, specify the keys as
a YAML list (e.g. `[c-c, c-l]`).

```yaml
- servers:
  - server 1:
    - vmstat 2 | tee log
    - sleep: 3
    - keys: c-c
```

Vim plugin
----------

You don't really need a Vim plugin for Heytmux (because `:w !heytmux` will
just do), but here's one anyway, to save you some typing.

- `:Heytmux [OPTIONS]`
    - Run with the current file
- `:Heytmux [OPTIONS] FILES...`
    - Run with the files
- `:'<,'>Heytmux [OPTIONS]` (in visual mode)
    - Run with the given range

Use bang version of the command (`:Heytmux!`) not to move focus. It is
equivalent to passing `-d` flag to heytmux executable.

Related projects
----------------

Many of the ideas were borrowed from [Tmuxinator][tmuxinator] and
[Ansible][ansible], but Heytmux solves a different problem.

[tmuxinator]: https://github.com/tmuxinator/tmuxinator
[ansible]: https://github.com/ansible/ansible

There are also other projects that are similar to tmuxinator.

- [teamocil](https://github.com/remiprev/teamocil)
- [tmuxp](https://github.com/tony/tmuxp)

#### How is this different from tmuxinator?

With Tmuxinator, you can manage session configurations each of which defines
the initial layout of a tmux session.

On the other hand, Heytmux does not care about sessions, instead it simply
creates windows and panes on the current session, and it only creates the ones
that don't exist. So it can be used not only to bootstrap the initial
workspace, but also to send commands to any subset of the existing panes,
which means you can use it for scripting your tasks that span multiple tmux
windows and panes. Heytmux somehow feels like a hybrid of Tmuxinator and
Ansible.

I primarily use Heytmux to write Markdown documents with fenced code blocks of
YAML snippets that I can easily select and run with Heytmux in my editor.

License
-------

MIT
