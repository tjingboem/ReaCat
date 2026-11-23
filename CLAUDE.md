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
Not yet confirmed: the embedded popup (vs the real ReaCat window) and the "Open the ReaCat window" button; (the second border colour for "used in another project" was rejected, see below).

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
- DECIDED AGAINST (tjingboem, 23 Nov 2026): a second colour for "used in another project". It would not help the composer, every project keeps its own copy of what it uses, and it would need a record that all projects update. Do not propose it again.
- The copies of `ReaCat.lua` / `ReaCatPicker.lua` in ReaNvelopes, ReaAC, ReaMaskM and ReaShapeM are updated (check_copies: 7 same) and their tests pass again; the live copies are updated.

## Step 4 (23 Nov 2026): ReaCat is a ReaSnap member — tested (selftest_snap 16 in a REAPER of its own; ReaSnap's run_selftest 23), NOT tried by tjingboem, committed in part
`lib/ReaSnap_Integration.lua` = pieces 2 (title "ReaCat #n") and 5 (Close All); `ReaCat.lua` keeps to ONE window (ExtState `ReaCat_Window`: a stamp renewed by the open window's own frame loop twice a second, older than 2 s = gone; a second start sets `focus` and ends, the open window raises itself); without ReaSnap the window is plainly "ReaCat". ReaSnap's `KNOWN_SCRIPTS.ReaCat` holds the command id of `~/Claude/ReaCat/ReaCat.lua` (loaded from the repo folder).
NEXT: step 5, Capture and Restore of the project's catalogue entries by ReaSnap (`ReaCat.exportProject`, `ReaCat.restore`); then step 6 (retire the old one-slot place).

## Step 5 (23 Nov 2026): ReaSnap captures and restores the project's catalogue entries — tested in ReaSnap's selftest in a REAPER of its own (33 checks, incl. a 36 KB entry), NOT tried by tjingboem, NOT committed
Details in spec 11.8. Lib: `exportProject(projectid, includeUsed)` (the project's own + the ones it uses), `restore` leaves entries in the trash alone. ReaSnap has a copy of `ReaCat.lua` (check_copies lists eight copies). The ReaCat window does not yet offer "restore the entries of this project" by itself (a possible small addition: ReaSnap's Restore does it).
NEXT: step 6, retire the old one-slot place (`CurveShare.lua`, `tjingboem_curve/current`, the fallbacks in ReaMaskM / ReaShapeM, ReaNvelopes' temporary extra write), after tjingboem has tried the new buttons.

## Manuals (23 Nov 2026) — written / patched, then RENDERED with LibreOffice and the changed pages looked at (the manuals open; see below how), NOT read by tjingboem, NOT committed
- **`doc/ReaCat.odt`** (new, about 3,200 words, 5 tables): built by `doc/manual_src/build_manual.py` from ReaNvelopes' manual as the template (its styles, meta, manifest); plain ODF, the contents list is static (no page numbers until "Update Index" in LibreOffice). Facts come from the code and the tests, not from running the window by hand.
- The other manuals were patched by scripts kept here: `doc/manual_src/patch_other_manuals.py` (ReaNvelopes_Manual.odt: section 6.4 now "send to ReaCat and the world", the filing of written curves, the settings paragraph; ReaMaskM.odt and ReaShapeM.odt: Take a curve from ReaCat; ReaAC.odt: the fifth Target in every module chapter (nine identical paragraphs), the Overview paragraphs, the MinervaCL chapter's Import and Rules paragraphs) and `doc/manual_src/patch_reasnap_manual.py` (ReaSnap.docx: the Launcher list, a table row and footnote (6), a section ReaCat, the taking of a curve, Moving a project). Backups `<manual>.bak-2026-11-23-preReaCat` sit next to each (untracked). `odt_edit.py` is the small helper. The scripts refuse to run a second time (the text they replace is gone).
- Not done: the PDFs (he does them), pictures, the ReaAC chapters on the nine editors only say "Send to ReaCat and the world" (the scaling sentences were left as they were).
- The window got one more control for the manual's sake: the box "Also add the curve to the item's name when a tool uses it on an item" (the setting of `ReaCat.nameSuffixOn`, off by default) in the bottom of the browser.

**LibreOffice DOES run here** (tjingboem, 23 Nov 2026: the library is in /usr/lib/libreoffice/program; the old note "libreglo.so missing" was a library PATH problem): `LD_LIBRARY_PATH=/usr/lib/libreoffice/program soffice --headless -env:UserInstallation=file:///tmp/<own profile dir> --convert-to pdf --outdir <dir> <file>`; then `pdftotext -f N -l N` to find pages and the Read tool with `pages` to look at them. Checked this way: ReaCat.odt (12 pages), ReaNvelopes 6.4, ReaMaskM, ReaSnap.docx (table row, section ReaCat) and ReaAC (Output Target, One Window, Import). Further small fixes to ReaSnap.docx after rendering: `doc/manual_src/patch_reasnap_manual_fix.py` (the shade of the ReaCat table row, a row for ReaCat.lua in the list of files) and `patch_reasnap_manual_bold.py` (bold lead words). The contents list of ReaCat.odt is still static (no page numbers: "Update Index" in LibreOffice).

## Step 6 (23 Nov 2026): the old one-slot place is retired — tested (ReaNvelopes send test, ReaMaskM / ReaShapeM take tests, the hub smoke tests), NOT committed
- ReaNvelopes: `lib/CurveShare.lua` is now `lib/CurveFit.lua` (git mv): only the fitting of a curve (control points, cubic pieces) remains, used by `ReaCatSend`; the ExtState slot (`tjingboem_curve/current`), `CurveShare.send` and the temporary extra write are gone.
- ReaMaskM and ReaShapeM: `read_reacurve(entry)` reads only a catalogue entry; the old button "Take Curve from ReaNvelopes" is gone. Without `ReaCat.lua` / `ReaCatPicker.lua` next to the script a grey note stands in the place of the buttons.
- A stale persistent value `tjingboem_curve/current` may still sit in his reaper-extstate.ini: harmless, nothing reads it any more.
- The migration of spec section 9 is complete (steps 1 to 6). The ReaMaskM manual says so (`doc/manual_src/patch_step6_manuals.py`).

## Tag chips: two lines, scroll sideways, project tags first (23 Nov 2026, his request) — drawn in a REAPER of its own and looked at; wheel and Home NOT tried by hand, NOT committed
The tags of the window are in a child of two lines with a HORIZONTAL scrollbar: each tag goes at the end of the shorter of the two lines (most used at the left, both lines about equally long); the mouse wheel scrolls sideways while the pointer is over them, Home goes back to the start (not while a field is being typed in); the limit of 40 chips is gone. Order: the amber project tags first, then the rest, each group by number of curves, ties alphabetically. Manual 3.1 says so (rebuilt). Copies of the picker in ReaAC, ReaMaskM, ReaShapeM updated (the tool popups show the same chips).

## ReaMaskM sends too: one dropdown (23 Nov 2026) — see ReaMaskM/CLAUDE.md
`ReaCatPicker.takeLatest(opts)` and `ReaCatPicker.popup(ctx, st, popupId, opts)` were added for a tool that has a menu of its own instead of the two buttons of `receiver` (ReaMaskM: one dropdown under the preset name with Latest / Open ReaCat / Send to ReaCat and the world). The picker tests pass 54. Copies updated everywhere.

ReaShapeM has the same one dropdown and a Send for its selected envelope (23 Nov 2026), see ReaShapeM/CLAUDE.md.

## No labels under the thumbnails, no red dot (23 Nov 2026, his request) — drawn in a REAPER of its own and looked at, NOT committed
The text under each thumbnail (it was cut to about 13 characters and told little the information panel does not say) and the red dot in the corner are gone: a used curve has only the red border (it gives way to the selection colours while the curve is selected or under the pointer; the panel still says "used in this project"). A row is a thumbnail plus 6 px (was +22), so more fit. `ReaCatPicker.label` and its tests were removed. Manual 3.1 and 6.1 say so (rebuilt). Copies updated in ReaAC, ReaMaskM, ReaShapeM and the live folders.

## A Send button in the information panel (23 Nov 2026, his request) — drawn in a REAPER of its own and looked at, NOT used with the mouse by tjingboem, NOT committed
In the ReaCat WINDOW (`browser = true`, not in the tool popups) the information of a selected curve has a button **Send** **under the large picture, green, 70 px wide, in the middle under the picture with 6 px extra space above it (it was the full width and too large) (moved there at his request, with no grey hint on the screen: the remark that the other tools take it with Latest is in the manual only)**: `Cat.touch(id)`, the same as a double-click on the picture: the curve becomes the newest, so "Latest" in ReaMaskM, ReaShapeM, MinervaCL takes it with no second search; the bottom line says "sent: ... (now the newest: Latest takes it)". Manual 3.4 and 5.1. The window_smoke test windows were moved apart (they overlapped in screenshots).

## Information panel: words scroll, picture and Send stay (23 Nov 2026, his request) — drawn in a REAPER of its own and looked at, NOT committed
The words on the right of the information panel are in a child of their own (`##infotext`) with its own scrollbar, so a long "used in this project" list scrolls while the large picture and the Send button stay put. 8 px of space between the three sections (name and dates / tags, note, keep / used in this project). Copies updated in ReaAC, ReaMaskM, ReaShapeM and the live folders.

## Migration step 4 finished: MinervaCL's Editors now send rules too, not only curves (23 Nov 2026) — tested offline (411 engine checks unchanged) and in a REAPER of its own (selftest_athenacl: 115 -> 121 checks), NOT tried by tjingboem, NOT committed
Spec section 9's migration list, step 4 (Senders: ReaNvelopes, `CurveUI.draw` nine editors, MinervaCL's Editors) is now complete for all three. ReaNvelopes and the nine editors already sent curves (and some already sent synthesised rules: Sieve, Markov, GA Rhythm); MinervaCL's own module-wide "Send to ReaCat and the world" (`CurveUI.commit` target 5, built earlier) sent only the derived 0..1 curves of its parameters and rhythm — never the athenaCL rule text itself, even though MinervaCL's own Import already knows how to take a `kind=rule` entry back (`X.takeEntry` / `X.takeRhythm`). The gap: `doCommit()` called `CurveUI.commit(..., nil, "ReaAC: MinervaCL")` with the trailing `rules` argument (the 6th parameter of `CurveUI.M.commit`) simply omitted.
Built `modules/athenacl/reaac_athenacl.lua`'s `X.outputRules()` (ReaAC repo), mirroring `X.outputCurves()`: one `{name=info.title, kind="value", text=E.shownText(p, S.start, S.finish)}` per `E.PARAMS` entry (Amplitude, Controller, Octave, Field, Speed — the Text view's own text, athenaCL's real syntax, not a translation), plus one `{name="Rhythm", kind="rhythm", text=E.rhythmText(S)}` (handles both Text and strips mode by itself). `doCommit()` now passes it as the 6th argument. Unlike Sieve/Markov/GA Rhythm, which build an athenaCL-*equivalent* rule from their own simpler controls (`core/reaac_rules.lua`), this is MinervaCL's actual athenaCL text — importing it back (by MinervaCL itself, or anything else that reads a `rule`) restores a real generator, not a frozen curve.
Spec section 6 updated to describe this. Tested: `tests/test_reaac_athenacl_engine.lua` still 411/411 (no engine change); `tests/selftest_athenacl.lua` gained stage 9.5 (121 checks, was 115): sets `target=5`, commits, confirms via `core.ReaCat` that a rule entry exists for Amplitude (`rulekind=value`, text matching `E.shownText` exactly) and for Rhythm (`rulekind=rhythm`), and that the curves are still sent alongside (unchanged). Deployed to the live Scripts copy via `sync_to_reaper.sh`. **Confirmed the same day in his real REAPER** (a real session, real Python/athenaCL: 47 notes generated, then "sent 9 curves and 6 rules to ReaCat (MinervaCL)" into his real catalogue — the real Amplitude rule text came back as `rb,0.4,0.4,0.7,0.9`), driven by a small script rather than his own mouse clicks; committed and pushed (ReaAC `94f9453`, ReaCat `16d5480`).
Migration status now: step 4 (senders) complete; step 5 (receivers: MinervaCL Import, ReaMaskM/ReaShapeM Take) already complete (see earlier entries); step 6 (remove the old one-slot place) done for the pieces reachable from this machine — `CorrectionsWhilePlaying.md` and the manuals it's bundled with live in a `ReaTjingboem` repo this machine cannot reach (no such GitHub remote found under `tjingboem/ReaTjingboem` or `tjingboem/reatjingboem`; likely desktop-only or not yet pushed).

## Manuals updated for MinervaCL's own rule-sending (23 Nov 2026) — rendered with LibreOffice and the changed pages looked at, NOT read by tjingboem, NOT committed
Spec section 6 and `doc/ReaCat_Spec.md` already said so (previous entry); the two real user manuals did not yet. `doc/manual_src/build_manual.py` (two sentences: the Pictures row's list of rule-sending modules, and the Output-section paragraph) rebuilds `doc/ReaCat.odt` (3602 words, 5 tables, 35 headings). A new one-off `doc/manual_src/patch_minervacl_sends_rules.py` (same `Odt` helper as `patch_other_manuals.py`, backup `ReaAC/doc/ReaAC.odt.bak-2026-11-23-minervacl-sends-rules`, untracked) adds one sentence to ReaAC's own "MinervaCL and its editors" paragraph, right after "Markov, Xenakis Sieve and GA Rhythm send a rule as well." Both verified by converting to PDF with LibreOffice (the house's own working recipe, `LD_LIBRARY_PATH=/usr/lib/libreoffice/program soffice --headless -env:UserInstallation=file:///tmp/<profile> --convert-to pdf`) and reading the rendered text back with `pdftotext`; the temporary PDFs were not kept. Not done: re-exporting the shipped `doc/ReaAC.pdf` (he does that).
