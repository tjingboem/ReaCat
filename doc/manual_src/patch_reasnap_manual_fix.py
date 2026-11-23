#!/usr/bin/env python3
# patch_reasnap_manual_fix.py (23 Nov 2026): after rendering ReaSnap.docx with LibreOffice two things were corrected: the ReaCat row of the tools table got the same blue
# first cell as every other row (not a white one), and the list of files has a row for ReaCat.lua (the copy of ReaCat's library next to ReaSnap_Core.lua).
import os, re, zipfile
from xml.sax.saxutils import escape
PATH = os.path.expanduser("~/Claude/ReaSnap/doc/ReaSnap.docx")
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")

# 1. the shade of the ReaCat row
m = re.search(r"<w:tr>(?:(?!</w:tr>).)*?<w:t>ReaCat</w:t>.*?</w:tr>", x, re.S)
row = m.group(0)
assert 'w:fill="FFFFFF"' in row, "already fixed"
x = x[:m.start()] + row.replace(' w:fill="FFFFFF"', ' w:fill="D0E4F5"', 1) + x[m.end():]

# 2. a row in the list of files, cloned from the row of ReaSculpt_Serial.lua
m = re.search(r"<w:tr>(?:(?!</w:tr>).)*?<w:t[^>]*>ReaSculpt_Serial\.lua</w:t>.*?</w:tr>", x, re.S)
assert m, "no ReaSculpt_Serial.lua row"
row = m.group(0)
texts = iter(["ReaCat.lua", "repo root", "A copy of the small library of ReaCat, the catalogue of envelopes. Capture and Restore use it to keep and restore the curves of a project. Optional: without it ReaSnap works as before and keeps no curves."])
newrow = re.sub(r"(<w:t(?: [^>]*)?>)([^<]*)(</w:t>)", lambda mm: mm.group(1) + escape(next(texts)).replace("'", "&apos;") + mm.group(3), row)
x = x[:m.end()] + newrow + x[m.end():]

import xml.dom.minidom
xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("fixed")
