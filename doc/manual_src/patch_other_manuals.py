#!/usr/bin/env python3
# patch_other_manuals.py (23 Nov 2026): the manuals of ReaNvelopes, ReaMaskM, ReaShapeM and ReaAC now speak of ReaCat. Run once (it refuses to run twice:
# the text it replaces is gone after the first run). Backups: <manual>.bak-2026-11-23-preReaCat (untracked).
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from odt_edit import Odt
ROOT = os.path.expanduser("~/Claude")
TAG = "2026-11-23-preReaCat"

# ------------------------------------------------------------------ ReaNvelopes
d = Odt(ROOT + "/ReaNvelopes/doc/ReaNvelopes_Manual.odt", TAG)
d.replace("6.4 Target: send to ReaMaskM / ReaShapeM", "6.4 Target: send to ReaCat and the world", 2)
d.replace("Parameter envelope, MIDI CC / pitch bend / pressure, Note value, Send to ReaMaskM / ReaShapeM", "Parameter envelope, MIDI CC / pitch bend / pressure, Note value, Send to ReaCat and the world")
B = lambda t: '<text:span text:style-name="B">%s</text:span>' % t
d.rewrite("SEND CURVE stores nothing on an item",
  B("SEND TO REACAT") + " stores nothing on an item, because nothing is written into the project. The ReaCat catalogue keeps the curve, and the tool that takes it remembers it. To get the shape of a curve you sent back in ReaNvelopes, save it as a preset (3.3).")
d.insert_after("SEND TO REACAT stores nothing on an item",
  '<text:p text:style-name="Body">' + B("Filed in ReaCat.") + " A curve that ReaNvelopes writes into the project (an automation item, MIDI CC, pitch bend, pressure or note values) is also filed in the ReaCat catalogue, tagged written, and marked as used by the item or automation item it went to. The notes of the item get one line, for example: ReaCat: ReaNvelopes RAND, taken 2026-11-23 10:15, project Night Piece. If filing fails, the write itself is not affected. See the manual of ReaCat.</text:p>")
d.rewrite("The button reads SEND CURVE",
  "The button reads " + B("SEND TO REACAT") + ". It sends the curve as the preview shows it, with Flip X and Flip Y applied, to the ReaCat catalogue, named ReaNvelopes and the generator: RAND, OSC or DRAW. Nothing is written into the project, so no time selection, envelope lane or item is needed.")
d.rewrite("In ReaMaskM or ReaShapeM, choose the envelope",
  "Any tool that takes curves can then take it. In ReaMaskM or ReaShapeM, choose the envelope that should receive the curve and press " + B("Latest") + " (the newest curve in the catalogue) or " + B("ReaCat...") + " (choose from small pictures, with search and tags). The curve replaces that envelope. It covers its whole width and its whole height: the bottom of the envelope is 0 and the top is 1, exactly as the curve is here. What the values mean is up to you, so for an envelope with a middle line, make the curve around the middle. In the MinervaCL module of ReaAC the Import button of a parameter takes a curve in the same way.")
d.rewrite("The curve is sent with only as many points as its shape needs",
  "The curve is sent with only as many points as its shape needs. RAND and DRAW send their points together with the line shape of each segment, and OSC, or any curve made of many small steps, is sent as a few smooth segments. This is enough to adjust the curve further in the receiving tool, or here, and send it again. The catalogue keeps every curve you sent, also after REAPER has been restarted.")
for line in d.save(): print("ReaNvelopes:", line)

# ------------------------------------------------------------------ ReaMaskM
d = Odt(ROOT + "/ReaMaskM/doc/ReaMaskM.odt", TAG)
d.replace('<text:h text:style-name="P26" text:outline-level="1">Take Curve from ReaNvelopes</text:h>', '<text:h text:style-name="P26" text:outline-level="1">Take a curve from ReaCat</text:h>')
d.replace("Take Curve from ReaNvelopes brings a curve made in ReaNvelopes into the envelope that is selected in ReaMaskM. In ReaNvelopes, generate or draw the curve (RAND, OSC or DRAW), set the target to Send to ReaMaskM / ReaShapeM and press SEND CURVE. Then, in ReaMaskM, choose the envelope and press Take Curve from ReaNvelopes, above the Generate button.",
  "Take a curve from ReaCat brings a curve from the ReaCat catalogue into the envelope that is selected in ReaMaskM. In ReaNvelopes, or in a module of ReaAC, generate or draw the curve and send it with the target Send to ReaCat and the world. Then, in ReaMaskM, choose the envelope and press Latest, above the Generate button, to take the newest curve in the catalogue, or ReaCat... to choose one from small pictures, with search and tags. (Without ReaCat.lua and ReaCatPicker.lua next to ReaMaskM.lua the old button Take Curve from ReaNvelopes stays.)")
