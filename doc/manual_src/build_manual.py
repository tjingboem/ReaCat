#!/usr/bin/env python3
# build_manual.py: builds doc/ReaCat.odt (plain ODF, no LibreOffice needed), in the layout of ReaNvelopes' manual
# (its styles.xml, meta and manifest are the template; keep that file at ../ReaNvelopes/doc/ReaNvelopes_Manual.odt).
# Usage:  python3 doc/manual_src/build_manual.py
import re, sys, zipfile, os
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "..", "..", "..", "ReaNvelopes", "doc", "ReaNvelopes_Manual.odt")
OUT = os.path.join(HERE, "..", "ReaCat.odt")

def inline(t):
    t = escape(t)
    return re.sub(r"\*\*(.+?)\*\*", r'<text:span text:style-name="B">\1</text:span>', t)

body, toc, tables = [], [], []
n1 = n2 = 0

def h1(t):
    global n1, n2
    n1 += 1; n2 = 0
    label = "%d. %s" % (n1, t)
    toc.append((1, label))
    body.append('<text:h text:style-name="%s" text:outline-level="1">%s</text:h>' % ("H1First" if n1 == 1 else "H1", escape(label)))
def h2(t):
    global n2
    n2 += 1
    label = "%d.%d %s" % (n1, n2, t)
    toc.append((2, label))
    body.append('<text:h text:style-name="H2" text:outline-level="2">%s</text:h>' % escape(label))
def h3(t): body.append('<text:p text:style-name="H3">%s</text:p>' % escape(t))
def p(t): body.append('<text:p text:style-name="Body">%s</text:p>' % inline(t))
def note(t): body.append('<text:p text:style-name="Note">%s</text:p>' % inline(t))
def bullets(items):
    body.append('<text:list text:style-name="LBul">' + "".join(
        '<text:list-item><text:p text:style-name="ListText">%s</text:p></text:list-item>' % inline(i) for i in items) + '</text:list>')
def numbered(items):
    body.append('<text:list text:style-name="LNum">' + "".join(
        '<text:list-item><text:p text:style-name="ListText">%s</text:p></text:list-item>' % inline(i) for i in items) + '</text:list>')
def table(head, rows, widths):
    k = len(tables) + 1
    tables.append((k, widths))
    x = '<table:table table:name="Tbl%d" table:style-name="Tbl%d">' % (k, k)
    x += "".join('<table:table-column table:style-name="Tbl%d.C%d"/>' % (k, i) for i in range(len(widths)))
    x += "<table:table-header-rows><table:table-row>" + "".join(
        '<table:table-cell table:style-name="CellH" office:value-type="string"><text:p text:style-name="TableHead">%s</text:p></table:table-cell>' % inline(c) for c in head) + "</table:table-row></table:table-header-rows>"
    for r in rows:
        x += "<table:table-row>"
        for i, c in enumerate(r):
            x += '<table:table-cell table:style-name="Cell" office:value-type="string"><text:p text:style-name="%s">%s</text:p></table:table-cell>' % ("TableFirst" if i == 0 else "TableText", inline(c))
        x += "</table:table-row>"
    x += "</table:table>"
    body.append(x)

# ---------------------------------------------------------------- the text
h1("What ReaCat is")
p("ReaCat is a catalogue of curves. Many of the author's tools make curves: ReaNvelopes makes random shapes, polygon LFOs and drawn lines, and the modules of ReaAC make the path of an attractor, the density of a cellular automaton, a random walk and more. Other tools need a curve: MinervaCL steers its parameters with curves, and ReaMaskM and ReaShapeM take a curve as an envelope. ReaCat sits between them.")
p("A tool that makes a curve sends it to ReaCat. A tool that needs a curve takes one from ReaCat. The two do not have to know each other, and a tool that does not exist yet can use the same catalogue.")
bullets([
    "**Send.** In a tool that makes curves, the Output target **Send to ReaCat and the world** puts its curves in the catalogue. Nothing is written into your project.",
    "**Keep.** The catalogue keeps every curve with its date, the tool it came from, tags that you can add, and a small picture of its shape.",
    "**Take.** A tool that needs a curve has two buttons: **Latest** takes the newest curve, and **ReaCat...** opens the catalogue as small pictures, so that you can choose.",
    "**Remember.** A curve that a tool took or wrote into your project is marked red in ReaCat, and ReaSnap can bring the curves of a project back on another computer.",
])
note("ReaCat only keeps copies. It does not change what a tool has already written into your project, and a curve in the catalogue never changes after it was sent.")

