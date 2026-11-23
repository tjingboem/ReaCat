#!/usr/bin/env python3
# patch_reasnap_manual_bold.py (23 Nov 2026): the lead words of the new ReaCat paragraphs in ReaSnap.docx are bold, as in the other sections.
import os, re, zipfile
PATH = os.path.expanduser("~/Claude/ReaSnap/doc/ReaSnap.docx")
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")
for lead in ["Launch and Close All. A ReaCat window", "The curves of the project. A capture", "Without ReaCat. The curves", "(6) ReaCat. It has no item"]:
    word = lead.split(". ")[0] + "."
    old = "<w:r><w:rPr></w:rPr><w:t>" + lead
    assert x.count(old) == 1, lead
    rest = lead[len(word):]
    new = ('<w:r><w:rPr><w:b/><w:bCs/></w:rPr><w:t xml:space="preserve">' + word + ' </w:t></w:r><w:r><w:rPr></w:rPr><w:t xml:space="preserve">' + rest.lstrip())
    x = x.replace(old, new)
import xml.dom.minidom
xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("bold leads done")
