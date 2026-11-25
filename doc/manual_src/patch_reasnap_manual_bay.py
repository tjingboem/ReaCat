#!/usr/bin/env python3
# patch_reasnap_manual_bay.py (25 Nov 2026): ReaSnap's manual (doc/ReaSnap.docx) gets a chapter "Three Ways Back": where ReaSnap excels, when to use the
# Project Bay, how to save with increased numbering, and which to use when. Facts: tjingboem's hand tests, compos/What Happens.md entries 1 to 24, and the
# REAPER 7.86 user guide (12.6, 12.23). Backup ReaSnap.docx.bak-2026-11-25-preBay (untracked). Refuses to run twice.
import os, re, shutil, zipfile
from xml.sax.saxutils import escape

PATH = os.path.expanduser("~/Claude/ReaSnap/doc/ReaSnap.docx")
BAK = PATH + ".bak-2026-11-25-preBay"
if not os.path.exists(BAK): shutil.copy2(PATH, BAK)
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")
if "Three Ways Back" in x: raise SystemExit("already patched")

def esc(t): return escape(t).replace("'", "&apos;")
def paragraphs(): return list(re.finditer(r"<w:p[ >].*?</w:p>", x, re.S))
def ptext(m): return "".join(re.findall(r"<w:t[^>]*>([^<]*)</w:t>", m.group(0)))
def find_para(start):
    hits = [m for m in paragraphs() if ptext(m).replace("&apos;", "'").startswith(start)]
    if len(hits) != 1: raise SystemExit("%d paragraphs start with %r" % (len(hits), start[:70]))
    return hits[0]

PPR = '<w:pPr><w:pStyle w:val="Normal"/><w:bidi w:val="0"/><w:spacing w:before="0" w:after="200"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
def body(text):
    return '<w:p>' + PPR + '<w:r><w:rPr></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>' % esc(text)
def lead(word, text):
    return ('<w:p>' + PPR + '<w:r><w:rPr><w:b/><w:bCs/></w:rPr><w:t xml:space="preserve">%s </w:t></w:r>'
            '<w:r><w:rPr></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>') % (esc(word), esc(text))
def heading1(text):
    return ('<w:p><w:pPr><w:pStyle w:val="Heading1"/><w:bidi w:val="0"/><w:ind w:hanging="0" w:start="0"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
            '<w:r><w:rPr><w:b w:val="false"/><w:bCs w:val="false"/><w:color w:val="2E74B5"/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr><w:t>%s</w:t></w:r></w:p>' % esc(text))
def heading2(text):
    return ('<w:p><w:pPr><w:pStyle w:val="Heading2"/><w:bidi w:val="0"/><w:ind w:hanging="0" w:start="0"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
            '<w:r><w:rPr><w:b w:val="false"/><w:bCs w:val="false"/><w:color w:val="2E74B5"/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr><w:t>%s</w:t></w:r></w:p>' % esc(text))