h1("Installation")
h2("What you need")
table(["What", "Why"], [
    ["REAPER", "ReaCat is a script that runs inside REAPER."],
    ["ReaImGui", "The window is drawn with it. Install it with ReaPack (Extensions, ReaPack, Browse packages)."],
    ["ReaSnap (optional)", "Gives ReaCat a button in the Launcher, a numbered window title, Close All, and the capture and restore of a project's curves. ReaCat works without it."],
], [4.0, 13.0])
h2("Loading the script")
p("In REAPER choose **Actions, Show action list, ReaScript: Load...** and select **ReaCat.lua** in the ReaCat folder. Run it from the list, or give it a key or a toolbar button. The window opens. The first time, the catalogue is empty.")
p("To register ReaCat with ReaSnap, copy its command ID from the action list (right-click the action, Copy selected action command ID) and put it in ReaSnap's list of tools. The ID belongs to the place the script was loaded from.")
h2("Trying it with sample curves")
p("The script **tools/seed_samples.lua** puts ten sample curves in the catalogue, all tagged **sample**: a sine, ramps, a triangle, a staircase, a gate, a swell, a bounce, a random walk and a curved S. Load and run it once from the action list. Search **tag:sample** to find them again, and delete them when you are done. Running it twice adds nothing new.")
h2("Where the catalogue is kept")
p("The catalogue is a folder, **Data/ReaCat** inside REAPER's resource folder (Options, Show REAPER resource path in explorer/finder). Each curve is one small text file, so the catalogue is plain, readable and easy to back up: copy the folder. A curve that you delete waits in the folder **_trash** inside it, until you empty that folder yourself.")

