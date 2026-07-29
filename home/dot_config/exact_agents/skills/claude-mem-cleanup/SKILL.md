---
name: claude-mem-cleanup
description: Use this skill whenever the user says Claude Code or claude-mem is slow, heavy, high-load, spawning many Claude processes, has stale sessions, has a broken worker, or needs safe cleanup/restart of claude-mem. This skill diagnoses the exact load source, protects active Claude Code sessions, checks claude-mem worker status/pidfile/port/logs/DB, uses official worker stop/start/restart/status commands, stops only stale claude-mem child processes with evidence, and verifies recovery. Trigger for prompts like “Claude が増えてる”, “claude-mem 暴走してそう”, “worker が port を掴んだまま”, or “古い Claude セッションを安全に止めたい”.
---

# claude-mem-cleanup: safe claude-mem load diagnosis and process cleanup

Use this skill to investigate and safely reduce local load from Claude Code / claude-mem process buildup. Prefer diagnosis and minimal targeted cleanup over broad killing. The goal is to explain **why** the machine is slow, protect active work, use official service controls where available, and verify recovery.

## Operating principles

- Start read-only.

  - Collect CPU, memory, swap, disk, power/thermal, and process-family data before stopping anything.
  - Treat unknown processes as someone’s active work until proven stale.
  - Do not kill Docker, Chrome, VS Code, terminals, security/MDM agents, or user apps unless the user explicitly chooses that target.

- Prefer service-native controls.

  - For `claude-mem`, use bundled worker commands before manual process termination:
    ```bash
    bun <plugin-root>/scripts/worker-service.cjs status
    bun <plugin-root>/scripts/worker-service.cjs stop
    bun <plugin-root>/scripts/worker-service.cjs start
    bun <plugin-root>/scripts/worker-service.cjs restart
    ```
  - `scripts/worker-cli.js <start|stop|restart|status>` is also valid when present.
  - Confirm the command shape from the installed files before relying on memory; plugin builds can differ.
  - Do not use unsupported flags such as `--help` on `worker-service.cjs`; unsupported arguments can fall through to normal startup.

- Protect active Claude Code sessions.

  - Check `.in_use` marker files under the relevant Claude plugin root before killing Claude-related processes.
  - Preserve PIDs listed in `.in_use`.
  - Preserve the current Claude Code process and its direct children unless the user explicitly asks to end the current session.

- Use gentle termination first.
  - Use `TERM` for stale child processes.
  - Recheck after a short wait.
  - Use `KILL` only as a last resort for a confirmed stale holder, and explain why.

## Phase 0: Clarify cleanup scope

If the user only says “重い”, “slow”, “cleanup”, or “Claude is heavy”, state that you will first run safe read-only diagnostics. Ask only when the target is ambiguous between all macOS load and Claude/claude-mem-specific load.

If the user asks you to stop processes, still do a short diagnostic pass first so you can avoid active sessions and unrelated apps.

## Phase 1: Triage current load

Run read-only checks and summarize the top suspects.

Useful checks:

```bash
uptime
top -l 1 -n 20 -o cpu -stats pid,command,cpu,mem,threads,state,time
top -l 1 -n 20 -o mem -stats pid,command,cpu,mem,threads,state,time
memory_pressure
vm_stat
sysctl vm.swapusage
df -h / /System/Volumes/Data
iostat -d -w 1 -c 5
pmset -g batt
pmset -g assertions
ps -axo pid,ppid,%cpu,%mem,stat,etime,time,command -r | perl -ne 'print if $.<=30'
```

Also summarize process families so the user sees the cause, not just individual PIDs:

```bash
ps -axo %cpu=,rss=,command= | perl -ne '
  chomp; s/^\s+//; next unless $_;
  my ($cpu,$rss,$cmd)=split /\s+/, $_, 3;
  my $k="other";
  $k="claude" if $cmd =~ /claude/;
  $k="claude-mem worker" if $cmd =~ /claude-mem.*worker-service/;
  $k="Docker VM" if $cmd =~ /Virtualization\.VirtualMachine|com\.docker\.virtualization/;
  $k="Chrome" if $cmd =~ /Google Chrome/;
  $k="VS Code" if $cmd =~ /Visual Studio Code|Code Helper/;
  $k="Slack" if $cmd =~ /Slack/;
  $k="Tanium" if $cmd =~ /Tanium/;
  $k="Ivanti" if $cmd =~ /Ivanti/;
  $cpu{$k}+=$cpu; $rss{$k}+=$rss; $cnt{$k}++;
  END {
    for $k (sort { $cpu{$b}<=>$cpu{$a} } keys %cpu) {
      printf "%7.1f%% %8.1f MiB %4d %s\n", $cpu{$k}, $rss{$k}/1024, $cnt{$k}, $k
    }
  }'
```

