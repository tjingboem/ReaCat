#!/usr/bin/env python3
# patch_reasnap_manual_toc.py (25 Nov 2026): ReaSnap's manual (doc/ReaSnap.docx) gets a contents list WITHOUT page numbers, on a page of its own between the cover
# and "Overview": a static list of the chapters (Heading1) and their sections (Heading2), each a link to a bookmark on its heading (the links work in the PDF).
# Static: it does not update itself; after a chapter is added, restore the backup taken before this patch, add the chapter, and run this patch again. Backup ReaSnap.docx.bak-2026-11-25-preContents (untracked).
import os, re, shutil, zipfile
PATH = os.path.expanduser("~/Claude/ReaSnap/doc/ReaSnap.docx")
BAK = PATH + ".bak-2026-11-25-preContents"
if not os.path.exists(BAK): shutil.copy2(PATH, BAK)
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")

if "<w:t>Contents</w:t>" in x: raise SystemExit("already has a contents list; to redo it, restore the backup taken before it and run the patches again")

def ptext(p): return "".join(re.findall(r"<w:t[^>]*>([^<]*)</w:t>", p))
paras = list(re.finditer(r"<w:p[ >].*?</w:p>", x, re.S))
start = next(i for i, m in enumerate(paras) if 'w:val="Heading1"' in m.group(0) and ptext(m.group(0)) == "Overview")

entries = []   # (level, escaped text, index of paragraph)
for i in range(start, len(paras)):
    p = paras[i].group(0)
    st = re.search(r'<w:pStyle w:val="(Heading[12])"', p)
    t = ptext(p).strip()
    if st and t: entries.append((int(st.group(1)[-1]), t, i))

# bookmarks, from the end so the offsets stay right
for n in range(len(entries) - 1, -1, -1):
    lvl, t, i = entries[n]
    m = paras[i]; p = m.group(0)
    # after the pPr: bookmarkStart; before </w:p>: bookmarkEnd
    k = p.index("</w:pPr>") + len("</w:pPr>")
    newp = p[:k] + '<w:bookmarkStart w:id="%d" w:name="_RSToc%d"/>' % (900 + n, n) + p[k:-len("</w:p>")] + '<w:bookmarkEnd w:id="%d"/></w:p>' % (900 + n)
    if t == "Overview":
        newp = newp.replace('<w:pStyle w:val="Heading1"/>', '<w:pStyle w:val="Heading1"/><w:pageBreakBefore/>', 1)
    x = x[:m.start()] + newp + x[m.end():]

def entry(lvl, t, n):
    ind = '<w:ind w:start="%d" w:hanging="0"/>' % (0 if lvl == 1 else 360)
    sp = '<w:spacing w:before="%d" w:after="40"/>' % (120 if lvl == 1 else 0)
    rpr = '<w:rPr><w:b/><w:bCs/></w:rPr>' if lvl == 1 else '<w:rPr></w:rPr>'
    return ('<w:p><w:pPr><w:pStyle w:val="Normal"/><w:bidi w:val="0"/>' + sp + ind + '<w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
            '<w:hyperlink w:anchor="_RSToc%d" w:history="1"><w:r>%s<w:t xml:space="preserve">%s</w:t></w:r></w:hyperlink></w:p>' % (n, rpr, t))

heading = ('<w:p><w:pPr><w:pStyle w:val="Heading1"/><w:pageBreakBefore/><w:bidi w:val="0"/><w:ind w:hanging="0" w:start="0"/><w:jc w:val="start"/><w:rPr></w:rPr></w:pPr>'
           '<w:r><w:rPr><w:b w:val="false"/><w:bCs w:val="false"/><w:color w:val="2E74B5"/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr><w:t>Contents</w:t></w:r></w:p>')
toc = heading + "".join(entry(l, t, n) for n, (l, t, i) in enumerate(entries)) + "<!--RSTOC-END-->"
# the marker comment is dropped again by the browser of the XML? No: keep it out of the file; use an empty paragraph as the end marker instead
toc = toc.replace("<!--RSTOC-END-->", "")
paras = list(re.finditer(r"<w:p[ >].*?</w:p>", x, re.S))
ov = next(m for m in paras if 'w:val="Heading1"' in m.group(0) and ptext(m.group(0)) == "Overview")
x = x[:ov.start()] + toc + x[ov.start():]
import xml.dom.minidom
xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH)
print("contents list with %d entries" % len(entries))
