# odt_edit.py: small helpers to edit an .odt / .docx in place without LibreOffice (unzip, edit the XML text, rezip with mimetype first).
# Used by patch_other_manuals.py. A backup of each file is made once, as <file>.bak-<tag> (untracked, the house habit).
import re, shutil, os, zipfile

def plain(inner):
    t = re.sub(r"<text:tab/>|<text:line-break/>|<text:soft-page-break/>", " ", inner)
    t = re.sub(r"<text:s[^>]*/>", " ", t)
    t = re.sub(r"<[^>]+>", "", t)
    return t.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"').replace("&apos;", "'")

class Odt:
    def __init__(self, path, backup_tag):
        self.path = path
        bak = path + ".bak-" + backup_tag
        if not os.path.exists(bak):
            shutil.copy2(path, bak)
        z = zipfile.ZipFile(path)
        self.names = z.namelist()
        self.infos = {i.filename: i for i in z.infolist()}
        self.data = {n: z.read(n) for n in self.names}
        z.close()
        self.xml = self.data["content.xml"].decode("utf8")
        self.log = []

    def replace(self, old, new, count=1):
        n = self.xml.count(old)
        if n != count:
            raise SystemExit("%s: expected %d of %r, found %d" % (os.path.basename(self.path), count, old[:90], n))
        self.xml = self.xml.replace(old, new)
        self.log.append("replaced %d x %r" % (count, old[:60]))

    def _find(self, start_plain, tags="ph"):
        hits = []
        for m in re.finditer(r"<text:([ph])\b([^>]*)>(.*?)</text:\1>", self.xml, re.S):
            if m.group(1) in tags and plain(m.group(3)).startswith(start_plain):
                hits.append(m)
        if len(hits) != 1:
            raise SystemExit("%s: %d paragraphs start with %r" % (os.path.basename(self.path), len(hits), start_plain[:70]))
        return hits[0]

    def rewrite(self, start_plain, new_inner):
        m = self._find(start_plain)
        self.xml = self.xml[:m.start(3)] + new_inner + self.xml[m.end(3):]
        self.log.append("rewrote paragraph %r" % start_plain[:50])

    def insert_after(self, start_plain, new_paragraph_xml):
        m = self._find(start_plain)
        self.xml = self.xml[:m.end()] + new_paragraph_xml + self.xml[m.end():]
        self.log.append("inserted after %r" % start_plain[:50])

    def save(self):
        self.data["content.xml"] = self.xml.encode("utf8")
        tmp = self.path + ".tmp"
        with zipfile.ZipFile(tmp, "w") as z:
            z.writestr(zipfile.ZipInfo("mimetype"), self.data["mimetype"], compress_type=zipfile.ZIP_STORED)
            for n in self.names:
                if n == "mimetype": continue
                z.writestr(n, self.data[n], compress_type=zipfile.ZIP_DEFLATED)
        os.replace(tmp, self.path)
        import xml.dom.minidom
        xml.dom.minidom.parseString(self.xml.encode("utf8"))     # still well-formed?
        return self.log
