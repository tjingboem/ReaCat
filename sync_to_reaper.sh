#!/bin/bash
# One-way sync: git repo (source of truth) -> REAPER's live Scripts copy. No --delete: the live folder may hold other files.
rsync -av --exclude='.git' --exclude='doc' --exclude='tests' --exclude='tools' --exclude='toolbar_icons' --exclude='CLAUDE.md' --exclude='sync_to_reaper.sh' \
  ~/Claude/ReaCat/ /home/tjingboem/.config/REAPER/Scripts/tjingboem/ReaCat/
mkdir -p ~/.config/REAPER/Data/toolbar_icons && cp ~/Claude/ReaCat/toolbar_icons/*.png ~/.config/REAPER/Data/toolbar_icons/   # toolbar icon (90x30, 3 states)
