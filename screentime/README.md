# stpoll — cross-device Screen Time reader

**Status: dead end for its original purpose.** Kept because the negative result is
worth not rediscovering, and because the local-Mac half still works.

Standalone macOS CLI. In no Xcode target — it is not part of the iOS app and is
not built by `xcodebuild`. Build it directly:

```bash
swiftc -O -o screentime/stpoll screentime/stpoll.swift
```

## What it was for

Reading iPhone Screen Time (app usage per bundle ID) from the Mac, by way of the
Screen Time data that syncs between a user's devices.

## Why it does not work

Two paths were tried. Both fail for the iPhone case.

**1. `RMAdminStore-Cloud.sqlite` — the cross-device store. Unreadable.**

```
errno=1 (Operation not permitted)
  /var/folders/…/0/com.apple.ScreenTimeAgent/Store/RMAdminStore-Cloud.sqlite
```

This is TCC, not file permissions, and Full Disk Access does not lift it — the
path sits under the ScreenTimeAgent's own container. Run `stpoll --diag` to
reproduce; it distinguishes a TCC denial (`errno=1`) from a wrong path
(`errno=2`).

**2. `knowledgeC.db` — readable, but local only.**

`stpoll --knowledge` reads it fine (Full Disk Access is enough here) and returns
thousands of `/app/usage` rows. Every one of them is local:

```
== app-usage rows per source device ==
  device=<local/null>  rows=5616  latest=2026-08-28 03:53:54
```

No `ZSOURCE.ZDEVICEID` for a phone ever appears. The iPhone's usage is simply not
in the Mac's knowledge store.

**Conclusion: iPhone Screen Time is not reachable from the Mac.** The app gets its
device data from HealthKit on the phone instead — see the main README.

## What still works

`--knowledge` and `--diag` are useful for local-Mac app usage and for TCC
triage. The default path (`RMAdminStore`) will fail on any machine.

| invocation | does |
|---|---|
| `stpoll --diag` | TCC probe: which of three known DBs are readable |
| `stpoll --knowledge` | local `/app/usage` rows per source device, top streams |
| `stpoll --schema` | dump table/column layout of the RMAdmin store |
| `stpoll [seconds]` | emit usage rows as JSONL (default 7200s lookback) |

## The launchd job

`com.nick.screentime-poll.plist` is **not installed** and should not be — on a
15-minute timer against an unreadable database it would only write errors. It is
kept as the record of the intended wiring.

## `data/` is gitignored

It holds real app-usage logs from earlier runs (personal data), and its rows use
an older field layout than `stpoll.swift` now emits — they came from a previous
iteration that read `knowledgeC.db`. Treat it as an artifact, not a fixture.