h1("The window")
h2("The parts of the window")
table(["Part", "What it does"], [
    ["Search box", "Type words to find curves. It understands AND, OR, NOT, brackets, quotes and field searches (3.2). A search that cannot be read is shown in red under the box and does not filter the list."],
    ["Date and sort", "The list can show all dates, today, the last 7 or 30 days, or a range you type as YYYY-MM-DD. It can be sorted newest first, oldest first, or by tool. The date is the day the curve was last sent."],
    ["Tags", "Every tag in the catalogue, with how many curves have it, in two lines that scroll sideways: turn the mouse wheel over them, and press Home to go back to the start. The tags with the name of a project come first and are amber, then the others, the most used first. A click adds the tag to the search, another click takes it out."],
    ["Pictures", "Each curve drawn small, without a name under it: hover a picture, or select it, and the information panel says what it is. A rule (the text that Markov, Xenakis Sieve, GA Rhythm and MinervaCL send) is drawn as a small box with its text. A star in the corner marks a curve that you keep."],
    ["Information", "Hover a picture, or select it, to see the large picture, the dates, the number of points, the range of the curve, its tags and note, and where it is used."],
    ["Bottom line", "The cleanup limit, Undo delete, messages, and the setting for item names (6.3)."],
], [3.5, 13.5])
h2("Searching")
p("The search looks at the name, the tool, the tags, the note and the project of every curve. A word matches part of a word, and capitals do not matter.")
table(["You write", "It finds"], [
    ["lorenz", "curves with lorenz in the name, tool, tags, note or project"],
    ["lorenz smooth", "both words (a space means AND)"],
    ["lorenz OR rossler", "either one. AND, OR and NOT are written in capitals."],
    ["NOT step  or  -step", "curves without step"],
    ["(lorenz OR rossler) AND smooth", "brackets group; without brackets NOT comes first, then AND, then OR"],
    ["\"first idea\"", "the words together, in that order"],
    ["tag:smooth", "only the tags, and the whole tag: tag:smooth does not find a tag smoothed. Use quotes for a tag of several words: tag:\"my tag\""],
    ["source:Sieve   name:x   note:bridge", "only that field (the tool, the name, the note)"],
    ["project:song", "only the project name"],
    ["used:", "curves that are used in the open project (6). NOT used: finds the others."],
], [6.0, 11.0])
p("The date choice next to the search box is joined to the search with AND. **Clear** takes the search and the date away.")
h2("Tags")
p("Every curve gets tags when it is sent: the tool, the name of the curve, and one word for its shape: **straight**, **smooth** or **step**. A curve that a tool wrote into your project also gets **written**.")
p("The **project** is a tag too, shown in amber: the name of the REAPER project when the curve was sent, without .RPP, or **Unsaved Project** when the project had no file yet. It stays as it was written. It cannot be removed, and it is found by tag:\"name\", by project: and by a plain word.")
p("Your own tags: select a curve and type in the field **add a tag** (Enter). While you type, tags that already exist and begin the same way are offered as small buttons. A click on a tag in the list of a selected curve (it carries a small x) removes it. Tags can be added or removed at any time, also long after the curve was sent. With several curves selected (3.4) one tag goes to all of them, and the field says so.")
h2("What the clicks do")
table(["Click", "In the ReaCat window", "In a tool's picker"], [
    ["Click", "Selects the curve and shows its information, with the fields to edit its tags and note.", "Takes the curve."],
    ["Shift+click", "(nothing extra)", "Shows the information and the fields to edit tags and note, without taking it."],
    ["Ctrl+click", "Adds the curve to the selection, or takes it out. Selected curves have an orange border.", "(nothing extra)"],
    ["Double-click", "Sends the curve again: it becomes the newest one, so Latest takes it. The line at the bottom says so.", "(nothing extra)"],
    ["Right-click", "Deletes the curve (all selected curves if it is one of them). It goes to the trash, and Undo delete at the bottom brings the last deletion back.", "(nothing extra)"],
], [2.6, 8.6, 5.8])
p("The same as a double-click is the green button **Send** under the large picture in the information of a selected curve. It makes the curve the newest one, so that **Latest** in ReaMaskM, ReaShapeM, MinervaCL and every other tool takes exactly that curve: you find the shape you need here, press Send, and in the tool you press Latest, with no second search. The bottom line says what was sent. (A curve that you send moves to the front of the list, because the list is ordered by the day a curve was last sent.)")
h2("Notes, keeping and cleaning up")
p("A selected curve has a **note** field (one line, kept when you leave the field) and a box **keep**: a curve that is kept is never proposed by the cleanup.")
p("The catalogue can grow. The box at the bottom, **max entries**, holds your limit: when the catalogue grows beyond it a cleanup is suggested. It is 2000 to begin with, any number you type, and 0 means never. When the catalogue holds more, the bottom line shows the number in red with the button **Clean up...**. That window lists the oldest curves first: first those that are not used in the open project, and only after them the used ones. Curves that you keep are never in the list. Untick what you want to keep, and press **Move to the trash**. Nothing is deleted without that press, and Undo delete brings it back.")

