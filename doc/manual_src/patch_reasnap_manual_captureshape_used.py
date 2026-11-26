#!/usr/bin/env python3
# patch_reasnap_manual_captureshape_used.py (26 Nov 2026): ReaSnap.docx: a filed shape is marked as used in this project (red border in ReaCat).
import os, zipfile, shutil
PATH = os.path.expanduser("~/Claude/ReaSnap/doc/ReaSnap.docx")
BAK = PATH + ".bak-2026-11-26-preCaptureShapeUsed"
if not os.path.exists(BAK): shutil.copy2(PATH, BAK)
z = zipfile.ZipFile(PATH); names = z.namelist(); data = {n: z.read(n) for n in names}; z.close()
x = data["word/document.xml"].decode("utf8")
old = "Your project is not changed, and ReaCat&apos;s own manual says more about what happens to the curve afterwards."
new = "Your tracks and items are not changed, but the curve is marked as used in this project, so it gets the red border in ReaCat and the project remembers it (ReaCat&apos;s own manual says more)."
if x.count(old) != 1: raise SystemExit("sentence not found once (already patched?)")
x = x.replace(old, new)
import xml.dom.minidom; xml.dom.minidom.parseString(x.encode("utf8"))
data["word/document.xml"] = x.encode("utf8")
tmp = PATH + ".tmp"
with zipfile.ZipFile(tmp, "w") as zo:
    for n in names: zo.writestr(n, data[n], compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, PATH); print("ok")
