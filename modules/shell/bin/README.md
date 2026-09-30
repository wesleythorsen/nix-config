# vigil

Keep the Mac awake (display on, Slack presence active) while a job runs, without
ever stealing focus or touching your windows.

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
vigil -d 2                   # focus mode: show Slack for 2 seconds (default 5s)
vigil -m jiggle              # default: invisible 1px mouse move when idle; no app switching
vigil -m focus               # old behaviour: briefly bring Slack frontmost, then restore
vigil -a Slack -a Teams      # focus mode with more than one app (implies -m focus)
vigil -m none                # just prevent sleep (alias: --no-presence)
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
keyboard or mouse event, the same signal Slack, Teams and the screensaver use).
Its own synthetic events are excluded, so "idle" always means *you* have been
idle. If you have been active within `-I` seconds it does nothing at all.
Otherwise it signals presence according to `-m`:

- **`jiggle`** (default): posts a real 1px mouse-move and back through the HID
  event tap. Every idle timer on the system resets exactly as if you had
  touched the trackpad. Nothing on screen changes. This is what actually keeps
  Slack green: merely activating the Slack window does not reset the idle
  timer, which is why a short focus dwell was unreliable.
- **`focus`**: the original approach. Records the frontmost app, activates each
  `-a` app for `-d` seconds, then re-activates the previous app. Polls once per
  second during the dwell and restores immediately on any input; leaves your
  choice alone if you switched apps yourself; skips apps that are not running.
  Slack only counts this as activity while it is frontmost, so use a long `-d`
  if you rely on this mode. Kept for machines where synthetic input is blocked.
- **`none`** (or `--no-presence`): sleep hold only.

### Output

Log lines go to stdout with a timestamp and the label:

```
18:17:56 vigil[sleep] holding awake for pid 67403; presence nudge after 120s idle, every 60s
18:17:56 vigil[sleep] you are active (idle 3s); standing by
18:19:56 vigil[sleep] idle 123s: jiggling mouse
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
| `-d, --dwell SEC` | 5 | focus mode: seconds the presence app stays frontmost |
| `-m, --mode MODE` | jiggle | `jiggle`, `focus` or `none` |
| `-a, --app NAME` | Slack | presence app for focus mode; repeatable; implies `-m focus` |
| `-q, --quiet` | off | no log output |
| `--no-presence` | off | same as `--mode none` |
| `--no-notify` | off | skip the exit notification |
| `-h, --help` | | print the header comment |
