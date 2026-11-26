#!/usr/bin/env python3
# patch_manuals_used_sends.py (26 Nov 2026): the other manuals say that what a tool SENDS is marked as used in this project (ReaCat's red border), and that
# S in ReaCat's row of ReaSnap scans the project. Edits ReaMaskM.odt, ReaShapeM.odt, ReaNvelopes_Manual.odt, ReaAC.odt and ReaSnap.docx.
# Backups <manual>.bak-2026-11-26-usedSends (untracked). A text that is not found exactly once is reported and skipped.
import os, re, shutil, sys, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from odt_edit import Odt
ROOT = os.path.expanduser("~/Claude")
TAG = "2026-11-26-usedSends"
def odt(path, edits):
    d = Odt(os.path.join(ROOT, path), TAG)
    for kind, a, b in edits:
        try:
            if kind == "replace": d.replace(a, b)
            elif kind == "append":
                m = d._find(a)
                d.xml = d.xml[:m.end(3)] + b + d.xml[m.end(3):]
                d.log.append("appended to %r" % a[:40])
        except SystemExit as e:
            print("SKIPPED:", e)
    for line in d.save(): print(os.path.basename(path), line)
odt("ReaMaskM/doc/ReaMaskM.odt", [("append", "The curve replaces every point of the selected envelope.", " A curve that you send is marked as used in this project too: ReaCat shows it with a red border and the line in ReaMaskM, and after you press Generate the item that was made, with a button that selects it.")])
odt("ReaShapeM/doc/ReaShapeM.odt", [("append", "Take a curve from ReaCat brings a curve from the ReaCat catalogue into the envelope that is selected in ReaShapeM", " A curve that you send with Send to ReaCat and the world is marked as used in this project too: ReaCat shows it with a red border and the line in ReaShapeM, and after you press Apply the item that was made, with a button that selects it.")])
odt("ReaNvelopes/doc/ReaNvelopes_Manual.odt", [
    ("replace", "SEND TO REACAT stores nothing on an item, because nothing is written into the project.", "SEND TO REACAT stores nothing on an item, because no track or item is changed. The project only remembers that the curve was sent from it, and ReaCat shows it with a red border."),
    ("replace", "Nothing is written into the project, so no time selection, envelope lane or item is needed.", "No track or item is changed, so no time selection, envelope lane or item is needed. ReaCat marks the curve as used in this project (in ReaNvelopes), with a red border."),
])
odt("ReaAC/doc/ReaAC.odt", [("append", "Send to ReaCat and the world. Every module that has an Output section", " The curves that a module sends are marked as used in this project too: ReaCat shows them with a red border and the name of the module as the place.")])

# ReaSnap.docx
PATH = os.path.join(ROOT, "ReaSnap/doc/ReaSnap.docx")
BAK = PATH + ".bak-" + TAG
if not os.path.exists(BAK): shutil.copy2(PATH, BAK)
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")
def esc(t): return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("'", "&apos;")
def rep(old, new):
    global x
    if x.count(old) != 1: print("SKIPPED (ReaSnap.docx): %d of %r" % (x.count(old), old[:70])); return
    x = x.replace(old, new)
rep("ReaCat&apos;s row has Launch and Close All but no S (see ReaCat, below).", "ReaCat&apos;s row has Launch, Close All and an S that scans the shapes of the project (see Scan the shapes of the project, below).")
# the S cell of the ReaCat table row (the fourth cell)
m = re.search(r"<w:tr>(?:(?!</w:tr>).)*?<w:t>ReaCat</w:t>.*?</w:tr>", x, re.S)
if m:
    row = m.group(0); cells = list(re.finditer(r"(<w:t(?: [^>]*)?>)([^<]*)(</w:t>)", row))
    if len(cells) >= 4 and cells[3].group(2).strip() == "No":
        new = row[:cells[3].start(2)] + "Yes: scans" + row[cells[3].end(2):]
        x = x[:m.start()] + new + x[m.end():]
    else: print("SKIPPED (ReaSnap.docx): the S cell of the ReaCat row is not 'No'")
PPR = '<w:pPr><w:pStyle w:val="Normal"/><w:bidi w:val="0"/><w:spacing w:before="0" w:after="200"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
def body(t): return '<w:p>' + PPR + '<w:r><w:rPr></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>' % esc(t)
def lead(w, t): return '<w:p>' + PPR + '<w:r><w:rPr><w:b/><w:bCs/></w:rPr><w:t xml:space="preserve">%s </w:t></w:r><w:r><w:rPr></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>' % (esc(w), esc(t))
def heading2(t):
    return ('<w:p><w:pPr><w:pStyle w:val="Heading2"/><w:bidi w:val="0"/><w:ind w:hanging="0" w:start="0"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
            '<w:r><w:rPr><w:b w:val="false"/><w:bCs w:val="false"/><w:color w:val="2E74B5"/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr><w:t>%s</w:t></w:r></w:p>' % esc(t))
heads = [mm for mm in re.finditer(r"<w:p[ >].*?</w:p>", x, re.S) if "Why Clouds is fully supported and Transformer only in part" in re.sub(r"<[^>]+>", "", mm.group(0)) and 'w:val="Heading2"' in mm.group(0)]
if len(heads) == 1 and "Scan the shapes of the project" not in re.sub(r"<[^>]+>", "", x[heads[0].start()-6000:heads[0].start()]):
    sec = "".join([
        heading2("Scan the shapes of the project"),
        body("The S button in ReaCat's row works on the whole project, not on the item you selected. It reads the shape of every automation item, compares it with the curves that are already in the ReaCat catalogue, and marks each curve that it finds as used in this project: ReaCat shows it with a red border and names the automation item as the place. It files nothing new in the catalogue, whatever the shape of the items is. Only the cat button does that, for the items you select."),
        lead("What you see.", "The S turns green for about a second when it found curves and amber when it found none. The line at the bottom of the Browser says how many curves were found, in how many places, and how many are new. A second press finds the same and adds nothing."),
        lead("What it can and cannot find.", "Two shapes count as the same when they differ by no more than 3% of the height. A shape that you changed by hand does not match. A lane of MIDI CC is not scanned, because the scan cannot know which part of the lane a curve was taken from; only the cat button marks those. The marks are saved in the project, so REAPER asks to save it after the first scan that found something."),
    ])
    x = x[:heads[0].start()] + sec + x[heads[0].start():]
else: print("SKIPPED (ReaSnap.docx): the place for the new section was not found once, or it is there already")
import xml.dom.minidom; xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("ReaSnap.docx patched")