Report:

- load average
- idle CPU / system CPU if available
- memory used, compressor, and swap
- top CPU process families
- whether the likely cause is one process, a service, or memory pressure

## Phase 2: If claude-mem is suspected

Use this phase when many `claude` processes exist, especially under a `worker-service.cjs --daemon` parent.

### Locate plugin root and settings

Find plugin roots and do not assume the version:

```bash
find ~/.claude/plugins/cache/thedotmack/claude-mem -maxdepth 4 -name worker-service.cjs -print
```

Read settings from `~/.claude-mem/settings.json` with the file read tool when available. Use `CLAUDE_MEM_WORKER_PORT` from settings. If unavailable, inspect process args and logs. In one observed case the port was `37777`, but do not hardcode it.

### Check official worker status

```bash
bun <plugin-root>/scripts/worker-service.cjs status
```

If `worker-service.cjs` is unavailable but `worker-cli.js` exists, inspect its local usage and status behavior first:

```bash
bun <plugin-root>/scripts/worker-cli.js --help
bun <plugin-root>/scripts/worker-cli.js status
```

If status disagrees with reality, check the PID file and port holder:

```bash
perl -0777 -pe 's/^/  /mg' ~/.claude-mem/worker.pid 2>/dev/null
lsof -nP -iTCP:<port> -sTCP:LISTEN
pgrep -af 'worker-service.cjs|mcp-server.cjs'
```

### Inspect worker children safely

Find the worker PID from status, `worker.pid`, or the port holder. Then inspect children:

```bash
ps -axo pid,ppid,lstart,etime,%cpu,%mem,stat,command -r \
  | perl -ne 'print if /^\s*\d+\s+<worker-pid>\s+/'
```

Look for stale Claude SDK generator children such as:

```text
claude --output-format stream-json --verbose --input-format stream-json --model claude-sonnet-4-5 --resume <memory-session-id> ...
```

Count by resume id:

```bash
ps -axo ppid=,command= | perl -ne '
  next unless /^\s*<worker-pid>\s+/ && /claude /;
  if (/--resume\s+([0-9a-f-]+)/) { $c{$1}++ } else { $c{"no-resume"}++ }
  END { for $k (sort { $c{$b}<=>$c{$a} } keys %c) { print "$c{$k} $k\n" } }'
```

### Protect active sessions

List active marker files:

```bash
for f in <plugin-root>/.in_use/*; do
  [ -e "$f" ] || continue
  printf '%s ' "${f##*/}"
  stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$f"
done | sort -k2,3
```

Inspect those PIDs:

```bash
ps -p <pid1>,<pid2>,... -o pid,ppid,lstart,etime,%cpu,%mem,stat,command
```

Do not terminate:

- any PID listed in `.in_use`
- the current Claude Code process
- direct children of active Claude Code sessions, unless clearly part of stale `claude-mem` work and the user approves

### Inspect database and logs

Check queue/session state:

```bash
sqlite3 -header -column ~/.claude-mem/claude-mem.db \
  "select status,message_type,count(*) n from pending_messages group by status,message_type order by status,message_type;"

sqlite3 -header -column ~/.claude-mem/claude-mem.db \
  "select status,count(*) n from sdk_sessions group by status;"
```

Map busy resume IDs to sessions:

```bash
sqlite3 -header -column ~/.claude-mem/claude-mem.db \
  "select id,content_session_id,memory_session_id,status,worker_port,prompt_counter,started_at,project,replace(substr(user_prompt,1,120), char(10), ' ') prompt from sdk_sessions where memory_session_id in ('<resume-id-1>','<resume-id-2>') order by started_at_epoch;"
```

Check recent logs:

```bash
log="$HOME/.claude-mem/logs/claude-mem-$(date +%F).log"
[ -f "$log" ] && perl -ne 'push @l,$_; shift @l if @l>300; END{print @l}' "$log" \
  | grep -E 'Failed to authenticate|OAuth|Generator|Worker|SDK|QUEUE|ERROR|aborted' \
  | perl -ne 'push @l,$_; shift @l if @l>120; END{print @l}'
```

