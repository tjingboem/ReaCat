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
| `npoints` | curve (set by `send`) | How many points the body holds (so a listing can say it without reading the points). |
| `beats` | curve (optional) | The length of the curve in beats, if the sender knows it. A receiver may use it or ignore it. |
| `range` | curve (optional) | `lo,hi`: what 0 and 1 stood for at the sender (e.g. the pitch range of a walk). The catalogue never applies it; a receiver may offer "Original range" (section 7). |
| `unit` | curve (optional) | A word for the values (information). |
| `project` | all (set by `send`) | The name of the REAPER project at the moment of the send, without `.RPP`; **"Unsaved Project"** when the project has no file yet. A **fixed tag**: it is not in `tags`, the user cannot remove it, and it stays as first written (sending the same thing again from another project does not change it). Shown in **amber**. Found by `tag:"name"` (the whole name), by `project:part`, and by a plain word. A sender may give it (`project=`); otherwise the lib asks REAPER (`ReaCat.projectName()`). |
| `tags` | all (optional) | Comma separated words, no commas inside a tag. Compared without case. |
| `note` | all (optional) | One free text. |
| `fav` | all (optional) | `1` = the user marked it; a cleanup never proposes to delete it. |
| `rulekind` | rule | `value` or `rhythm` (MinervaCL: where the rule can go). |
| `seq` | all (optional) | The send counter (the `stamp` of section 4) at the moment of the send. It orders sends within one second: newest = highest `sent`, then highest `seq`. |
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

**The core is pure Lua, no ReaImGui** (decided 23 Nov 2026): the format, this lib and its tests need no GUI, so a tool that only sends loads no GUI code and the
lib is tested outside REAPER. Only the picker widget and the ReaCat window (sections 7 and 8) use ReaImGui, which every tool of the family already requires,
and they live in separate files.

One small file, **an identical copy in every tool** (the family copies shared files; a test compares the copies). It needs only `reaper.*`
(`GetResourcePath`, `RecursiveCreateDirectory`, `EnumerateFiles`, `GetExtState`, `SetExtState`) and `os`/`io`. It never uses `load()` on file text.

