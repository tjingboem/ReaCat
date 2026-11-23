#!/usr/bin/env python3
# patch_minervacl_sends_rules.py (23 Nov 2026): MinervaCL's own Output target now sends a rule for every parameter
# and the rhythm too, its own real athenaCL text, not only the derived curves. Run once (it refuses to run twice:
# the text it replaces is gone after the first run). Backup: ReaAC.odt.bak-2026-11-23-minervacl-sends-rules (untracked).
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from odt_edit import Odt
ROOT = os.path.expanduser("~/Claude")
TAG = "2026-11-23-minervacl-sends-rules"

d = Odt(ROOT + "/ReaAC/doc/ReaAC.odt", TAG)
d.replace(
  "Markov, Xenakis Sieve and GA Rhythm send a rule as well.",
  "Markov, Xenakis Sieve and GA Rhythm send a rule as well. MinervaCL's own Target sends a rule too, one for every "
  "parameter and one for the rhythm — but its own, real athenaCL text, not a translation of a simpler idea, so "
  "taking one of them back (with Import) restores the real generator, not only its curve.")
log = d.save()
for line in log: print(line)