h1("Sending curves")
h2("From ReaNvelopes")
p("In the OUTPUT section of RAND, OSC or DRAW choose the target **Send to ReaCat and the world**. The button reads **SEND TO REACAT**. The curve goes as the preview shows it, with Flip X and Flip Y applied, with only as many points as its shape needs. It is named ReaNvelopes, then RAND, OSC or DRAW. No time selection, lane or item is needed.")
h2("From the ReaAC modules")
p("Every module of ReaAC that has an Output section has the Target **Send to ReaCat and the world**. With it **Insert to Project** sends all the curves of the module, each as its own curve, named after the module and the curve: the Lorenz module sends Lorenz Attractor x, y and z, Discrete Map sends x and y, Cellular Automata sends Density and Position, and so on. The values are between 0 and 1, as every curve in the catalogue is. Markov, Xenakis Sieve and GA Rhythm also send rules, the text of the same idea in athenaCL's language, for the MinervaCL module. The MinervaCL module sends rules too, one for every parameter and one for the rhythm — but its own, real athenaCL text, not a translation of a simpler idea, so taking one of them back (in MinervaCL, with Import) restores the real generator, not only its curve.")
h2("From ReaMaskM and ReaShapeM")
p("The dropdown **ReaCat** of ReaMaskM and ReaShapeM also sends: **Send to ReaCat and the world** puts the selected envelope in the catalogue as a curve, named ReaMaskM or ReaShapeM and the envelope, for example Pitch: Min Pitch or Time: Warp, and tagged with its group. The envelope fills the whole width and the whole height of the curve, as in the window. In ReaShapeM the time runs over the notes that you selected. An envelope with curved segments or Bezier points is sent in small steps, so that it keeps its shape. So a shape that you made in one of these tools can be used in MinervaCL, in the other of the two, or in any tool that takes curves.")
h2("What a tool writes into the project")
p("When a tool writes a curve into your project, as an automation item, as MIDI CC or pitch bend, or as note values, it also files a copy in the catalogue, tagged **written**, and marks it as used by the item or the automation item it went to (6). So everything that reached your project is in the catalogue too, ready to be used somewhere else, for example to open a filter or to make a note structure. If filing the copy fails, the write itself is not affected.")
h2("Sending twice")
p("The same curve from the same tool and the same name is stored once. Sending it again only makes it the newest. A curve that differs, because you changed a slider and sent again, is a new curve, and the catalogue keeps both. A tool that takes a curve with a link (MinervaCL's Linked) follows the newest one.")

h1("Taking curves")
h2("Latest and ReaCat...")
p("Every tool that takes curves offers the same two ways: two buttons, or, in ReaMaskM and ReaShapeM, two entries of one dropdown (5.3).")
bullets([
    "**Latest** takes the newest curve that the tool can use, from any tool. Use it when you have just sent a curve and want it at once, or after you pressed Send on a curve in the ReaCat window (3.4). The tool shows what it took, for example: took Lorenz Attractor x (Night Piece).",
    "**ReaCat...** opens the catalogue as pictures, with search, tags and dates, in a window of its own or under the buttons. A click on a picture takes that curve, also when a newer one with the same name exists.",
])
h2("MinervaCL")
p("In the MinervaCL module the **Import** button of every parameter, and of the Rhythm tab, opens a window with **Points**, **Low** and **High**, the choice **As Draw** or **As Choose**, the box **Linked**, and the two buttons. A curve becomes a Draw or a Choose of the parameter, scaled between Low and High (they start at the limits of the parameter). A rule of the right kind is kept as the Text of the parameter, and a rhythm rule becomes the rhythm of the layer. The details are in the MinervaCL chapter of the ReaAC manual (Import).")
h2("ReaMaskM and ReaShapeM")
p("In ReaMaskM and ReaShapeM the old button Take Curve from ReaNvelopes has become one dropdown, **ReaCat**. In ReaMaskM it stands under the preset name and the Save button, in the style of the BPM Grid dropdown. In ReaShapeM it stands in the bottom left corner, on the row of the steps. Its entries are **Latest**, **Open ReaCat** (the catalogue in a small window) and **Send to ReaCat and the world** (4.3). Choose the envelope that should receive the curve first. The curve replaces that envelope. It covers its whole width and its whole height: the bottom of the envelope is 0 and the top is 1, exactly as the curve is in the catalogue. What the values mean is up to you. A short message beside or under the dropdown says what happened.")
h2("Original range")
p("A curve in the catalogue is always between 0 and 1. Some tools also say what 0 and 1 stood for where the curve was made, for example the lowest and the highest pitch of a random walk. When you pick such a curve in MinervaCL, the box **Original range** appears: ticked, Low and High become that range instead of the limits of the parameter. ReaMaskM and ReaShapeM do not offer it, because a curve always covers the whole envelope there.")

