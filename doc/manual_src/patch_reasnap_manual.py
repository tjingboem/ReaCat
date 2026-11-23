#!/usr/bin/env python3
# patch_reasnap_manual.py (23 Nov 2026): ReaSnap's manual (doc/ReaSnap.docx) gets ReaCat: the Launcher list, a table row, footnotes, a section ReaCat, and the new
# way a curve is taken (Latest / ReaCat...). Edits word/document.xml in place; backup ReaSnap.docx.bak-2026-11-23-preReaCat (untracked).
import os, re, shutil, zipfile
from xml.sax.saxutils import escape

PATH = os.path.expanduser("~/Claude/ReaSnap/doc/ReaSnap.docx")
BAK = PATH + ".bak-2026-11-23-preReaCat"
if not os.path.exists(BAK): shutil.copy2(PATH, BAK)
z = zipfile.ZipFile(PATH)
names = z.namelist()
data = {n: z.read(n) for n in names}
z.close()
x = data["word/document.xml"].decode("utf8")

def esc(t): return escape(t).replace("'", "&apos;")

def replace(old, new, count=1):
    global x
    n = x.count(old)
    if n != count: raise SystemExit("expected %d of %r, found %d" % (count, old[:80], n))
    x = x.replace(old, new)

def paragraphs():
    return list(re.finditer(r"<w:p[ >].*?</w:p>", x, re.S))
def ptext(m): return "".join(re.findall(r"<w:t[^>]*>([^<]*)</w:t>", m.group(0)))
def find_para(start):
    hits = [m for m in paragraphs() if ptext(m).replace("&apos;", "'").startswith(start)]
    if len(hits) != 1: raise SystemExit("%d paragraphs start with %r" % (len(hits), start[:70]))
    return hits[0]

def body_para(text):
    return ('<w:p><w:pPr><w:pStyle w:val="Normal"/><w:bidi w:val="0"/><w:spacing w:before="0" w:after="200"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
            '<w:r><w:rPr></w:rPr><w:t>%s</w:t></w:r></w:p>' % esc(text))
def heading2(text):
    return ('<w:p><w:pPr><w:pStyle w:val="Heading2"/><w:bidi w:val="0"/><w:ind w:hanging="0" w:start="0"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
            '<w:r><w:rPr><w:b w:val="false"/><w:bCs w:val="false"/><w:color w:val="2E74B5"/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr><w:t>%s</w:t></w:r></w:p>' % esc(text))

# 1. the Launcher list, the count of tools, the icon list
replace("Currently: ReaMaskM, ReaShapeM, ReaGestM, ReaNvelopes, ReaATS, ReaAC, Clouds, and Transformer.", "Currently: ReaMaskM, ReaShapeM, ReaGestM, ReaNvelopes, ReaATS, ReaAC, ReaCat, Clouds, and Transformer.")
replace("Transformer&apos;s row has Launch only (see Transformer, below).", "ReaCat&apos;s row has Launch and Close All but no S (see ReaCat, below). Transformer&apos;s row has Launch only (see Transformer, below).")
replace("ReaSnap knows eight tools today. ReaMaskM, ReaShapeM, ReaGestM, ReaNvelopes, ReaATS and ReaAC are the author's own scripts and hand over their settings in the way described below.",
        "ReaSnap knows nine tools today. ReaMaskM, ReaShapeM, ReaGestM, ReaNvelopes, ReaATS and ReaAC are the author's own scripts and hand over their settings in the way described below. ReaCat, the catalogue of envelopes, is the author's too, but it has no settings of its own: ReaSnap keeps and restores the curves of a project instead (see ReaCat, below).")
replace("(Clouds, Mask, ReaAC, ReaGestM, ReaNvelopes, Shape)", "(Clouds, Mask, ReaAC, ReaCat, ReaGestM, ReaNvelopes, Shape)")

