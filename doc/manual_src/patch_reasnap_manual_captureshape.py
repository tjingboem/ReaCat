#!/usr/bin/env python3
# patch_reasnap_manual_captureshape.py (26 Nov 2026): ReaSnap's manual (doc/ReaSnap.docx) gets the cat button (Capture Shape): a section
# "Capture Shape: the cat button" inside the ReaCat part of "Working with Your Tools", and one sentence in the Launcher tab text.
# Backup ReaSnap.docx.bak-2026-11-26-preCaptureShape (untracked). Refuses to run twice.
import os, re, shutil, zipfile
from xml.sax.saxutils import escape

PATH = os.path.expanduser("~/Claude/ReaSnap/doc/ReaSnap.docx")
BAK = PATH + ".bak-2026-11-26-preCaptureShape"
if not os.path.exists(BAK): shutil.copy2(PATH, BAK)
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")
if "Capture Shape: the cat button" in x: raise SystemExit("already patched")

def esc(t): return escape(t).replace("'", "&apos;")
def paragraphs(): return list(re.finditer(r"<w:p[ >].*?</w:p>", x, re.S))
def ptext(m): return "".join(re.findall(r"<w:t[^>]*>([^<]*)</w:t>", m.group(0)))
def find_para(start):
    hits = [m for m in paragraphs() if ptext(m).replace("&apos;", "'").startswith(start)]
    if len(hits) != 1: raise SystemExit("%d paragraphs start with %r" % (len(hits), start[:70]))
    return hits[0]

PPR = '<w:pPr><w:pStyle w:val="Normal"/><w:bidi w:val="0"/><w:spacing w:before="0" w:after="200"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
def body(text): return '<w:p>' + PPR + '<w:r><w:rPr></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>' % esc(text)
def lead(word, text):
    return ('<w:p>' + PPR + '<w:r><w:rPr><w:b/><w:bCs/></w:rPr><w:t xml:space="preserve">%s </w:t></w:r>'
            '<w:r><w:rPr></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>') % (esc(word), esc(text))
def heading2(text):
    return ('<w:p><w:pPr><w:pStyle w:val="Heading2"/><w:bidi w:val="0"/><w:ind w:hanging="0" w:start="0"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
            '<w:r><w:rPr><w:b w:val="false"/><w:bCs w:val="false"/><w:color w:val="2E74B5"/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr><w:t>%s</w:t></w:r></w:p>' % esc(text))

# 1. the Launcher tab text
old = "ReaCat&apos;s row has Launch and Close All but no S (see ReaCat, below)."
if x.count(old) != 1: raise SystemExit("Launcher sentence not found once")
x = x.replace(old, "ReaCat&apos;s row has Launch and Close All but no S (see ReaCat, below). The small cat face in front of ReaCat is also a button: it files a selected automation item, or a lane of MIDI CC, in ReaCat (see Capture Shape, below).")

# 2. the section, before "Why Clouds is fully supported and Transformer only in part"
hits = [m for m in paragraphs() if ptext(m).startswith("Why Clouds is fully supported and Transformer only in part") and 'w:val="Heading2"' in m.group(0)]
if len(hits) != 1: raise SystemExit("%d headings Why Clouds..." % len(hits))   # (the contents list has the same words, not as a heading)
mh = hits[0]
section = "".join([
 heading2("Capture Shape: the cat button"),
 body("The small cat face in ReaCat's row on the Launcher tab is a button. It takes a shape that is already in your project and files it in ReaCat as a curve, so that you can use it in another tool. Nothing is watched in the background: you select, you click the cat, and ReaCat keeps a copy. Your project is not changed, and ReaCat's own manual says more about what happens to the curve afterwards."),
 lead("An automation item.", "Select one or more automation items and click the cat. Each becomes a curve, named after its envelope and its length. Only the shape is filed, never any setting: an item with its own LFO is filed as the curve it looks like, not as the speed, strength and phase of the LFO."),
 lead("A lane of MIDI CC.", "With no automation item selected and a MIDI editor open, the cat files the lane that you clicked last in that editor. First click the lane (a CC, pitch bend or channel pressure), then make a time selection over the part you mean, then click the cat. The time selection decides the part: a lane mostly has no event exactly at the start and the end of what you mean, so the curve takes its value at those two moments from the lane itself, the value the lane holds there or the value on the ramp that is running. If nothing comes before the selection, the curve starts flat at the first event inside it. Step, line, slow, fast start and fast end are kept; a Bezier segment is filed as a straight line. When the lane has events on several MIDI channels, the channel with most events inside the selection is used."),
 lead("What the cat tells you.", "After a click the cat turns green for about a second when a curve was filed, and red when nothing was filed. The line at the bottom of the Browser says what happened, for example 1 shape filed in ReaCat, or make a time selection first."),
 lead("What you get.", "A curve between 0 and 1 in the catalogue, with the source Automation Item or MIDI CC, and with the original range kept (the range of the envelope, 0 to 127 for a CC), so that a tool that offers Original range can scale it back. It needs the small copy of ReaCat's library next to ReaSnap_Core.lua, like the curves of the project."),
])
x = x[:mh.start()] + section + x[mh.start():]

import xml.dom.minidom
xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("ReaSnap.docx: Capture Shape added")