d.replace("so you can adjust it further here, with the usual point and handle editing, or back in ReaNvelopes, and send it again.</text:p>",
  "so you can adjust it further here, with the usual point and handle editing, or back in ReaNvelopes, and send it again. The project remembers that the curve is used here, and ReaCat shows it with a red mark.</text:p>")
for line in d.save(): print("ReaMaskM:", line)

# ------------------------------------------------------------------ ReaShapeM
d = Odt(ROOT + "/ReaShapeM/doc/ReaShapeM.odt", TAG)
d.replace("A small grey label beside the Take Curve from ReaNvelopes button, under the envelope button", "A small grey label beside the Latest and ReaCat... buttons, under the envelope button")
d.replace('<text:h text:style-name="P23" text:outline-level="2">Take Curve from ReaNvelopes</text:h>', '<text:h text:style-name="P23" text:outline-level="2">Take a curve from ReaCat</text:h>')
d.replace("Take Curve from ReaNvelopes brings a curve made in ReaNvelopes into the envelope that is selected in ReaShapeM. In ReaNvelopes, generate or draw the curve (RAND, OSC or DRAW) and press SEND CURVE. Then, in ReaShapeM, choose the envelope and press Take Curve from ReaNvelopes. The button sits on its own line under the envelope button at the top of the window, and the text beside it reports what happened, for example how many points were taken.",
  "Take a curve from ReaCat brings a curve from the ReaCat catalogue into the envelope that is selected in ReaShapeM. In ReaNvelopes, or in a module of ReaAC, generate or draw the curve and send it with the target Send to ReaCat and the world. Then, in ReaShapeM, choose the envelope and press Latest (the newest curve in the catalogue) or ReaCat... (choose from small pictures, with search and tags). The buttons sit on their own line under the envelope button at the top of the window, and the text beside them reports what happened, for example how many points were taken. The project remembers that the curve is used here, and ReaCat shows it with a red mark.")
d.replace("Take Curve from ReaNvelopes changes the envelope and not the notes, so the U button does not reverse it.", "Taking a curve changes the envelope and not the notes, so the U button does not reverse it.")
for line in d.save(): print("ReaShapeM:", line)

# ------------------------------------------------------------------ ReaAC
d = Odt(ROOT + "/ReaAC/doc/ReaAC.odt", TAG)
T = lambda t: '<text:span text:style-name="T1">%s</text:span>' % t
OLD_PREFIX = (T("Send to MinervaCL.") + " The Output " + T("Target") + " " + T("MinervaCL (send the curves)") +
              " puts the curves of this module on a shelf, from which the MinervaCL module takes them with its " + T("Import") + " button; " + T("Insert to Project") + " sends them.")
NEW_PREFIX = (T("Send to ReaCat and the world.") + " The Output " + T("Target") + " " + T("Send to ReaCat and the world") +
              " puts the curves of this module in the ReaCat catalogue, from which the MinervaCL module and every other tool can take them (" + T("Latest") + " or " + T("ReaCat...") + "); " + T("Insert to Project") + " sends them.")
d.replace(OLD_PREFIX, NEW_PREFIX, 9)
d.rewrite("Notes (the default); MIDI CC / pitch bend / pressure; Parameter envelope; Note velocity",
  "Notes (the default); MIDI CC / pitch bend / pressure; Parameter envelope; Note velocity (selected MIDI item); and " + T("Send to ReaCat and the world") + ", described under Send to ReaCat and the world below. Every module that has an Output section has this fifth entry.")
d.rewrite("Send to MinervaCL. In the nine editor modules",
  T("Send to ReaCat and the world.") + " Every module that has an Output section has a fifth Target entry, " + T("Send to ReaCat and the world") + ". With it, " + T("Insert to Project") +
  " puts all the curves of the module in the ReaCat catalogue, each as a curve between 0 and 1, named after the module and the curve (the Lorenz module sends Lorenz Attractor x, y and z), together with the rules of the modules that have them. Nothing is written into the project. Anyone can then take them: the " + T("Import") +
  " button of every parameter in the MinervaCL module, " + T("Take Curve") + " in ReaMaskM and ReaShapeM, and any other tool that reads the catalogue. The catalogue keeps everything that was sent, also after REAPER has been restarted, and the same curve sent twice is stored once. When a module writes a curve into the project (MIDI CC, note velocity or an envelope), a copy is also filed in the catalogue, tagged written, and marked as used by the item or automation item it went to. The manual of ReaCat describes the catalogue.")
