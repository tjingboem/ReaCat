# ReaCat Item Shelf — specification (DRAFT, revised 25 November 2026)

Status: **DECIDED 25 Nov 2026: the item shelf is REAPER's Project Bay (section 3, route A). Nothing is to be built. Sections 4 to 13 describe route B (ReaCat files) and are SHELVED, kept only in case he misses tags, search, lineage or the red border of pieces.** The decision follows his hand tests of the Project Bay (`compos/What Happens.md` entries 7 to 24). Section 2a says what the bay does and does not do. Section 5 and section 9 are corrected with his tests of 25 Nov. Written as an addition to `ReaCat_Spec.md` (read that first: format "ReaCat 1", the lib, the picker, section 11). Decisions are marked **OPEN** where he has not answered.

Written for tjingboem, who composes with cut, copied and reversed MIDI items and wants to be able to go back to what an item once was.

## 1. Three things that are not the same

1. **Numbered saves.** Save-as with the number going up. His own habit; REAPER does it; the whole project at one moment. This stays exactly as it is. The shelf does not replace it and does not touch it.
2. **ReaSnap.** Snapshots of tools and plugins, and S (reopen the tool that made the selected item, with its settings). A state of the tools. Unchanged by this spec.
3. **The Item Shelf (new).** A catalogue of MIDI items, one entry per item, that he can always go back to: what an item was when it was filed, with the notes and the settings of the tool that made it. It lives outside the project, so it survives every cut, move, delete and numbered save of the project.

The test of the difference: after cutting an item into twelve pieces and deleting half of them, numbered saves bring back the whole project of an hour ago, ReaSnap brings back the tools, and the shelf brings back **that one item** as it was, into the project as it is now.

## 2. What it is

The shelf is a new `kind=item` of the ReaCat catalogue. Same files, same lib, same picker, same search, tags, notes, favourites, trash and undo delete, the same amber project name. Nothing new to learn in the ReaCat window except that an entry is an item, with a thumbnail of its notes.

**MIDI first.** Audio items come later, when he starts rendering (he keeps MIDI as MIDI until a composition is fixed). A MIDI item is stored by its content, so the entry stays whole even if the project it came from is gone.

## 2a. What REAPER's Project Bay already does (his tests, 25 Nov 2026)

All of this was tried by him in REAPER 7.86 (`compos/What Happens.md` entries 7 to 17); nothing here is read from the guide alone.

**It does:**
- lists MIDI and audio items, with where they are in the project and how many times (usage); plays them back (MIDI or audio);
- keeps an entry after the item is deleted from the project (Retain, set per row; the menu option "Automatically retain media items when removed from project" was ON) and after a restart, with an empty project ("available" rows against "active" rows);
- saves and loads as a **.ReaBay** file, and works in a NEW project: the item goes back at the cursor, with the notes as they were kept (cut up, notes deleted), and **S opens the settings it was created with** (ReaGestM, tried);
- holds several versions of one item side by side: a copy added with "Add selected items" before cutting gets its own entry and stays as it was when the original is cut and reversed (entry 9);
- names ReaGestM items by tool plus date and time of Generate (`ReaGestM 2026-11-25 11:48:35`), so different Generates tell apart; a comment can be put on the main item.

**It does not:**
- fill itself, as tested: not a new named bay, not a hand-drawn item, not a Generate (entries 13, 15, 16). **CORRECTED (25 Nov 2026): a second bay window ("New project bay window") DID fill itself with all the items of the project (entry 21); it was the named and the loaded bay that did not. Forum:** two forum users say the bay should list the project's media by itself, if the Bay dropdown at the top is set to "Current project"; he may have been in a named or loaded bay all the time (`What Happens.md` entry 20). To be tested before this line is trusted. Each item has to be added by hand with "Add selected items" (the Retain dot of an added row is then set);
- list cut pieces, in the bays he had at first (named or loaded): they were not entries, and S on a piece shows the settings of the original. **CORRECTED 25 Nov 2026:** in a second Project Bay window ("New project bay window") every item of the project is there by itself and a split adds two items by himself (`What Happens.md` entry 21);
- bring back the track or the instrument (paste at the cursor on a track he makes first, with a synth);
- tag, favourite, search beyond name, path and comment, or show a thumbnail of the notes, and it has no lineage ("made from").
- Not known: whether "Add selected items" is an action that a script can call. The guide does not mention it. This decides whether the bay could be filled by a Generate (section 3).

## 3. Where the entries live: the Project Bay (DECIDED, 25 Nov 2026)

**His decision: route A is the answer.** The item shelf is REAPER's own Project Bay. Nothing is built; no script, no ReaCat file, no new kind in the catalogue. In his words, the only small disadvantage is the manual retaining or not, and that is the price: much better than having to build a new script.

