#!/usr/bin/env python3
# patch_step6_manuals.py (23 Nov 2026): the old one-slot place is gone, so ReaMaskM's manual no longer says that the old button stays without the ReaCat files.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from odt_edit import Odt
d = Odt(os.path.expanduser("~/Claude/ReaMaskM/doc/ReaMaskM.odt"), "2026-11-23-preReaCat")
d.replace("(Without ReaCat.lua and ReaCatPicker.lua next to ReaMaskM.lua the old button Take Curve from ReaNvelopes stays.)",
          "(Taking a curve needs ReaCat.lua and ReaCatPicker.lua next to ReaMaskM.lua; without them a grey note in the place of the buttons says so.)")
for line in d.save(): print("ReaMaskM:", line)