h1("Used in this project")
h2("The red mark")
p("A curve that is used in the open project has a **red border** around its picture. The line above the pictures says how many curves are used. Search **used:** to list them. A tool marks a curve as used when it takes it into a parameter, an item or an envelope, or writes it into the project.")
note("While a used curve is selected (green or orange border) or under the pointer (white border), the border shows that colour and not red. The information then still says used in this project.")
note("The mark follows the content of the curve. If two curves in the catalogue are exactly the same line under different names, both are red when one of them is used.")
h2("Where it is used")
p("Select a curve that is red: the information shows **used in this project** and a line for every place, with the tool and the time. For an item or an automation item the button **select** selects it in REAPER and moves the edit cursor to its start. A parameter inside a tool, for example a parameter of MinervaCL, cannot be selected from here, and the line says which tool it is in. A place that no longer exists, because you deleted the item, is shown in red as gone; **Forget the places that are gone** removes those lines.")
h2("On the item")
p("When a tool uses a curve on a MIDI item, the item's **notes** get one line: ReaCat: Lorenz Attractor x, taken 2026-11-23 10:15, project Night Piece. Open the item's notes in REAPER to read it. A newer take of the same curve replaces its own line and nothing else in your notes. An automation item has no notes, so for it the information is only in ReaCat.")
p("If you want the name of the curve in the name of the item too, tick the box at the bottom of the ReaCat window: **Curve name on item** (the name is added when a tool uses a curve on an item). The name then ends with + ReaCat: Lorenz Attractor x. It is off to begin with, so your own item names stay as they are.")
h2("Saved with the project")
p("This record is kept inside the project file. When you take a curve, REAPER sees the project as changed and asks to save it when you close, so the red marks come back when you open the project again. The marks need the curves themselves to be in the catalogue. On a computer where the catalogue is empty, nothing shows red until the curves are back (7.2).")

h1("ReaSnap")
h2("The Launcher")
p("ReaCat has a row in the ReaSnap Launcher, with a cat face next to the Launch button. A window that ReaSnap starts is numbered in its title, for example ReaCat #2, and **Close All** closes it with the other windows of the project. There is only ever one ReaCat window: if you press Launch while it is open, or start the script again, the open window comes to the front and the second start ends. (REAPER asks whether to terminate the running script or start a new instance when you run a script that is already running: answer new instance, and tick remember.)")
p("ReaCat does not belong to an item, so it has no settings that a snapshot could bring back in the window, and the S button has nothing to scan. A Restore does not open it by itself.")
h2("Capture and Restore of the curves")
p("A **Capture** keeps the curves that this project needs inside the project: the curves that were sent while this project was open, and the curves that the project uses even if another project sent them. Each curve is kept once, not once for every snapshot. A **Restore**, **Restore and Replace** or **Return** puts the missing ones back into the catalogue of the computer you are on, as they were, with their tags, notes and dates. A curve that is already there is not added twice. A curve that you deleted on purpose, which is in the trash, stays gone.")
p("So you can move a project to another computer: capture a snapshot, save the project, open it there and restore the snapshot. The red marks and the curves are back.")

h1("Messages and questions")
h2("Messages")
table(["Message", "What it means"], [
    ["nothing to take yet", "The catalogue holds no curve of the kind this place can take. Send one first."],
    ["a bracket is never closed (red, under the search box)", "The search cannot be read. The list is not filtered until you fix it. The same goes for a quote that is never closed and for AND or OR at the end."],
    ["sent again: ... (now the newest)", "You double-clicked a curve. Latest will now take it."],
    ["that item is gone", "The item that used the curve was deleted. Use Forget the places that are gone."],
    ["this place is inside ..., there is nothing to select", "The curve is used in a parameter of a tool, not in an item or envelope."],
    ["could not write the catalogue", "The folder Data/ReaCat cannot be written, for example because the disk is full. The tool that sent the curve shows the message."],
], [6.0, 11.0])
h2("Questions")
p("**A curve that I deleted came back.** A Restore does not bring back curves that are in the trash. If the file was removed some other way, outside ReaCat, a Restore puts it back, because the project still keeps its own copy.")
p("**Where are the curves of another project?** In the same catalogue. All projects share it. The amber project tag tells you where a curve came from. Search project:name to see them.")
p("**Does the catalogue grow for ever?** It grows with what you send and write. The cleanup limit and the Clean up window are there for that, and the folder can also be emptied by hand: nothing in a project depends on it, because every tool keeps its own values in the project.")
p("**Why do several curves of mine have the tag written?** Every curve that a tool wrote into the project is filed with that tag. Search tag:written to see what has reached your projects.")