# 2. the table: the ReaNvelopes cell, and a row for ReaCat after ReaAC
replace("Yes, except Send curve (1)", "Yes, except Send to ReaCat (1)")
m = re.search(r"<w:tr>(?:(?!</w:tr>).)*?<w:t>ReaAC</w:t>.*?</w:tr>", x, re.S)
row = m.group(0)
cells = ["ReaCat", "Yes", "Yes", "No", "No: the curves of the project are kept in the project (6)", "No: it opens from the Launcher (6)", "Not applicable"]
it = iter(cells)
newrow = re.sub(r"(<w:t(?: [^>]*)?>)([^<]*)(</w:t>)", lambda mm: mm.group(1) + esc(next(it)) + mm.group(3), row)
assert len(re.findall(r"<w:t[ >]", row)) == 7, "the ReaAC row has not 7 text cells"
# the first cell of every second row is shaded: give ReaCat the other shade than ReaAC
if 'w:fill="D0E4F5"' in row: newrow = newrow.replace(' w:fill="D0E4F5"', ' w:fill="FFFFFF"', 1)
x = x[:m.end()] + newrow + x[m.end():]

# 3. footnotes
replace("Send curve writes into no item, so nothing is remembered for it.", "Send to ReaCat writes into no item, so nothing is remembered on an item for it; ReaCat keeps the curve (see ReaCat, below).")
m5 = find_para("(5) Transformer.")
x = x[:m5.end()] + body_para("(6) ReaCat. It has no item and no settings that a window could hand over. A capture keeps the curves of the project inside the project, and a restore puts the missing ones back into the catalogue; see ReaCat, below.") + x[m5.end():]

# 4. taking a curve
replace("Sending a curve to ReaMaskM or ReaShapeM. </w:t>", "Taking a curve in ReaMaskM or ReaShapeM. </w:t>")
replace("A curve that ReaNvelopes sends with SEND CURVE becomes part of the receiving tool once you take it. In ReaMaskM or ReaShapeM, Take Curve from ReaNvelopes lays the curve into the envelope that is active there",
        "A curve that ReaNvelopes, or a module of ReaAC, sends to ReaCat becomes part of the receiving tool once you take it. In ReaMaskM or ReaShapeM, Latest or ReaCat... lays the curve into the envelope that is active there")
replace("The sent curve waits in REAPER as a single curve, and the next SEND CURVE replaces it.", "The catalogue keeps the sent curve, and ReaSnap can bring it back (see ReaCat, below).")

# 5. the section ReaCat, before "Why Clouds is fully supported and Transformer only in part"
mh = find_para("Why Clouds is fully supported and Transformer only in part")
section = (heading2("ReaCat") +
  body_para("ReaCat is the catalogue of envelopes of the author's tools: a tool that makes a curve sends it there, a tool that needs a curve takes it from there. It has its own manual. In the Launcher it has a row with a cat face, with Launch and Close All.") +
  body_para("Launch and Close All. A ReaCat window that ReaSnap starts is numbered in its title (ReaCat #2) and closed by Close All with the other windows of the project. There is only ever one ReaCat window: pressing Launch while it is open brings the open one to the front. S (Scan) has nothing to scan, because ReaCat does not belong to an item, and a restore does not open it by itself.") +
  body_para("The curves of the project. A capture keeps the curves that the project needs inside the project: the curves that were sent while this project was open, and the curves that the project uses even if another project sent them. Each curve is kept once, not once for every snapshot. A restore (Restore, Restore and Replace or Return) puts the missing curves back into the catalogue of the computer you are on, with their tags, notes and dates. A curve that is already there is not added twice, and a curve that you deleted on purpose, which sits in ReaCat's trash, stays gone. The ReaSnap console says how many curves were kept and how many were put back.") +
  body_para("Without ReaCat. The curves are kept and restored by ReaSnap itself, with a copy of ReaCat's small library next to ReaSnap_Core.lua. Without that file ReaSnap works as before and keeps no curves."))
x = x[:mh.start()] + section + x[mh.start():]

# 6. moving a project
mm = find_para("A project that contains snapshots can be opened in another REAPER")
t = ptext(mm)
x = x[:mm.end()] + body_para("The curves of the project in ReaCat travel too: capture a snapshot before you move the project, and a restore on the other computer puts the missing curves back into its catalogue (see ReaCat).") + x[mm.end():]

import xml.dom.minidom
xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names:
        zo.writestr(n, data[n], compress_type=zipfile.ZIP_STORED if n == "[Content_Types].xml" and False else zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("ReaSnap.docx patched")
