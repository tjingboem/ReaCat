# ReaCat — working notes

Started 23 November 2026 by tjingboem. The catalogue of envelopes for the whole family: every script that makes a curve "sends to ReaCat and the
world", every script that needs a curve takes one from the catalogue. **Read `doc/ReaCat_Spec.md` first** (format "ReaCat 1", the shelf lib, the picker, the
window, the migration order). Decisions are marked in section 10 of the spec.

## What is here
- `doc/ReaCat_Spec.md` — the spec (his decisions of 23 Nov 2026 are in it).
- `lib/ReaCat.lua` — the core, PURE LUA (no ReaImGui): send / list / get / newest / touch / tags / update / delete / undelete / cleanup limit / boolean search (`query`).
  An identical copy goes into every tool that sends or receives (a test that compares the copies is still to be written).
- `lib/ReaCatPicker.lua` — the picker widget (ReaImGui): thumbnails drawn from the points, search box, date filter, sort, tag chips, info panel, tag editing,
  Original range; `browser = true` adds select / delete / undo / send again / cleanup and the limit setting.
- `ReaCat.lua` — the window (load it into the Actions list). `tools/seed_samples.lua` — puts ten sample curves (tag `sample`) into the catalogue to try it.
- Tests: `lua5.4 tests/test_reacat.lua` (the lib, offline, 121 checks), `lua5.4 tests/test_picker_logic.lua` (filters, clicks, selection, delete, project chip, 35 checks),
  `RT_REACAT=$PWD tests/run_in_reaper.sh $PWD/tests/window_smoke.lua` (the real window and the picker draw frames in a REAPER of its own; with `SHOT=<png> CROP=WxH+X+Y`
  a screenshot of that part of the desktop is made: never save the whole desktop). The catalogue of that REAPER is its own; yours is not touched.

## State (23 Nov 2026)
- Lib and picker built and tested; the window drawn in a REAPER of its own and looked at in screenshots. NOT yet used with the mouse by tjingboem.
- Not built: pin / window place / one window / ReaSnap pieces for the ReaCat window; the senders (ReaNvelopes, `CurveUI.draw`, MinervaCL Editors); the receivers
  (MinervaCL Import, ReaMaskM, ReaShapeM); retiring `CurveShare.lua` and `reaac_series.lua`. See the migration list (spec section 9).
- Interactions only a mouse can test: click / double-click / Ctrl+click / right-click on thumbnails, typing in the tag and note fields, the cleanup window.
  Their logic is tested offline (`_click`, `_sendAgain`, `_delete`).
- A listing reads every file; if it gets slow near 2000 entries, add a header cache.

## Rules
- Commit and push only on his word, after he has tried it in REAPER.

## 23 Nov 2026, later: the project name and smaller thumbnails (his requests)
- Every send writes the REAPER project name (without .RPP; "Unsaved Project" when the project has no file yet) as the header key `project=`: a FIXED tag, not in `tags`,
  not removable, kept when the same thing is sent again, shown in AMBER (chips and the info panel). `tag:"name"`, `project:part` and plain words find it. `ReaCat.projectName()`.
  The name is looked up with `GetProjectName(0)`; in the test REAPER it is always "Unsaved Project". Not tried with a saved project in his REAPER.
- Thumbnails 96 x 54 (were 120 x 68), the label under them is "source name" (the source gives way when the room is short, so the name stays readable). Tag chips in the info panel wrap.

## Migration step 4a: ReaNvelopes sends (23 Nov 2026) — built, tested offline and in a REAPER of its own, NOT yet used by tjingboem
- ReaNvelopes OUTPUT target 4 is now "Send to ReaCat and the world" (button "SEND TO REACAT"): `ReaNvelopes/lib/ReaCatSend.lua` fits the curve with `CurveShare`, stores it with
  `ReaCat.send` (source "ReaNvelopes", name RAND / OSC / DRAW, project tag, shape word). TEMPORARY: it also writes the old one-slot place, so ReaMaskM / ReaShapeM "Take Curve"
  keep working until step 5; then `CurveShare.send` and `CurveShare.lua` go (step 6). `ReaNvelopes/lib/ReaCat.lua` is an identical copy (`lua5.4 tests/check_copies.lua`).
- Tests in ReaNvelopes: `lua5.4 tests/test_reacat_send.lua` (14 checks), `tests/hub_smoke.lua` (15, real hub in a REAPER of its own, still passes).
- Tags in the picker are pills (rounded). Next: `CurveUI.draw` (the nine ReaAC editors), MinervaCL Editors, then the receivers.

## Design of 23 Nov 2026 (late): provenance, "used" borders, snapshots — see spec section 11. Nothing built yet.
Decided by tjingboem: Option A for snapshots (with a hidden project ID next to the visible amber name), every write also files a copy in ReaCat, usage shown as a red border + a list in the info panel + click to select the item,
item NOTES for the item side with a setting "also add to the item name" (off by default), receivers get "Latest" (newest of the kind, any source) and "ReaCat..." (the picker as a popup).
Not yet confirmed: the embedded popup (vs the real ReaCat window) and the "Open the ReaCat window" button; the second border colour for "used in another project".

