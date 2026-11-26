#!/usr/bin/env python3
# patch_reasnap_manual_captureshape_toc.py (26 Nov 2026): adds "Capture Shape: the cat button" to the static contents list of ReaSnap.docx (after ReaCat),
# with a bookmark on its heading. Run after patch_reasnap_manual_captureshape.py. Refuses to run twice.
import os, re, zipfile
PATH = os.path.expanduser("~/Claude/ReaSnap/doc/ReaSnap.docx")
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")
if "_RSTocCapShape" in x: raise SystemExit("already done")
# 1. the contents entry: a copy of the ReaCat entry
m = re.search(r'<w:p>(?:(?!</w:p>).)*?<w:hyperlink w:anchor="_RSToc16">(?:(?!</w:p>).)*?</w:p>', x, re.S)
if not m or "<w:t>ReaCat</w:t>" not in m.group(0): raise SystemExit("ReaCat contents entry not found")
new = m.group(0).replace("_RSToc16", "_RSTocCapShape").replace("<w:t>ReaCat</w:t>", "<w:t>Capture Shape: the cat button</w:t>")
x = x[:m.end()] + new + x[m.end():]
# 2. the bookmark on the heading
h = re.search(r'<w:p><w:pPr><w:pStyle w:val="Heading2"/>(?:(?!</w:p>).)*?<w:t>Capture Shape: the cat button</w:t></w:r></w:p>', x, re.S)
if not h: raise SystemExit("heading not found")
p = h.group(0); k = p.index("</w:pPr>") + len("</w:pPr>")
p = p[:k] + '<w:bookmarkStart w:id="990" w:name="_RSTocCapShape"/>' + p[k:-len("</w:p>")] + '<w:bookmarkEnd w:id="990"/></w:p>'
x = x[:h.start()] + p + x[h.end():]
import xml.dom.minidom
xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("contents list: Capture Shape added")