Important clues:

- `Failed to authenticate: OAuth session expired and could not be refreshed`
- repeated `Generator auto-starting ... using Claude SDK`
- repeated `Generator aborted`
- `Worker failed to start Failed to start server. Is port <port> in use?`
- missing or stale `~/.claude-mem/worker.pid`

## Phase 3: Choose cleanup action

Before stopping anything, summarize:

- exact process group
- PIDs or count
- parent PID
- why they are stale
- what will be preserved
- expected impact

If the user has not already authorized cleanup, ask before terminating.

Good options:

1. **Restart claude-mem worker only**

   - Use when worker status/pidfile is inconsistent or worker is healthy but stale children exist.
   - Command:
     ```bash
     bun <plugin-root>/scripts/worker-service.cjs restart
     ```

2. **Terminate stale worker children**

   - Use when many old `claude` children are under one `claude-mem` worker and current `.in_use` PIDs are protected.
   - Prefer a script that:
     - selects only children of the worker PID
     - excludes `.in_use` PIDs
     - excludes the current session
     - optionally excludes processes newer than the current investigation start
     - sends `SIGTERM`
   - Recheck after 5 seconds.

3. **Official stop/start**

   - Use when a full worker reset is needed:
     ```bash
     bun <plugin-root>/scripts/worker-service.cjs stop
     bun <plugin-root>/scripts/worker-service.cjs start
     ```

4. **Port-holder cleanup**
   - Use only when official stop fails and the port remains held.
   - Follow docs-style escalation:
     ```bash
     lsof -nP -iTCP:<port> -sTCP:LISTEN
     kill -TERM <pid>
     ```
   - Use `kill -9 <pid>` only if `TERM` fails and the PID is confirmed stale.

Avoid:

- broad `pkill claude`
- killing all `bun`
- killing all `node`
- killing all Docker/Chrome/VS Code processes as a side effect

## Phase 4: Verify recovery

After cleanup, verify:

```bash
bun <plugin-root>/scripts/worker-service.cjs status
perl -0777 -pe 's/^/  /mg' ~/.claude-mem/worker.pid 2>/dev/null
lsof -nP -iTCP:<port> -sTCP:LISTEN
pgrep -af 'worker-service.cjs|mcp-server.cjs'
uptime
ps -axo pid,ppid,%cpu,%mem,stat,etime,time,command -r | perl -ne 'print if $.<=30'
```

Recompute the process-family summary from Phase 1.

For `claude-mem`, also verify:

```bash
sqlite3 -header -column ~/.claude-mem/claude-mem.db \
  "select status,message_type,count(*) n from pending_messages group by status,message_type order by status,message_type;"

log="$HOME/.claude-mem/logs/claude-mem-$(date +%F).log"
[ -f "$log" ] && perl -ne 'push @l,$_; shift @l if @l>200; END{print @l}' "$log" \
  | grep -E 'Worker started|Worker restarted|Worker already running|Failed to authenticate|Generator|ERROR' \
  | perl -ne 'push @l,$_; shift @l if @l>80; END{print @l}'
```

A good recovery report includes:

- before/after process counts
- before/after CPU/memory by process family
- worker PID/port/status
- whether queue is empty or still processing
- any remaining root cause, such as expired OAuth
- whether follow-up login/restart is needed

## Report template

Use a concise report like this:

```markdown
## 原因

- 主因: ...
  - evidence...
  - why it matters...

## 実施した cleanup

- 対象: ...
  - stopped PIDs/count...
  - preserved active sessions...

## 検証結果

- load: before → after
- claude/worker process count: before → after
- worker status: ...
- queue/logs: ...

## 残っている対応

- ...
```

## Known claude-mem incident pattern

In one observed incident:

- `claude-mem` worker PID had about 149 stale Claude SDK generator children.
- Many children were `claude --output-format stream-json --input-format stream-json --model claude-sonnet-4-5 --resume <memory-session-id>`.
- `claude` processes consumed roughly `396% CPU / 21.9 GiB RSS`.
- `~/.claude-mem/claude-mem.db` had many `sdk_sessions.status='active'` rows.
- Logs contained `Failed to authenticate: OAuth session expired and could not be refreshed`.
- Terminating stale worker children, then running official worker restart, restored `worker.pid` and reduced `claude` load drastically.

Treat this as a pattern to recognize, not as hardcoded PIDs or ports.