```
ReaCat.send{ kind="curve", source=, name=, points=, beats=, range=, unit=, tags=, note= }  ->  id | nil, message
ReaCat.send{ kind="rule",  source=, name=, text=, rulekind= }                              ->  id | nil, message
ReaCat.list(filter)      -> array of headers, newest first   (cheap: reads the header only)
ReaCat.get(id)           -> entry with points / text
ReaCat.newest(source, name)  -> id | nil                (what a link follows)
ReaCat.query(text)       -> match(header) function | nil, problem   (the boolean search, 8.1)
ReaCat.touch(id)         -> id | nil, message     (make an entry the newest without copying anything)
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

- A shared widget (`lib/ReaCatPicker.lua`, ReaImGui; `Picker.new()`, then `Picker.draw(ctx, st, { height = 420 })` every frame returns nil or `{ id =, originalRange = }`;
  `opts.kind` / `opts.rulekind` limit what is listed; `browser = true` is the ReaCat window; also a copy per tool) lists the catalogue as thumbnails; the thumbnail is **drawn from the points** (no stored picture, so
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
- Hover: information and tags in the panel under the grid. **In the ReaCat window (built 23 Nov 2026, changed from the first draft): click = look at it and edit its tags (a plain click must not
  reorder the list), double-click = send it again (it becomes the newest: it only moves `sent` and `seq`, nothing is copied; `ReaCat.touch`), Ctrl+click = select several, right-click = delete.**
  In a receiver's picker: click = take it, Shift+click = look at it and edit.
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
| `tag:smooth` | only a tag, the whole tag (`tag:"my tag"` for several words); the project name counts as a tag here |
| `project:song` | only the project name (part of it is enough) |
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
- **Fixed tag: the project name (decided 23 Nov 2026, tjingboem), amber; "Unsaved Project" when not saved yet.** Thumbnails smaller (96 x 54, were 120 x 68) so more fit.
- ~~Tags as typed or lower-cased~~ **Decided 23 Nov 2026: as typed** (compared without case). He also asked for **boolean search**, see section 8.1.
- Do other kinds follow (a note series, a pattern)? The `kind` key leaves room; none is specified now.

## 11. Provenance, "used" borders and snapshots (DESIGN decided 23 Nov 2026, tjingboem — nothing built yet)

His idea: show in ReaCat which envelopes are used in the project, and let ReaSnap bring the catalogue entries of a project back. "Just thinking about what kind of system we can build via ReaSnap."

### 11.1 Decisions
- **Snapshots: Option A.** A ReaSnap Capture stores the catalogue entries of the project; Restore puts back the missing ones (11.5).
- **The project gets a hidden ID** next to the visible name (the name is not unique: every unsaved project is "Unsaved Project"). A GUID-like string made once per project and kept in the project's own ExtState (`SetProjExtState`, section `ReaCat`, key `projectid`). Every send writes it as the header key `projectid=` (not shown, not a tag). The amber name stays what the user sees.
- **A write also files a copy in ReaCat.** "Write to envelope", "Write MIDI" and "Set note values" (ReaNvelopes, `CurveUI.commit`, MinervaCL's outputs) put the curve they wrote into the catalogue too (tag `written`; same duplicate check by hash), and mark it as used at once. Reason (his words): he intends to re-use an envelope for opening a filter, generating a note structure and more, so everything that reaches the project should be in the catalogue. The cleanup limit and the duplicate check contain the growth.
- **Item side: item NOTES (B), with a setting "also add to the item name", off by default.** Each place that takes or writes an entry adds one clean line to the item's notes: `ReaCat: <source> <name>, taken <date time>, project <name>`. With the setting on, the name also gets the suffix ` + ReaCat: <source> <name>` (his item names already read "... + ReaShapeM"). Automation items have no name or notes field: for them the information is only in the usage record and in ReaCat's panel.

### 11.2 The usage record (stored in the project, needs no ReaSnap)
Every receiver and every write adds a line to the project's ExtState (section `ReaCat`, key `usage`, saved with the project):
`<hash>|<what>|<guid>|<tool>|<label>|<date time>`  — `hash` = the entry's content hash (so a reference survives a restore, another machine and a re-added entry), `what` = item / automation item / parameter, `guid` = the item's GUID when there is one, `tool` = who took it, `label` = a short words for the panel.
One entry can be used in several places (a filter, a note structure, ...): several lines with the same hash. A line whose item is gone is stale: ReaCat checks that the item still exists before it shows the line.

### 11.3 In ReaCat
- A **red border** on an entry that is used in the open project (a second colour for "used in another project", to be chosen).
- The info panel lists where it is used ("item ReaMaskM 22 Nov 14:45 on track 3", "automation item ReaNvelopes RAND ...") and **a click selects that item** in REAPER.
- Search: `used:` finds the used ones; `NOT used:` the others. Cleanup proposes the never-used, oldest entries first.

### 11.4 Receivers: two buttons (decided: "Latest" = yes)
- **Latest**: one click takes the newest entry of the right kind (`kind`, `rulekind`), from any source. It says what it took ("took Lorenz Attractor x (Night Piece)").
- **ReaCat...**: opens the picker (11.3's widget) as a popup inside the receiver; a click takes the entry. (Proposed, not yet confirmed: an "Open the ReaCat window" button in that popup when ReaSnap can launch it.)
- A receiver records the usage line (11.2) and the notes line (11.1) when it takes an entry.

### 11.5 ReaSnap
- ReaCat becomes a ReaSnap member as far as the integration contract fits: window title with the instance number (piece 2), Close All (piece 5), single instance, a Launcher button. No settings are written onto an item (pieces 3 and 4 do not apply).
- **Capture** stores the entries with the project's `projectid`; **Restore** adds the ones that are missing (same hash = not added twice) through a lib function that keeps the original id, dates, tags, note and `projectid` (`ReaCat.restore(text)`, to write). The usage lines are in the project already, so the red borders come back by themselves.

### 11.6 Order of work
1. Lib: `projectid`, `restore`, the usage record and its reader (offline tests).
2. A write also files its copy; the receivers' "Latest" and "ReaCat..." buttons, which record usage and notes (MinervaCL Import first, then ReaMaskM and ReaShapeM Take Curve).
3. ReaCat: red borders, the info panel list, click to select, `used:` search, cleanup order.
4. ReaCat as a ReaSnap member.
5. Capture and Restore of the entries.
Each step: offline tests, then a REAPER of its own, then his own trying; commit and push on his word.

### 11.7 Step 1 built (23 Nov 2026): the lib
`ReaCat.projectId()` (made once, kept in the project's ExtState, written as the header key `projectid=` by every send; nil when REAPER cannot say); `ReaCat.newId()`; `ReaCat.export(id)` and `ReaCat.exportProject(projectid)`
(what a snapshot stores); `ReaCat.restore(id, text)` (puts an entry back as it was, never as the newest; same content = "exists"; a taken id or a bad id gets a new one; refuses broken text and another major version);
the usage record `ReaCat.useAdd / usage / usedHashes / usedBy / usePrune` (project ExtState `ReaCat/usage`, at most 2000 lines, characters % ; | and line ends escaped; every change bumps the edit counter so open windows refresh);
the item side `ReaCat.noteWith / nameWith` (pure) and `ReaCat.markItem(item, entry, { tool =, nameSuffix = })` (usage line + the notes line + the name suffix when the setting is on; `ReaCat.nameSuffixOn / setNameSuffixOn`, persistent, off by default);
the search word `used:` (alone: used in this project; `NOT used:` the others).
**The reference is the CONTENT hash** (the points, or the rule text): two entries with identical content under different names are the same thing, so both get the red border when one is used. That follows from referencing by hash (a reference survives a restore
and another machine); it is not a bug. Tests: `tests/test_reacat_provenance.lua` (61 checks). Not built yet: steps 2 to 5.