chapter = "".join([
 heading1("Three Ways Back"),
 body("REAPER gives you three different ways to go back, and they do not do the same thing. ReaSnap brings back your tools with their settings. The Project Bay keeps items, with their notes. A numbered save keeps the whole project. This chapter says what each one is good at and when to use which."),

 heading2("Where ReaSnap excels"),
 lead("Getting a tool back with the settings it had.", "Select an item that one of your tools made and press S: the tool opens with the settings that made the item. This keeps working when you cut the item into pieces, duplicate it, reverse it, stretch it, move it to another track, copy it into another project, or save and reopen the project. Every piece shows the settings of the whole original item. It stops working when the item is glued, exploded or merged, because REAPER then builds new items and the settings are not carried over."),
 lead("Changing one thing and trying again.", "With the settings back in the tool you can change one setting and generate again. You do not have to remember what the earlier values were."),
 lead("Bringing back a whole working situation.", "A capture (F10) stores your tracks, their items and the settings of every tool at that moment. A restore brings the moment back and opens the tools. F10 costs nothing, so capture at the moments that matter."),
 lead("What ReaSnap does not bring back is the notes.", "The tool comes back as it was; the item keeps the notes it has now. If you deleted a note or cut up an item by hand, ReaSnap does not undo that. For that, use the Project Bay or a numbered save, below."),

 heading2("When to use the Project Bay"),
 body("The Project Bay (View, Project Media/FX Bay) is REAPER's own catalogue of the items in a project, audio and MIDI. Use it when you want to keep an item itself, with the notes it has, so that you can put it back later."),
 lead("Setting it up.", "Open the Project Bay. In its Options menu choose New project bay window. This second window lists every item of the project by itself, and when you split an item the pieces appear in it at once. A bay that you made by name, or loaded from a file, does not follow the project; the window made with New project bay window does."),
 lead("Keeping what you delete.", "In the Actions menu of the bay choose Retain all items. Every item in the list then stays in the bay, also when you delete it from the project. A single item can be kept with the dot in its Retain column. Look at the Retain column again after you have made new items. An item that was not retained may disappear from the bay when you delete it, so retain before you delete."),
 lead("The bay is saved with the project.", "Save the project, close it and open it again: the items are still in the bay, also those that are not on the timeline. A numbered save (below) carries the bay along."),
 lead("Before you edit an item.", "Copy the item before you cut it up, reverse it or take notes out. The copy is an entry of its own in the bay and stays as it is while you work on the original. If the edit turns out wrong, insert the copy again."),
 lead("Taking an item back.", "Choose its entry and insert it at the cursor, on a track that has an instrument: the track and the instrument are not kept, only the item. The item comes back with the notes it was kept with, and S opens its tool with the settings it was created with."),
 lead("Taking items to another project.", "Save the bay as a file with the Bay field (a .ReaBay file) and load it in the other project. The items come with their notes and their settings."),
 lead("What the bay does not do.", "It keeps items, not steps, and it does not decide for you what is worth keeping; that is the price of retaining. The pieces of a cut item are listed, but S on a piece still opens the settings of the whole original. The bay filters on name, path and comment only."),

 heading2("How to save with increased numbering"),
 body("REAPER has an action for this: File: Save new version of project (automatically increment project name). By default it has the shortcut Ctrl+Alt+Shift+S. If your project is called WinterBlues.RPP, the action saves the project as it is now as WinterBlues_1.RPP; the next time as WinterBlues_2.RPP, and so on. You can find the action in the Actions list (Actions, Show action list) and give it another shortcut."),
 lead("What a numbered save keeps.", "Everything: tracks, items, the Project Bay and the ReaSnap snapshots are all part of the project file. A numbered save is the way back for the whole project at one moment. Make one before a risky step, for instance before you cut up several items."),
 lead("Going back.", "Open the numbered file you want. What you did after that save is not in that file, but the later numbered files stay on disk, so nothing is lost by going back and looking."),
 lead("The ordinary Save overwrites.", "Ctrl+S replaces the file. REAPER can also keep older versions of each save as backup files: in Preferences, Project, Backups, choose to preserve previous versions as timestamped rpp-bak files. These options are off until you switch them on."),

 heading2("Which one to use"),
 lead("You want a tool and its settings back:", "use ReaSnap (S on an item, or a restore of a snapshot)."),
 lead("You cut up or changed one item and want that item as it was:", "use the Project Bay, with a copy kept before you edited."),
 lead("You want the whole project as it was an hour ago:", "use a numbered save."),
 lead("Together:", "a numbered save before a risky session, the Project Bay for the items you want to keep, and F10 at the moments that matter."),
])

mh = find_para("Scope and Limits")
x = x[:mh.start()] + chapter + x[mh.start():]
import xml.dom.minidom
xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("ReaSnap.docx: chapter Three Ways Back added")