**How it is used** (each step tried by him, `compos/What Happens.md` entries 7 to 24, except where marked):
1. Open View, Project Media/FX Bay, and in its Options menu "New project bay window". That second window lists every item of the project by itself, audio and MIDI, with usage and place, and shows the two pieces of a split at once (entry 21). The first bay he used (a named or a loaded one) does not follow the project; this one does.
2. To keep what is in the project, also what he deletes later: Actions, "Retain all items" (entry 24; guide 12.6: it marks every item of the current page to stay in the bay). A single item can be marked by hand with the dot in its Retain column. Items made after "Retain all items" are probably not marked yet: repeat it (not tested).
3. The bay is kept in the saved project file, with the retained items, also those not on the timeline (entry 24). So a numbered save (Ctrl+Alt+Shift+S) carries the catalogue along, and an old numbered version holds the bay as it was then.
4. Taking an item back: choose its entry, insert it at the cursor (entry 7), on a track that has an instrument (the track and the instrument do not come back). The item has the notes as they were kept and S opens the settings it was created with (entries 8, 10, 11).
5. To another project: save the bay as a .ReaBay (the Bay field) and load it there; the item comes with its notes and its settings (entries 10, 11). Tried with a bay made by hand; the .ReaBay of the self-filling bay is not tested.
6. A version of one item next to the changed one: a copy made before cutting is its own entry and stays as it was when the original is cut and reversed (entry 9, tried with "Add selected items" in the first bay; with a copy in the self-filling bay not tried).

**The price:** marking what to retain (step 2) and remembering it. Nothing fills itself with items that were not marked and are deleted (not tested: whether an unmarked deleted item disappears).

**What this does NOT give**, and what route B (sections 4 to 13) was for: tags, favourites and a search of the ReaCat kind (the bay filters on name, path and comment only); a "made from" lineage; a thumbnail of the notes; the red border and the list of pieces in the project (the bay lists the pieces, but S on a piece still opens the settings of the original, entry 8); filing by itself on Generate in a bay he did not open; the track and the instrument. **Route B is shelved, not deleted:** sections 4 to 13 stay as written in case he misses one of these things. Then they are the plan, to be read again against what the bay does by then.

**Still to test** (small): an unmarked deleted item; "Retain all items" for later items; the .ReaBay of the self-filling bay; comments and names of the pieces; whether the second bay window opens again by itself in a new session (not stated).

## 4. The file (route B only: SHELVED, 25 Nov 2026; sections 4 to 13 are not planned, see section 3)

Format "ReaCat 1", `kind=item`. Not needed for route A. One thing in common with the bay, tested: the notes in a kept entry are the notes of the moment it was added, while the settings are the ones the item was created with, so the two can differ (`What Happens.md` entry 11); a ReaCat entry has the same two parts. Header keys as in `ReaCat_Spec.md` 3.2 (`source`, `name`, `saved`, `sent`, `project`, `tags`, `note`, `fav`, `hash`), plus:

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

Tested in a REAPER of its own, 24 Nov 2026 (`compos/What Happens.md`, entry 1): an item extension **survives** split, duplicate, reverse, copy and paste onto another track, moving to another track, saving and reopening the project, copy and paste between projects, and render in place. Tested by him, 25 Nov 2026 (entries 6 and 7): it also survives **stretching**, and it is **lost** by glue, **Explode and Merge** (his result: S no longer brings back the settings, so the tool's own item extension is gone; the ReaCat id, an extension of the same kind, would go the same way, not tried).

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

A taken-back item can be pressed S on in ReaSnap at once, because it carries the tool's settings (the bay does the same, tried by him). The earlier warning of `What Happens.md` entry 1 (Generate on an item rewrites it) is NOT confirmed: his observation with ReaGestM is that Generate adds a new item (entry 13). Not settled for ReaMaskM. The track and the instrument do not come back with an inserted item, as with the bay; a track template could do that, not tested.

## 8. The red border: what is in the open project

An entry gets the **red border** when at least one item in the open project carries its id. Unlike the envelope borders (a usage record, `ReaCat_Spec.md` 11.2), this is **asked of the project**, because items are cut, copied and deleted all the time:

- While the ReaCat window (or the picker) is open, it scans the project's items about once a second and reads `P_EXT:ReaCat_ItemIds`. Delete the last piece of an entry and its border goes.
- The info panel lists the pieces ("3 items: track 2 at 12.0 s, track 2 at 20.5 s, ...") and **a click selects them** in REAPER, as decided for envelopes.
- Search: `used:` finds entries in the open project, `NOT used:` the others. (The same words as for envelopes.)
- Items with no id are ignored. Items made before the shelf existed are unknown until filed once.

## 9. Glue and keep

REAPER's glue, merge and explode make new MIDI items and lose the id (section 5; Explode makes several items, each would need the ids written on it). **Glue and keep** (a script, bindable to the key of glue) reads the ids of the selected items, runs REAPER's own glue or merge, and writes all those ids onto the result. Every entry that went into it keeps its red border; the info panel lists the glued item for each. Optionally (a setting) the result is filed as a new entry with `from=` all of those ids, so the join has its own place in the lineage.

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

0. **Route A or route B: DECIDED 25 Nov 2026, route A (the Project Bay).** The points below are all route B and are shelved with it.
1. **Where the shelf lives** (route B): one per composition in the project's own folder (proposed), or the general catalogue with a piece tag.
2. **ReaShapeM Apply**: file the result as a new entry (proposed), or only what he files by hand.
3. **Automatic filing on Generate**: on by default for every generator (proposed), or off until he turns it on per tool.
4. **Time**: quarter notes (proposed) or seconds.
5. **Glue and keep**: also file the result as a new entry (proposed on), or only keep the ids.
6. Explode and Merge: tested by him 25 Nov 2026, they lose the tool's settings (like glue). So "glue and keep" would need an "explode and keep" and a "merge and keep" too, or he avoids them on filed items.
7. **Which tests are still missing:** whether "Add selected items" can be called by a script; whether a ReaCat id would be lost by Explode and Merge as the tool's settings are; whether Generate in ReaMaskM adds or rewrites (entry 13).
