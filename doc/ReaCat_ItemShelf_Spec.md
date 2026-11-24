# ReaCat Item Shelf — specification (DRAFT, 24 November 2026)

Status: **draft for tjingboem to read. Nothing is built. TO BE REVISED (24 Nov 2026, later): see "What REAPER already offers" in `compos/What Happens.md` entry 2 and the Soundmole look in entry 3. Sections 3 and 4 (where the files are, the file) will change: an entry can be REAPER's own item chunk or a one-track template with items; the Project Bay (Retain, comments, .ReaBay) may already do the storing, to be tried by hand first.** Written as an addition to `ReaCat_Spec.md` (read that first: format "ReaCat 1", the lib, the picker, section 11). Decisions are marked **OPEN** where he has not answered.

Written for tjingboem, who composes with cut, copied and reversed MIDI items and wants to be able to go back to what an item once was.

## 1. Three things that are not the same

1. **Numbered saves.** Save-as with the number going up. His own habit; REAPER does it; the whole project at one moment. This stays exactly as it is. The shelf does not replace it and does not touch it.
2. **ReaSnap.** Snapshots of tools and plugins, and S (reopen the tool that made the selected item, with its settings). A state of the tools. Unchanged by this spec.
3. **The Item Shelf (new).** A catalogue of MIDI items, one entry per item, that he can always go back to: what an item was when it was filed, with the notes and the settings of the tool that made it. It lives outside the project, so it survives every cut, move, delete and numbered save of the project.

The test of the difference: after cutting an item into twelve pieces and deleting half of them, numbered saves bring back the whole project of an hour ago, ReaSnap brings back the tools, and the shelf brings back **that one item** as it was, into the project as it is now.

## 2. What it is

The shelf is a new `kind=item` of the ReaCat catalogue. Same files, same lib, same picker, same search, tags, notes, favourites, trash and undo delete, the same amber project name. Nothing new to learn in the ReaCat window except that an entry is an item, with a thumbnail of its notes.

**MIDI first.** Audio items come later, when he starts rendering (he keeps MIDI as MIDI until a composition is fixed). A MIDI item is stored by its content, so the entry stays whole even if the project it came from is gone.

## 3. Where the files are  (OPEN, decision 1)

Proposed: **one shelf per composition**, in the composition's own folder, next to the `.RPP` and its subprojects:

`<folder of the project file>/ReaCatItems/`

Example: `compos/nummer01/ReaCatItems/` serves `nummer01.RPP` and its subproject `ritmiek.RPP`, because both are in that folder. It goes to the laptop and the desktop with the compos repo. The `project=` key still says which of the two the entry came from. A project that is not saved yet ("Unsaved Project") has no folder: its entries go to the general catalogue (`Data/ReaCat/`) and ReaCat offers to move them when the project is saved.

Alternative: one general catalogue (`Data/ReaCat/`), with a piece tag to filter on. Simpler; not shared between machines by itself; the composition is not self-contained.

## 4. The file

Format "ReaCat 1", `kind=item`. Header keys as in `ReaCat_Spec.md` 3.2 (`source`, `name`, `saved`, `sent`, `project`, `tags`, `note`, `fav`, `hash`), plus:

| key | meaning |
|---|---|
| `kind` | `item` |
| `itemkind` | `midi` (later `audio`) |
| `source` | the tool that made the item ("ReaMaskM", "ReaGestM", "ReaAC", "by hand") |
| `length` | the item's length in quarter notes (see 4.1) |
| `takename` | the take name |
| `color` | the item colour, if set |
| `from` | the id of the entry this one was made from (a newer version of an item, or a glue), comma separated when it came from several. Lineage; never rewritten. |
| `ext.<key>` | one line per item extension the item carries (item P_EXT), for example `ext.ReaMaskM_ItemSettings=b64:...`. This is how the tool's settings travel, so S works on a taken-back item. Written and read as they are, unknown keys kept. |

Body, after the line `midi`: one event per line, times in quarter notes from the item's start.

```
n,0.000,0.500,0,60,100          note: start, end, channel, pitch, velocity  (a trailing ,m = muted)
cc,0.250,0,74,64                controller: time, channel, number, value
pb,0.250,0,8192                 pitch bend: time, channel, 14-bit value
cp,0.250,0,40                   channel pressure
pc,0.000,0,5                    program change
x,0.000,<hex>                   anything else (text, sysex), as raw hex
```

### 4.1 Time

Stored in quarter notes (music time), so an item taken back into a project with another tempo keeps its musical shape. The picker says so; "keep seconds" can be offered later. (OPEN, decision 4.)

## 5. The ID on the item

Every item that is filed, or taken back, gets one item extension: `P_EXT:ReaCat_ItemIds` = the id (or ids, comma separated) of the shelf entries it stands for.

Tested in a REAPER of its own, 24 Nov 2026 (`compos/What Happens.md`, entry 1): an item extension **survives** split, duplicate, reverse, copy and paste onto another track, moving to another track, saving and reopening the project, copy and paste between projects, and render in place. It is **lost** by glue (and probably merge; the result is a new MIDI item). Not tested: Explode.

