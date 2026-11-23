#!/bin/bash
# run_in_reaper.sh script.lua [seconds]: runs a Lua ReaScript in a REAPER of its own (own settings folder, empty project, own catalogue).
# Needs RT_REACAT (the ReaCat folder). Copies ReaImGui in. The script writes results.txt (ending with the line DONE) into RT_OUT.
# If the script writes the file READY into RT_OUT and SHOT is set, a screenshot of the part of the desktop given in CROP (WxH+X+Y, default 1000x1000+1300+0) is taken to $SHOT, then the file GO is made. The whole desktop is never saved.
# Your normal REAPER is never touched.
WORK=$(mktemp -d ${TMPDIR:-/tmp}/reacat_rt.XXXXXX); mkdir -p $WORK/cfg $WORK/out
for f in reaper-vstplugins64.ini reaper-vstshells64.ini reaper-clap-linux-x86_64.ini; do [ -f ~/.config/REAPER/$f ] && cp ~/.config/REAPER/$f $WORK/cfg/; done
mkdir -p $WORK/cfg/UserPlugins; for f in ~/.config/REAPER/UserPlugins/reaper_imgui*.so; do [ -f "$f" ] && cp "$f" $WORK/cfg/UserPlugins/; done
LIMIT=${2:-90}
RT_OUT=$WORK/out timeout $LIMIT reaper -cfgfile $WORK/cfg/reaper.ini -nosplash -newinst -new "$1" > $WORK/out/stdout.txt 2>&1 &
for i in $(seq 1 $LIMIT); do
  sleep 1
  if [ -f $WORK/out/READY ] && [ ! -f $WORK/out/GO ]; then
    sleep 1; [ -n "$SHOT" ] && import -window root -crop "${CROP:-1000x1000+1300+0}" +repage "$SHOT" 2>/dev/null; touch $WORK/out/GO
  fi
  grep -q '^DONE$' $WORK/out/results.txt 2>/dev/null && break
done
pkill -f "cfgfile $WORK/cfg" 2>/dev/null; sleep 2
cat $WORK/out/results.txt 2>/dev/null || { echo "no results"; tail -3 $WORK/out/stdout.txt; }
rm -rf $WORK
