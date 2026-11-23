# ReaCat — specification, version 1 (DRAFT, 23 November 2026)

Status: **draft for tjingboem to read. Nothing is built.** The system is in beta, so everything here can still change.

## 1. What ReaCat is

One way for every script of the family to hand an envelope (a curve) to every other script, now and in the future.

- A script that **makes** a curve has one target: **"Send to ReaCat and the world"**. It does not know who will use the curve.
- A script that **needs** a curve has one source: **"Take from ReaCat"** (a picker with thumbnails). It does not know who made the curve.
- The **catalogue** is a folder of small text files, one per curve. The folder is the system. The **ReaCat window** is only a browser for it
  (search, tags, thumbnails, delete). A send works when the ReaCat window is closed; every tool still works without any other tool
  (the family rule).

Replaces, when all senders and receivers are converted: `ReaNvelopes/lib/CurveShare.lua` (ExtState `tjingboem_curve/current`, "ReaCurve 1"),
`ReaAC/core/reaac_series.lua` (ExtState `ReaAC_series`), the targets "Send to ReaMaskM / ReaShapeM" and "MinervaCL (send the curves)", and
the buttons "Take Curve from ReaNvelopes". MinervaCL's `.mcp` presets are NOT replaced (they hold a *way* of a parameter, not a curve).

## 2. Where the files are

`<REAPER resource folder>/Data/ReaCat/`