h1("Credits and licence")
p("ReaCat is written by tjingboem productions as part of a family of tools that share curves, settings and windows with each other: ReaNvelopes, ReaAC, ReaMaskM, ReaShapeM and ReaSnap. It contains no code from other people. The window is drawn with ReaImGui (Christian Fillion, LGPL version 3 or later; Dear ImGui inside it is MIT licensed). The licence of ReaCat itself has not been decided yet.")

# ---------------------------------------------------------------- assemble
tpl = zipfile.ZipFile(TEMPLATE)
content = tpl.read("content.xml").decode("utf8")
head = content[:content.index("<office:automatic-styles>")]
auto = "<office:automatic-styles>"
for k, widths in tables:
    auto += '<style:style style:name="Tbl%d" style:family="table"><style:table-properties style:width="17.00cm" table:align="left" fo:margin-top="0.2cm" fo:margin-bottom="0.35cm"/></style:style>' % k
    for i, w in enumerate(widths):
        auto += '<style:style style:name="Tbl%d.C%d" style:family="table-column"><style:table-column-properties style:column-width="%.2fcm"/></style:style>' % (k, i, w)
auto += "</office:automatic-styles>"
title = (
    '<text:p text:style-name="Title">ReaCat</text:p>'
    '<text:p text:style-name="Subtitle">The catalogue of envelopes for REAPER: every tool that makes a curve can send it, every tool that needs a curve can take it</text:p>'
    '<text:p text:style-name="TitleMeta">Manual, November 2026</text:p>'
    '<text:p text:style-name="TitleMeta">tjingboem productions</text:p>'
    '<text:p text:style-name="TocTitle">Contents</text:p>')
tocx = ('<text:table-of-content text:protected="false" text:name="Contents"><text:table-of-content-source text:outline-level="2">'
        '<text:index-title-template text:style-name="TocTitle">Contents</text:index-title-template>'
        '<text:table-of-content-entry-template text:outline-level="1" text:style-name="Toc1"><text:index-entry-text/></text:table-of-content-entry-template>'
        '<text:table-of-content-entry-template text:outline-level="2" text:style-name="Toc2"><text:index-entry-text/></text:table-of-content-entry-template>'
        '</text:table-of-content-source><text:index-body>' +
        "".join('<text:p text:style-name="Toc%d">%s</text:p>' % (lv, escape(t)) for lv, t in toc) +
        '</text:index-body></text:table-of-content>')
doc = head + auto + "<office:body><office:text>" + title + tocx + "".join(body) + "</office:text></office:body></office:document-content>"

styles = tpl.read("styles.xml").decode("utf8").replace("ReaNvelopes manual, page", "ReaCat manual, page")
meta = tpl.read("meta.xml").decode("utf8").replace("ReaNvelopes manual", "ReaCat manual").replace("2026-10-21T12:00:00", "2026-11-23T12:00:00")
manifest = tpl.read("META-INF/manifest.xml")

# well-formed?
import xml.dom.minidom
xml.dom.minidom.parseString(doc.encode("utf8"))
with zipfile.ZipFile(OUT, "w") as z:
    z.writestr(zipfile.ZipInfo("mimetype"), "application/vnd.oasis.opendocument.text", compress_type=zipfile.ZIP_STORED)
    z.writestr("content.xml", doc, compress_type=zipfile.ZIP_DEFLATED)
    z.writestr("styles.xml", styles, compress_type=zipfile.ZIP_DEFLATED)
    z.writestr("meta.xml", meta, compress_type=zipfile.ZIP_DEFLATED)
    z.writestr("META-INF/manifest.xml", manifest, compress_type=zipfile.ZIP_DEFLATED)
words = len(re.sub(r"<[^>]+>", " ", "".join(body)).split())
print("built", os.path.normpath(OUT), "-", words, "words,", len(tables), "tables,", len(toc), "headings")
