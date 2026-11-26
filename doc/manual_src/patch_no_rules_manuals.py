#!/usr/bin/env python3
# patch_no_rules_manuals.py (26 Nov 2026): ReaCat holds shapes only; rules (athenaCL text) are no longer sent. Edits ReaAC.odt accordingly.
# Backup ReaAC.odt.bak-2026-11-26-noRules (untracked). Refuses to run twice (the text it replaces is gone).
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from odt_edit import Odt
d = Odt(os.path.expanduser("~/Claude/ReaAC/doc/ReaAC.odt"), "2026-11-26-noRules")
# 1. the Output Target paragraph
d.replace("(the Lorenz module sends Lorenz Attractor x, y and z), together with the rules of the modules that have them. Nothing is written",
          "(the Lorenz module sends Lorenz Attractor x, y and z). Rules, the athenaCL text that some modules know, are not sent: ReaCat holds shapes only. Nothing is written")
# 2. MinervaCL and its editors
d.replace("instead of notes; Markov, Xenakis Sieve and GA Rhythm send a rule as well. MinervaCL's own Target sends a rule too, one for every parameter and one for the rhythm — but its own, real athenaCL text, not a translation of a simpler idea, so taking one of them back (with Import) restores the real generator, not only its curve. In MinervaCL the Import button of a parameter takes what was sent (Latest, or chosen in ReaCat...) and turns it into a Draw, a Choose or a rule, and keeps it linked:",
          "instead of notes. In MinervaCL the Import button of a parameter takes what was sent (Latest, or chosen in ReaCat...) and turns it into a Draw or a Choose, and keeps it linked:")
# 3. the paragraph about rules from other modules
m = re.search(r'(<text:p text:style-name="Text_20_body">)<text:span text:style-name="T1">Rules from other modules\.</text:span>.*?</text:p>', d.xml, re.S)
if not m: raise SystemExit("paragraph 'Rules from other modules' not found")
new = (m.group(1) + '<text:span text:style-name="T1">Rules are not sent.</text:span> A rule is athenaCL\'s own text for a generator, and only MinervaCL understands it, so it stays '
       'in the module. ReaCat is a catalogue of shapes: the modules send their curves, and Markov, Xenakis Sieve and GA Rhythm send the shape of what they make, '
       'which MinervaCL takes with Import as a Draw or a Choose.</text:p>')
d.xml = d.xml[:m.start()] + new + d.xml[m.end():]
d.log.append("rewrote 'Rules from other modules'")
for line in d.save(): print(line)