- One file per curve: `<YYYYMMDD>_<HHMMSS>_<nnn>.reacat` (the name without the extension is the entry's **id**; `nnn` counts within a second).
- `_trash/` holds deleted entries (ReaCat's "Undo delete"). Receivers never read it.
- Shared by all projects. Not part of any project. Nothing in a project depends on a catalogue file (an item keeps its own values).

## 3. The file format "ReaCat 1"

Plain text, UTF-8, one item per line, `\n` line ends (`\r` is ignored when reading). **Any script can write or read it without a library.**

```
ReaCat 1
kind=curve
source=ReaNvelopes
name=RAND
saved=2026-11-23 10:15:00
sent=2026-11-23 10:15:00
beats=16
range=-20,20
unit=x
tags=ReaNvelopes,RAND,smooth
note=first idea for the bridge
hash=3f9a1c20
points
0.000000,0.500000,2
0.250000,0.800000,0
0.500000,0.100000,5,0.4,0.6
1.000000,0.500000
```

### 3.1 Rules

- Line 1 is exactly `ReaCat 1`. A reader accepts any `ReaCat 1.x` line and refuses another major number ("ReaCat 2") with a message.
- Header lines are `key=value` (first `=` splits; the value is the rest of the line). Unknown keys are **ignored and kept** when a tool rewrites the file.
- The header ends at the line `points` (kind `curve`) or `text` (kind `rule`); what follows is the body, to the end of the file.
- A value holds no line end. In `note=` and `text=` a line end is written `\n` (backslash, n) and a backslash `\\`.
- **Unknown `kind`**: the receiver does not list the entry. ReaCat shows it and never deletes it on its own.

### 3.2 Header keys

| key | kind | meaning |
|---|---|---|
| `kind` | all | `curve` or `rule`. Others may be added later. |
| `source` | all | The tool that sent it, as the user knows it ("ReaNvelopes", "Strange Attractor", "MinervaCL"). |
| `name` | all | What it is within that source ("RAND", "x", "Gate"). `source` + `name` is the **link key**. |
| `saved` | all | When the entry was first made (`YYYY-MM-DD HH:MM:SS`, local time). |
| `sent` | all | When it was last sent. A send of identical content (same `hash`) only updates this line. **Newest = highest `sent`.** |
| `beats` | curve (optional) | The length of the curve in beats, if the sender knows it. A receiver may use it or ignore it. |
| `range` | curve (optional) | `lo,hi`: what 0 and 1 stood for at the sender (e.g. the pitch range of a walk). The catalogue never applies it; a receiver may offer "Original range" (section 7). |
| `unit` | curve (optional) | A word for the values (information). |
| `tags` | all (optional) | Comma separated words, no commas inside a tag. Compared without case. |
| `note` | all (optional) | One free text. |
| `fav` | all (optional) | `1` = the user marked it; a cleanup never proposes to delete it. |
| `rulekind` | rule | `value` or `rhythm` (MinervaCL: where the rule can go). |
| `hash` | all | A short checksum of kind + body (not of the header). Used to avoid storing the same thing twice. |

### 3.3 Body of a `curve`

After the line `points`: one point per line, `t,v` or `t,v,shape` or `t,v,5,c1,c2`.

- `t` and `v` are 0..1. `t` ascends; the first `t` is 0 and the last 1. At least two points, at most 2048.
- `shape` is the segment that **leaves** the point: 0 straight line (also when missing), 1 step (hold, then jump), 2 slow start and end,
  3 fast start, 4 fast end, 5 cubic curve with the handle levels `c1`, `c2` (a third and two thirds across the segment; may lie between
  -0.5 and 1.5, the curve itself stays within 0..1). The last point's shape is ignored.
- `v = 0` is the bottom, `v = 1` the top **as sent**. What the values mean is the receiver's choice.
- A sender that has evenly spaced samples (a series, a staircase) writes them as points; a staircase uses shape 1. A sender may thin them
  (the existing `Curve.thin` and the cubic fit in `CurveShare.lua` may be reused).

### 3.4 Body of a `rule`

After the line `text`: the rule text (athenaCL syntax for MinervaCL), may run over several lines. A rule is a curve's sibling, not a curve.

## 4. The signal: a counter, nothing running

ExtState section `ReaCat` (not persistent; the files are):

- `stamp`: a number that goes up by one with every send. A receiver reads it from its own frame loop (at most four times a second; one cheap read,
  no background script) and looks at the catalogue only when it changed.
- `last`: the id of the entry sent last.
- `edit`: goes up by one when tags, note or `fav` of an entry are changed (so an open picker or browser refreshes its list; links ignore it).

## 5. The shared lib `ReaCat.lua`

One small file, **an identical copy in every tool** (the family copies shared files; a test compares the copies). It needs only `reaper.*`
(`GetResourcePath`, `RecursiveCreateDirectory`, `GetExtState`, `SetExtState`) and `os`/`io`. It never uses `load()` on file text.

```
ReaCat.send{ kind="curve", source=, name=, points=, beats=, range=, unit=, tags=, note= }  ->  id | nil, message
ReaCat.send{ kind="rule",  source=, name=, text=, rulekind= }                              ->  id | nil, message
ReaCat.list(filter)      -> array of headers, newest first   (cheap: reads the header only)
ReaCat.get(id)           -> entry with points / text
ReaCat.newest(source, name)  -> id | nil                (what a link follows)
ReaCat.query(text)       -> match(header) function | nil, problem   (the boolean search, 8.1)
ReaCat.stamp()           -> string
ReaCat.update(id, {tags=, addtags=, removetags=, note=, fav=})   (addtags / removetags: lists; adds are deduplicated without case)
ReaCat.tags()            -> every tag in the catalogue with its count (for the suggestions)
   ReaCat.delete(id)   ReaCat.undelete(id)
```

- `send` writes to `<name>.tmp` and renames, so a reader never sees half a file. A missing folder is created.
- `send` adds **automatic tags**: the source, the name, and a shape word (`step` when any point has shape 1, `smooth` when 2..5, `straight` otherwise);
  the sender's own `tags` are added to those. Duplicates are removed.
- Same `hash` + same `source` + same `name` already in the catalogue: no new file; `sent` of that file is set to now and the counter goes up (so a link follows it).
- A failure (disk full, no write access) returns `nil` and a message. The sending tool shows it in its own message (a modal in ReaNvelopes) and goes on.
- `send` never deletes anything. Only the user deletes, in ReaCat (moves to `_trash/`).

## 6. Sending: one target everywhere

- Name of the target: **"Send to ReaCat and the world"**. Message on success: `sent to ReaCat: <source> - <name>` (a failure speaks in the tool's message window, as now).
- ReaNvelopes: OUTPUT target 4. The curve as shown, flips included, as control points with their shapes (`Generator.controlForSend`, which already makes them for the old send).
- ReaAC: `CurveUI.draw`'s sendName target (about 20 modules; the nine "editors" first), the module's curves normalised 0..1 as now, `range` carries the original range
  where the module knows it. Rules of Sieve, Markov and GA Rhythm go as `kind=rule`.
- MinervaCL: the Editors and the strips send a parameter's curve (the values the strip draws, normalised to the parameter's range, `range` set).
- Any future script: call `ReaCat.send` and show the message. Nothing else.

## 7. Receiving: one picker everywhere

- A shared widget (`ReaCatPicker`, in ReaCat's lib, also a copy per tool) lists the catalogue as thumbnails; the thumbnail is **drawn from the points** (no stored picture, so
  the small and the big picture are both sharp), 68 x 38 as in MinervaCL's presets; hover shows the big picture with source, name, date and tags **on screen** (no tooltip;
  his rule); search by date, tags (AND, click to combine) and text; click = take it.
- A receiver turns the points into what it needs: ReaMaskM / ReaShapeM lay them over the whole X and Y of their envelope (as Take Curve does now);
  MinervaCL samples them into a Draw or Choose (`E.importSeries`) or keeps the shape.
- **Link**: a receiver may remember `source` + `name` and follow `ReaCat.newest(source, name)` when `stamp` changes (MinervaCL's "Linked" button works this way).
- **Scale back to the original range**: when an entry has `range=lo,hi`, the picker shows it on screen ("0 = lo, 1 = hi", with `unit`) and the receiver may offer
  "Original range": it maps `v` to `lo + v * (hi - lo)` instead of laying 0..1 over its own range. The picker hands the receiver the entry with `range` and `unit`;
  the mapping is the receiver's (a receiver without a real value scale, or whose parameter cannot hold the range, does not offer it). Without `range` the choice is not shown.
  The default stays "as sent" (0..1 over the receiver's own range).
- The default of every picker is the newest entry, so "take the last one I sent" stays one click.

## 8. The ReaCat tool (the browser)

A window of its own (`ReaCat.lua`), pin / window place / one window as the other tools, ReaSnap integration pieces as far as they make sense (nothing is written on an item).

- Grid of thumbnails, newest first; sort by date or by source.
- Search: date (today, last 7 days, a range) and a search box with boolean search (8.1). Clicking a tag adds `tag:"<tag>"` to the box, joined with AND.
  Tags are shown as typed and compared without case.
- **Cleanup suggestion**: when the catalogue holds more entries than the user's limit, ReaCat shows a line "N entries (limit L): clean up?" which opens the list of
  the oldest entries without `fav` to choose from. The limit is **an option the user can change** in ReaCat's window (a number; **default 2000**; `0` = never suggest).
  Stored in ExtState section `ReaCat`, key `cleanup_after`, persistent. Nothing is deleted without the user's click, and deleted entries go to `_trash/`.
- Hover: information and tags. Click: take it (as the current "newest": it only moves `sent`; nothing is copied). Shift+click: edit tags and note.
  **Tags can be added (and removed) at any time, also long after the send:** the editor has an "add tag" field that suggests the tags already in the catalogue as you type;
  with several entries ticked (Ctrl+click) one tag can be added to, or removed from, all of them at once. Automatic tags can be removed too. The same "add tag" is in the
  picker's hover panel, so a receiver can tag an entry right after taking it ("this one worked for the bridge"). An edit rewrites the file in place (same id, same `saved`; `sent` is not changed)
  and does not bump the stamp of a send, only a separate `edit` counter, so links do not move. Right-click: delete (to `_trash/`), "Undo delete" at the bottom.
- Star = `fav`. A cleanup offers old entries without `fav` and never deletes without asking.
- The browser also **sends**: a click on an entry sets it as newest, so a receiver with a link takes it.

### 8.1 Boolean search

One search box, the same in ReaCat and in every picker (the matcher is in the lib: `ReaCat.query(text)` returns a function that says yes or no for a header, so all tools search identically).

| you write | it means |
|---|---|
| `lorenz` | the word appears in the name, source, tags or note (part of a word is enough, case ignored) |
| `lorenz smooth` | both (a space is AND) |
| `lorenz AND smooth` | both (same) |
| `lorenz OR rossler` | either |
| `NOT step` or `-step` | not this |
| `( lorenz OR rossler ) AND smooth` | brackets group; without brackets NOT binds first, then AND, then OR |
| `"first idea"` | a phrase in quotes |
| `tag:smooth` | only a tag, the whole tag (`tag:"my tag"` for several words) |
| `source:ReaNvelopes`, `name:x`, `note:bridge` | only that field (`source` and `name` match part of the text, `note` too) |

- The operators AND, OR, NOT are written in capitals; `and`, `or`, `not` are ordinary words.
- A search that does not parse (an open bracket, a quote that never closes) shows the problem in red under the box and **leaves the list unfiltered**; it never errors.
- The date filter is separate from the box (buttons / a range) and is joined to the search with AND.
- The parser is written by hand (no `load()` of the text).

## 9. Migration (nothing before it is tested in REAPER by tjingboem)

1. This spec read and agreed.
2. `ReaCat.lua` + `tests/test_reacat.lua` (offline, a stand-in `reaper`): write, read back, atomic write, dedupe, auto tags, newest, delete / undelete.
3. The picker and the ReaCat window.
4. Senders: ReaNvelopes, `CurveUI.draw` (nine editors), MinervaCL's Editors.
5. Receivers: MinervaCL Import (+ link), ReaMaskM and ReaShapeM (Take).
6. Remove `CurveShare.lua`, `reaac_series.lua` and the old targets / buttons; manuals and `CorrectionsWhilePlaying.md`.
Each step: tested offline first, then by him in REAPER; commit and push only on his word.

## 10. Open points (his to decide)

- ~~Is the catalogue folder in `Data/ReaCat/` right?~~ **Decided 23 Nov 2026 (tjingboem): yes, `<REAPER resource folder>/Data/ReaCat/`.**
- `range` and `unit` are information only. Should a receiver be able to offer "scale back to the original range"?
- A cap: after how many entries does ReaCat start to suggest a cleanup (proposal: 2000)?
- Tags: lower-case everything, or show as typed (proposal: as typed, compared without case)?
- ~~Scale back to the original range~~ **Decided 23 Nov 2026: yes**, see section 7.
- ~~Cleanup suggestion after how many entries~~ **Decided 23 Nov 2026: yes, default 2000, and the user can change it**, see section 8.
- ~~Tags as typed or lower-cased~~ **Decided 23 Nov 2026: as typed** (compared without case). He also asked for **boolean search**, see section 8.1.
- Do other kinds follow (a note series, a pattern)? The `kind` key leaves room; none is specified now.
