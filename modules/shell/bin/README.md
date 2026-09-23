# vigil

Keep the Mac awake (display on, Slack presence active) while a job runs, without
ever stealing focus while you are typing.

## Quickstart

### [Hold until Ctrl-C](#hold-until-ctrl-c-1)

```sh
vigil
```

### [Run a command and hold until it exits](#run-a-command)

```sh
vigil -- nix build .#darwinConfigurations.biguy.system
vigil -- ./deploy.sh --env prod
vigil -n migration -- psql -f big-migration.sql   # custom label
```

### [Watch an existing process](#watch-a-pid)

```sh
vigil -p 48211
vigil -p "$(pgrep -x claude)"
vigil -p "$(pgrep -f 'cargo build')" -n cargo
```

### [Tune the presence nudge](#presence-nudge)

```sh
vigil -I 300                 # only nudge after 5 minutes without input (default 120s)
vigil -i 120                 # check every 2 minutes (default 60s)
vigil -d 2                   # show Slack for 2 seconds (default 5s)
vigil -a Slack -a Teams      # nudge more than one app
vigil --no-presence          # just prevent sleep; never switch apps
```

### [Quiet and notifications](#output)

```sh
vigil -q -- make test        # no log lines
vigil --no-notify -p 48211   # skip the macOS notification when the target exits
```

### [Claude Code hook](#claude-code-hook-1)

Runs automatically once activated. Manual equivalent:

```sh
vigil -p "$(pgrep -x claude)" -n claude -q --no-notify
```

### [See it in a process list](#process-title)

```sh
ps -o pid,comm,command -p "$(pgrep -f 'vigil\[')"
```

---

## Details

### Hold until Ctrl-C

With no target, vigil holds the machine awake until you interrupt it. `caffeinate`
runs underneath with `-dims` (display, idle, disk, system), so the screen stays
on and nothing sleeps. Ctrl-C releases everything.

### Run a command

Everything after `--` (or the first non-option word) is run as a child process.
vigil holds until it exits, prints its exit status, posts a macOS notification,
and exits with the same status, so it is safe in `&&` chains:

```sh
vigil -- make release && echo shipped
```

The label defaults to the command's basename. Override with `-n NAME`.

### Watch a pid

`-p PID` attaches to a process you did not start. vigil exits when that process
does. `caffeinate -w PID` is used underneath, so the sleep hold is released by
the OS even if vigil is killed. The label defaults to the process's command
name; `-n` overrides it. `--pid` and a command are mutually exclusive.

### Presence nudge

Every `-i` seconds vigil reads the macOS HID idle timer (time since the last
keyboard or mouse event, the same signal Slack and the screensaver use).

- If you have been active within `-I` seconds, it does nothing at all. Your
  windows are never touched.
- Otherwise it records the frontmost app, activates each `-a` app for `-d`
  seconds, then re-activates the app that was in front before.
- During the dwell it polls once per second. Any input restores the previous
  app immediately.
- If the frontmost app changed during the dwell (you clicked somewhere), it
  leaves your choice alone.
- Apps that are not running are skipped, never launched.

`--no-presence` disables all of this and leaves only the sleep hold.

### Output

Log lines go to stdout with a timestamp and the label:

```
18:17:56 vigil[sleep] holding awake for pid 67403; presence nudge after 120s idle, every 60s
18:17:56 vigil[sleep] you are active (idle 3s); standing by
18:19:56 vigil[sleep] idle 123s: showing Slack for 5s
18:20:01 vigil[sleep] sleep exited with status 0
18:20:01 vigil[sleep] released
```

`-q` silences them. A macOS notification fires when a watched pid or command
exits unless `--no-notify` is set.

### Process title

vigil re-execs itself once so the process appears as `vigil[LABEL]`, and the
caffeinate child as `vigil-hold[LABEL]`, in `ps`, `top`, and Activity Monitor:

```
  PID COMM               COMMAND
67438 vigil[claude]      vigil[claude] /Users/you/bin/vigil --name claude --pid 66435 ...
67443 vigil-hold[claude] vigil-hold[claude] -dims -w 66435
```

The `VIGIL_TITLED` environment variable marks the re-exec; do not set it yourself.

### Claude Code hook

`modules/claude-code/hooks/vigil` is a Claude Code hook (symlinked to
`~/.claude/hooks/vigil`, registered in `~/.claude/settings.json` per
`modules/claude-code/hooks/hooks.json`):

| Event | Action |
| --- | --- |
| `UserPromptSubmit` | start `vigil -p <claude pid> -n claude -q --no-notify` for this session, if not already running |
| `Stop`, `SessionEnd` | kill that vigil so the Mac can sleep once Claude is waiting on you |

Claude Code itself only runs `caffeinate -i` around Bash calls, which prevents
system sleep but lets the display sleep and Slack go idle. The hook covers the
whole turn. State lives in `$TMPDIR/vigil-claude-<session_id>.pid`. Set
`VIGIL=/path/to/vigil` in the environment to point the hook at a different
binary (used for testing from the repo checkout).

### Options reference

| Option | Default | Meaning |
| --- | --- | --- |
| `-p, --pid PID` | | process to watch; exit when it does |
| `-n, --name NAME` | target name / `shell` | label in the process title and log |
| `-i, --interval SEC` | 60 | seconds between presence checks |
| `-I, --idle SEC` | 120 | required idle time before a nudge |
| `-d, --dwell SEC` | 5 | seconds the presence app stays frontmost |
| `-a, --app NAME` | Slack | presence app; repeatable |
| `-q, --quiet` | off | no log output |
| `--no-presence` | off | sleep hold only, never switch apps |
| `--no-notify` | off | skip the exit notification |
| `-h, --help` | | print the header comment |