So the ID is the way to recognise an item in the project, not the item's GUID (new at every split) and not its notes (changed by every edit, reverse included).

## 6. Filing an item

- **File item** (a script, bindable to a key): files each selected MIDI item. The item then carries its id (section 5). Filing an item that already has an id makes a **new entry** with `from=` the old id. An entry is never overwritten: the shelf is a history. Identical content (same `hash`) is not stored twice; the item just gets the existing id.
- **Automatic filing on Generate**, as the writers already file a copy of what they wrote (`ReaCat_Spec.md` 11.1): ReaMaskM, ReaGestM and ReaAC file the item they just made, tag `generated`. A setting per tool, on by default, off in the tool's own settings window.
- ReaShapeM Apply changes an existing item. Proposed: it files the **result** as a new entry with `from=` the item's id, tag `shaped`; the item before Apply is already on the shelf if it was ever filed. (OPEN, decision 2.)
- The tool settings are read from the item's own extension, so nothing in a tool needs to change for a manual "File item".

## 7. Taking an item back

In the ReaCat window and in the picker popup (section 7 of `ReaCat_Spec.md`), two actions on an item entry:

- **Insert**: a new MIDI item at the edit cursor on the selected track, with the notes, name, colour and all `ext.` settings, and the id. Nothing in the project changes.
- **Replace selected**: the selected item gets the entry's notes, keeping its position, length and track. For "go back to what this was". One undo step.

A taken-back item can be pressed S on in ReaSnap at once, because it carries the tool's settings. The earlier warning of `What Happens.md` still holds: Generate on it rewrites it.

## 8. The red border: what is in the open project

An entry gets the **red border** when at least one item in the open project carries its id. Unlike the envelope borders (a usage record, `ReaCat_Spec.md` 11.2), this is **asked of the project**, because items are cut, copied and deleted all the time:

- While the ReaCat window (or the picker) is open, it scans the project's items about once a second and reads `P_EXT:ReaCat_ItemIds`. Delete the last piece of an entry and its border goes.
- The info panel lists the pieces ("3 items: track 2 at 12.0 s, track 2 at 20.5 s, ...") and **a click selects them** in REAPER, as decided for envelopes.
- Search: `used:` finds entries in the open project, `NOT used:` the others. (The same words as for envelopes.)
- Items with no id are ignored. Items made before the shelf existed are unknown until filed once.

## 9. Glue and keep

REAPER's glue and merge make a new MIDI item and lose the id (section 5). **Glue and keep** (a script, bindable to the key of glue) reads the ids of the selected items, runs REAPER's own glue or merge, and writes all those ids onto the result. Every entry that went into it keeps its red border; the info panel lists the glued item for each. Optionally (a setting) the result is filed as a new entry with `from=` all of those ids, so the join has its own place in the lineage.

Plain REAPER glue keeps working; it only does not keep the id. The border of an entry whose only pieces were glued that way goes out.

## 10. Search and tags

Everything of `ReaCat_Spec.md` 8.1 applies. New words: `kind:item`, `from:<id>` (everything made from an entry), `source:ReaMaskM`. The tag `generated`, `shaped`, `glued` are set by the filing in section 6 and 9; he adds his own ("bridge", "intro").

## 11. ReaSnap

No change needed first. The shelf is outside the project, so a ReaSnap snapshot does not have to store items. Later: the plan of `ReaCat_Spec.md` 11.5 (a Capture stores the catalogue entries of the project, a Restore puts the missing ones back) covers item entries too, so that a snapshot brings back the shelf entries of its time.

## 12. Not in this spec

- Audio items, render, freeze (he renders when things are fixed).
- Several takes in an item (only the active MIDI take is filed).
- Envelope or automation items.
- Any automatic action at a split: REAPER has no event for it, so pieces are recognised by the id they inherit, not by a hook.

## 13. Order of work

1. Lib: the `item` kind (write and read the file; the `midi` body from and to a take) — tested in a REAPER of its own, since reading a take needs REAPER. A round trip: item to entry to item, notes identical.
2. File item, Insert, Replace selected, in the ReaCat window and the picker. The id on the item.
3. The red border scan, the info panel list, click to select, `used:`.
4. Glue and keep.
5. Automatic filing in ReaMaskM, ReaGestM, ReaAC (and ReaShapeM if decision 2 says so).
6. ReaSnap (section 11).

Each step: offline tests where possible, then a REAPER of its own, then his own trying; commit and push on his word.

## 14. Open points (his to decide)

1. **Where the shelf lives**: one per composition in the project's own folder (proposed), or the general catalogue with a piece tag.
2. **ReaShapeM Apply**: file the result as a new entry (proposed), or only what he files by hand.
3. **Automatic filing on Generate**: on by default for every generator (proposed), or off until he turns it on per tool.
4. **Time**: quarter notes (proposed) or seconds.
5. **Glue and keep**: also file the result as a new entry (proposed on), or only keep the ids.
6. Explode and Merge were not tested for the id. If he uses them, test first.