d.rewrite("MinervaCL and its editors. The modules whose Output Target list",
  T("MinervaCL and its editors.") + " MinervaCL takes its generators from other modules, through ReaCat. Nine modules are its editors: Strange Attractor, Discrete Map, Random Walk, Cellular Automata, Game of Life, Markov, Lindenmayer System, Xenakis Sieve and GA Rhythm (every module can send to ReaCat, but these nine stay open together with MinervaCL, see One Window). MinervaCL has a special place among the modules. The others make notes from one algorithm; MinervaCL builds a layer whose every property is steered by a generator, and it can take those generators from the editors. With the Target " + T("Send to ReaCat and the world") +
  ", Insert to Project sends the curves of an editor, scaled between 0 and 1, instead of notes; Markov, Xenakis Sieve and GA Rhythm send a rule as well. In MinervaCL the Import button of a parameter takes what was sent (Latest, or chosen in ReaCat...) and turns it into a Draw, a Choose or a rule, and keeps it linked: move a slider in the editor, send again, and the layer follows. So you shape a curve, a chain or a sieve in the module that knows it best, and let MinervaCL use it to steer loudness, register, speed or rhythm. While a MinervaCL window is open, it and these modules stay open together; any other module still replaces them, and they replace it.")
d.rewrite("Import. The Import button, left of Text, takes a series",
  T("Import.") + " The " + T("Import") + " button, left of " + T("Text") + ", takes a curve from the ReaCat catalogue (one that a module sent with the Output target " + T("Send to ReaCat and the world") +
  ", from any module of ReaAC or from ReaNvelopes) and turns it into a way of this parameter. The window has two buttons: " + T("Latest") + " takes the newest curve in the catalogue, and " + T("ReaCat...") +
  " opens the catalogue as small pictures, with search and tags (see the manual of ReaCat); a click on a picture takes that curve, also when a newer one with the same name exists. " + T("Points") +
  " says how many values are taken (it starts at the number of values the curve holds, so the curve comes over whole; you can type another number, 2 to 512 for a Draw and 2 to 128 for a Choose; the curve is read at that many evenly spaced places. Too few points lose the shape: a curve of fourteen cycles needs at least about eight points to a cycle), and " + T("Low") + " and " + T("High") +
  " give the range the curve 0 to 1 is scaled to; they start at the limits of the parameter. When you pick a curve that knows what 0 and 1 stood for where it was made, the box " + T("Original range") + " appears in the catalogue window: ticked, Low and High become that range. " + T("As Draw") +
  " spreads the points over the time range as a line, once, so a drifting attractor can slowly change a tremolo; " + T("As Choose") + " makes a list of the values that is taken in order, one for every event. What you get is an ordinary Draw or Choose: you can edit it, see its text under " + T("Text") +
  ", and the item keeps the values. With the box " + T("Linked: update when the module sends again") + " ticked (the default), the parameter also stays linked to its curve: the button then reads " + T("Linked") +
  " and is lit, and when you send again from the module, for example after moving a slider in Strange Attractor, the parameter takes the newest curve with the same name, with the same points, range and kind, and the notes follow. If you edit the parameter yourself, by moving a point, choosing another way or changing a value, the link is dropped at once and nothing you made is overwritten; " + T("Unlink") +
  " in the same window drops it too. The link is kept with the item: after you reopen it, the next send from the same module updates the parameter if you have not changed it since. Changing Start or End does not break the link. The status line says what was taken, for example took Lorenz Attractor x (Night Piece), and the project remembers that the curve is used here: ReaCat shows it with a red mark.")
d.replace("In the " + T("Import") + " window of a strip the value rules are listed under the series, and " + T("As rule (Text)") + " puts one in as the Text of the parameter, taken to ",
          "In the " + T("Import") + " window of a strip a value rule that you take, with " + T("Latest") + " or from " + T("ReaCat...") + ", goes in as the Text of the parameter, taken to ")
d.replace("In the Rhythm tab an " + T("Import") + " button, left of " + T("Text") + ", lists the rhythm rules (the GA rhythm, and the pulse sieve of Xenakis Sieve) and puts one in as the rhythm of the layer.",
          "In the Rhythm tab an " + T("Import") + " button, left of " + T("Text") + ", takes a rhythm rule from the catalogue (the GA rhythm, and the pulse sieve of Xenakis Sieve; " + T("Latest") + " or " + T("ReaCat...") + ") and puts it in as the rhythm of the layer.")
d.replace("Some modules send, besides series, a ", "Some modules send, besides curves, a ")
for line in d.save(): print("ReaAC:", line)
