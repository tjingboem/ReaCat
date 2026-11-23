#!/usr/bin/env python3
# patch_dropdown_manuals.py (23 Nov 2026): ReaMaskM and ReaShapeM have ONE dropdown "ReaCat" (Latest, Open ReaCat, Send to ReaCat and the world) instead of two buttons:
# the manuals of ReaMaskM and ReaShapeM, the ReaSnap manual and (by build_manual.py, edited by hand) the ReaCat manual say so. Run once; backups exist (.bak-2026-11-23-preReaCat).
import os, re, sys, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from odt_edit import Odt
ROOT = os.path.expanduser("~/Claude")
TAG = "2026-11-23-preReaCat"

d = Odt(ROOT + "/ReaMaskM/doc/ReaMaskM.odt", TAG)
d.replace("Take a curve from ReaCat brings a curve from the ReaCat catalogue into the envelope that is selected in ReaMaskM. In ReaNvelopes, or in a module of ReaAC, generate or draw the curve and send it with the target Send to ReaCat and the world. Then, in ReaMaskM, choose the envelope and press Latest, above the Generate button, to take the newest curve in the catalogue, or ReaCat... to choose one from small pictures, with search and tags. (Taking a curve needs ReaCat.lua and ReaCatPicker.lua next to ReaMaskM.lua; without them a grey note in the place of the buttons says so.)",
  "Take a curve from ReaCat brings a curve from the ReaCat catalogue into the envelope that is selected in ReaMaskM, and sends the envelope back. One dropdown, ReaCat, stands under the preset name and the Save button, in the style of the BPM Grid dropdown. Latest takes the newest curve in the catalogue. Open ReaCat opens the catalogue as small pictures, with search and tags, to choose one. Send to ReaCat and the world sends the selected envelope to the catalogue, named ReaMaskM and the envelope, for example Pitch: Min Pitch; an envelope with Bezier points is sent in small steps, so it keeps its shape. A short message under the dropdown says what happened. In ReaNvelopes, or in a module of ReaAC, generate or draw a curve and send it with the target Send to ReaCat and the world; then, in ReaMaskM, choose the envelope and choose Latest or Open ReaCat. (Taking a curve needs ReaCat.lua and ReaCatPicker.lua next to ReaMaskM.lua; without them a grey note in the place of the dropdown says so.)")
for line in d.save(): print("ReaMaskM:", line)

d = Odt(ROOT + "/ReaShapeM/doc/ReaShapeM.odt", TAG)
d.replace("A small grey label beside the Latest and ReaCat... buttons, under the envelope button at the top of the window, shows which of the two is in use. ", "")
d.replace("Then, in ReaShapeM, choose the envelope and press Latest (the newest curve in the catalogue) or ReaCat... (choose from small pictures, with search and tags). The buttons sit on their own line under the envelope button at the top of the window, and the text beside them reports what happened, for example how many points were taken.",
  "Then, in ReaShapeM, choose the envelope and choose Latest (the newest curve in the catalogue) or Open ReaCat (choose from small pictures, with search and tags) in the dropdown ReaCat. The dropdown stands in the bottom left corner of the window, on the row of the steps, and the green text beside it reports what happened, for example how many points were taken. The third entry, Send to ReaCat and the world, sends the selected envelope to the catalogue, named ReaShapeM and the envelope, for example Time: Warp. Its time runs over the notes that you selected; an envelope with bulges or curved segments is sent in small steps, so it keeps its shape.")
for line in d.save(): print("ReaShapeM:", line)

# ReaSnap.docx
PATH = ROOT + "/ReaSnap/doc/ReaSnap.docx"
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")
old = "In ReaMaskM or ReaShapeM, Latest or ReaCat... lays the curve into the envelope that is active there"
assert x.count(old) == 1
x = x.replace(old, "In ReaMaskM or ReaShapeM, the dropdown ReaCat (Latest or Open ReaCat) lays the curve into the envelope that is active there")
import xml.dom.minidom
xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("ReaSnap.docx patched")

# the ReaCat manual: its builder
bp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build_manual.py")
s = open(bp).read()
def rep(old, new):
    global s
    assert s.count(old) == 1, old[:60]
    s = s.replace(old, new)
rep('p("Every tool that takes curves has the same two buttons.")', 'p("Every tool that takes curves offers the same two ways: two buttons, or, in ReaMaskM and ReaShapeM, two entries of one dropdown (5.3).")')
rep('h2("ReaMaskM and ReaShapeM")\np("In ReaMaskM and ReaShapeM the old button Take Curve from ReaNvelopes has become **Latest** and **ReaCat...**. Choose the envelope that should receive the curve first. The curve replaces that envelope. It covers its whole width and its whole height: the bottom of the envelope is 0 and the top is 1, exactly as the curve is in the catalogue. What the values mean is up to you. ReaCat... opens the catalogue in a small window.")',
    'h2("ReaMaskM and ReaShapeM")\np("In ReaMaskM and ReaShapeM the old button Take Curve from ReaNvelopes has become one dropdown, **ReaCat**. In ReaMaskM it stands under the preset name and the Save button, in the style of the BPM Grid dropdown. In ReaShapeM it stands in the bottom left corner, on the row of the steps. Its entries are **Latest**, **Open ReaCat** (the catalogue in a small window) and **Send to ReaCat and the world** (4.3). Choose the envelope that should receive the curve first. The curve replaces that envelope. It covers its whole width and its whole height: the bottom of the envelope is 0 and the top is 1, exactly as the curve is in the catalogue. What the values mean is up to you. A short message beside or under the dropdown says what happened.")')
rep('h2("What a tool writes into the project")', 'h2("From ReaMaskM and ReaShapeM")\np("The dropdown **ReaCat** of ReaMaskM and ReaShapeM also sends: **Send to ReaCat and the world** puts the selected envelope in the catalogue as a curve, named ReaMaskM or ReaShapeM and the envelope, for example Pitch: Min Pitch or Time: Warp, and tagged with its group. The envelope fills the whole width and the whole height of the curve, as in the window. In ReaShapeM the time runs over the notes that you selected. An envelope with curved segments or Bezier points is sent in small steps, so that it keeps its shape. So a shape that you made in one of these tools can be used in ReaNvelopes\' neighbours, in MinervaCL or in the other tool.")\nh2("What a tool writes into the project")')
open(bp, "w").write(s)
print("build_manual.py edited")