## Step 1 of spec section 11 built (23 Nov 2026): the lib — tested offline (61 checks in `tests/test_reacat_provenance.lua`), NOT yet used by any tool
`projectId`, `restore`, `export` / `exportProject`, the usage record (`useAdd`, `usage`, `usedHashes`, `usedBy`, `usePrune`), the item side (`noteWith`, `nameWith`, `markItem`, the name-suffix setting), the search word `used:`.
Details and the one thing to remember (a reference is the content hash, so identical content under other names is "used" too) are in spec 11.7. The copies of `lib/ReaCat.lua` in ReaNvelopes and ReaAC are updated (identical).
NEXT: step 2 (a write also files a copy in ReaCat; "Latest" and "ReaCat..." in MinervaCL Import, ReaMaskM / ReaShapeM Take Curve; they call `markItem`).

## Step 2 of spec section 11 (23 Nov 2026) — partly built: writes file a copy, MinervaCL Import has Latest and ReaCat... — tested offline and in a REAPER of its own, NOT yet used by tjingboem, NOT committed
- `ReaCatPicker.receiver(ctx, st, opts)`: the two buttons. "Latest" = `ReaCatPicker.latest(opts)` (the newest entry of the accepted kind, any source); "ReaCat..." opens the picker under the buttons (opts: kind, rulekind, accept + acceptKey). Returns { id, entry, originalRange, how }. The picker needs `ReaCat` as "ReaCat" or "core.ReaCat" (ReaAC keeps its copies in core/). `ReaCatPicker.label(e, maxChars)`.
- ReaAC: MinervaCL's Import popup (parameter and Rhythm tab) = Points / Low / High / As Draw or Choose / Linked + the receiver. `X.takeEntry` / `X.takeRhythm` do the work (tested without drawing), record the usage (`what = "param"`) and set the status line. `Series.fromEntry(id)`.
- A write also files a copy (tag `written`, marked used): ReaNvelopes `OutputPanel` (CC, note values, both envelope writers; `ReaCatSend.fileWritten`) and ReaAC `CurveUI.commit` (CC, velocity, envelope; `Series.fileWritten`); the item gets the notes line. `CurveOut.commitEnvelope` in ReaAC returns env and aiIdx as 6th and 7th value.
- Tests: picker logic 46, ReaAC selftest_athenacl 115, smoke_all_modules 26, ReaAC selftest_written 10, ReaNvelopes selftest_written 11 + hub_smoke 15, test_reaac_series 35.
- NOT done yet: ReaMaskM and ReaShapeM "Take Curve" (they still read the old one-slot place, which ReaNvelopes still writes); MinervaCL's own outputs; ReaCat red borders (step 3); ReaSnap (steps 4, 5).

## Step 2 finished (23 Nov 2026): ReaMaskM and ReaShapeM take curves from ReaCat — tested in a REAPER of its own, NOT used by tjingboem, NOT committed
`ReaCatPicker.receiver` got `opts.popup` (the picker in a popup of its own), `opts.buttonH`, `opts.noRange` (hide "Original range": those two tools lay the curve over the whole envelope). ReaMaskM and ReaShapeM have copies of `ReaCat.lua` and `ReaCatPicker.lua` next to their script (`tests/check_copies.lua` lists all seven copies) and keep the old button as a fallback. Live copies are updated.
The old one-slot place (`CurveShare.lua`, `tjingboem_curve/current`) can go now: step 6 of the plan (still written by ReaNvelopes' send; the fallbacks in ReaMaskM and ReaShapeM would go with it).

## Step 3 of spec section 11 (23 Nov 2026): red borders, "used in" list, select the place, cleanup order — tested offline (provenance 73, picker 49) and in a REAPER of its own (selftest_places 11, window_smoke 10); screenshot looked at; NOT used by tjingboem, NOT committed
- Picker: an entry used in the open project has a red border and a red dot (the dot stays when a selection or focus border wins); the header says "N used in this project"; the info panel lists the places ("MinervaCL: in MinervaCL", "ReaNvelopes: item ..."), a `select` button for an item or automation item (`Cat.selectPlace`: selects it and moves the edit cursor to its start), a place that no longer exists shows in red "(gone)", and the browser has "Forget the places that are gone" (`Cat.usePrune(Cat.placeExists)`). Places are looked up again every two seconds and when the usage changes. The browser's info panel is taller (250).
- Lib: `findItem(guid)`, `placeExists(rec)`, `selectPlace(rec)` (an item, or an automation item named by `ai:<envelope guid>:<index>`; a parameter inside a tool says where it is); `cleanupCandidates` proposes the entries NOT used in this project first (oldest first), the used ones only after them, favourites never.
- NOT built: the second colour for "used in another project" (a project only knows its own usage; it would need a record of its own).
- The copies of `ReaCat.lua` / `ReaCatPicker.lua` in ReaNvelopes, ReaAC, ReaMaskM and ReaShapeM are updated (check_copies: 7 same) and their tests pass again; the live copies are updated.
