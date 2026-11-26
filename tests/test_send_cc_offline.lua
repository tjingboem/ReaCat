-- test_send_cc_offline.lua (26 Nov 2026): Cat.sendToMidiCC with a stand-in `reaper` that holds one MIDI take. Run from the repo root:
--   lua5.4 tests/test_send_cc_offline.lua
package.path = "lib/?.lua;" .. package.path
local root = (os.getenv("TMPDIR") or "/tmp") .. "/reacat_sendcc_" .. os.time() .. "_" .. math.random(100000)
os.execute("mkdir -p '" .. root .. "'")
local ext, proj = {}, {}
local PPQ = 1000                                   -- ticks per second in the stand-in
local evs = {}                                     -- { ppq, chanmsg, chan, msg2, msg3, shape }
local lane, defChan, editorOpen = 1, 2, true
local item = { pos = 4, len = 8 }
local ts = { 0, 0 }                                -- the time selection
local undo = {}
local take = {}
local function sortEvs() table.sort(evs, function(a, b) return a.ppq < b.ppq end) end
reaper = setmetatable({
  GetResourcePath = function() return root end,
  RecursiveCreateDirectory = function(p) os.execute("mkdir -p '" .. p .. "'") return 1 end,
  EnumerateFiles = function(dir, i)
    if i < 0 then return nil end
    local p = io.popen("find '" .. dir .. "' -maxdepth 1 -type f 2>/dev/null | sort")
    local k = 0
    for path in p:lines() do if k == i then p:close() return (path:match("([^/]+)$")) end k = k + 1 end
    p:close() return nil
  end,
  GetExtState = function(s, k) return ext[s .. "/" .. k] or "" end,
  SetExtState = function(s, k, v) ext[s .. "/" .. k] = v end,
  GetProjExtState = function(_, s, k) local v = proj[s .. "/" .. k] return v and 1 or 0, v or "" end,
  SetProjExtState = function(_, s, k, v) proj[s .. "/" .. k] = (v ~= "") and v or nil return 0 end,
  MarkProjectDirty = function() end, GetProjectName = function() return "" end, genGuid = function() return "{TEST-PROJECT-ID}" end,
  MIDIEditor_GetActive = function() return editorOpen and {} or nil end,
  MIDIEditor_GetTake = function() return take end,
  MIDIEditor_GetSetting_int = function(_, what) if what == "last_clicked_cc_lane" then return lane end return defChan end,
  TakeIsMIDI = function() return true end,
  GetMediaItemTake_Item = function() return item end,
  GetMediaItemInfo_Value = function(_, what) return what == "D_POSITION" and item.pos or item.len end,
  GetSetMediaItemInfo_String = function() return true, "{ITEM-GUID-1}" end,
  GetSet_LoopTimeRange = function() return ts[1], ts[2] end,
  MIDI_GetPPQPosFromProjTime = function(_, t) return (t - item.pos) * PPQ end,
  MIDI_GetProjTimeFromPPQPos = function(_, ppq) return item.pos + ppq / PPQ end,
  MIDI_DisableSort = function() end,
  MIDI_Sort = function() sortEvs() end,
  MIDI_CountEvts = function() return true, 0, #evs, 0 end,
  MIDI_GetCC = function(_, i) local e = evs[i + 1] if not e then return false end return true, false, false, e.ppq, e.chanmsg, e.chan, e.msg2, e.msg3 end,
  MIDI_DeleteCC = function(_, i) table.remove(evs, i + 1) return true end,
  MIDI_InsertCC = function(_, _, _, ppq, cm, ch, m2, m3) evs[#evs + 1] = { ppq = ppq, chanmsg = cm, chan = ch, msg2 = m2, msg3 = m3, shape = 0 } return true end,
  MIDI_SetCCShape = function(_, i, shape) evs[i + 1].shape = shape return true end,
  UpdateItemInProject = function() end, UpdateArrange = function() end,
  Undo_BeginBlock = function() undo[#undo + 1] = "begin" end, Undo_EndBlock = function(n) undo[#undo + 1] = n end,
}, { __index = function() return function() end end })

local Cat = require("ReaCat")
local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1 else failed = failed + 1 print("FAIL: " .. name .. (detail and (" -- " .. tostring(detail)) or "")) end
end
local function near(a, b, tol) return math.abs(a - b) < (tol or 1e-6) end
local function ofLane(cm, ch, m2) local o = {} for _, e in ipairs(evs) do if e.chanmsg == cm and e.chan == ch and (m2 == nil or e.msg2 == m2) then o[#o + 1] = e end end return o end

local id = Cat.send{ source = "Test", name = "ramp", points = { { 0, 0, 0 }, { 0.5, 1, 1 }, { 1, 0.5, 0 } } }   -- line, step, end
-- some events that are there already: CC 1 channel 3 inside the item (to be replaced), CC 7 (to stay), CC 1 on another channel (to stay)
evs = { { ppq = 1000, chanmsg = 176, chan = 2, msg2 = 1, msg3 = 99, shape = 0 }, { ppq = 2000, chanmsg = 176, chan = 2, msg2 = 7, msg3 = 50, shape = 0 }, { ppq = 3000, chanmsg = 176, chan = 5, msg2 = 1, msg3 = 11, shape = 0 } }

-- no time selection: over the whole item (4 .. 12 s)
local n, msg = Cat.sendToMidiCC(id)
local cc1 = ofLane(176, 2, 1)
check("three events written", n == 3 and #cc1 == 3, msg)
check("the old CC 1 event of that channel is replaced", #cc1 == 3 and cc1[1].msg3 ~= 99)
check("CC 7 and the other channel are left alone", #ofLane(176, 2, 7) == 1 and #ofLane(176, 5, 1) == 1)
check("times over the whole item (0, 4 s, 8 s in ticks)", cc1[1].ppq == 0 and cc1[2].ppq == 4000 and cc1[3].ppq >= 7999 and cc1[3].ppq <= 8000, cc1[3] and cc1[3].ppq)
check("values 0..127: 0, 127, 64", cc1[1].msg3 == 0 and cc1[2].msg3 == 127 and cc1[3].msg3 == 64, cc1[1].msg3 .. "," .. cc1[2].msg3 .. "," .. cc1[3].msg3)
check("shapes: line = linear (1), step = square (0)", cc1[1].shape == 1 and cc1[2].shape == 0 and cc1[3].shape == 1, cc1[1].shape .. "," .. cc1[2].shape)
check("the channel is the editor's (3)", msg:find("channel 3") ~= nil, msg)
local e = Cat.get(id)
check("the item is a place where the curve is used (red border)", Cat.usedHashes()[e.hash] == 1, tostring(Cat.usedHashes()[e.hash]))
local by = Cat.usedBy(e.hash)
check("the place is the item", by[1] and by[1].what == "item" and by[1].guid == "{ITEM-GUID-1}")
check("one undo step with a name", undo[#undo] == "ReaCat: curve to MIDI CC")

-- a time selection 6..10 s: the curve goes over it, the events outside it stay
evs = { { ppq = 500, chanmsg = 176, chan = 2, msg2 = 1, msg3 = 33, shape = 0 }, { ppq = 3000, chanmsg = 176, chan = 2, msg2 = 1, msg3 = 44, shape = 0 }, { ppq = 7000, chanmsg = 176, chan = 2, msg2 = 1, msg3 = 55, shape = 0 } }
ts = { 6, 10 }
n = Cat.sendToMidiCC(id)
cc1 = ofLane(176, 2, 1)
check("the events outside the time selection stay (ppq 500 and 7000), the one inside (3000) is replaced", #cc1 == 5 and cc1[1].ppq == 500 and cc1[5].ppq == 7000 and cc1[1].msg3 == 33 and cc1[5].msg3 == 55, #cc1)
check("the curve starts at 6 s (2000 ticks)", cc1[2].ppq == 2000 and cc1[3].ppq == 4000, cc1[2].ppq .. " " .. cc1[3].ppq)

-- a selection that reaches past the item is cut at the end of the item
evs = {}
ts = { 10, 20 }
n = Cat.sendToMidiCC(id)
check("a selection that reaches past the item is cut off at its end", n == 3 and evs[3].ppq <= 8000, evs[3] and evs[3].ppq)
ts = { 30, 40 }
local n2, m2 = Cat.sendToMidiCC(id)
check("a selection outside the item: says so", n2 == 0 and m2:find("outside the item") ~= nil, m2)
ts = { 0, 0 }

-- pitch bend (14 bits) and channel pressure
evs = {}
lane = 0x201
n = Cat.sendToMidiCC(id)
local pb = ofLane(224, 2)
check("pitch bend: three events, 14 bits (0, 16383, 8192)", n == 3 and #pb == 3 and pb[1].msg2 == 0 and pb[1].msg3 == 0 and pb[2].msg2 == 127 and pb[2].msg3 == 127 and pb[3].msg3 == 64 and pb[3].msg2 == 0, #pb)
evs = {}
lane = 0x203
n = Cat.sendToMidiCC(id)
local cp = ofLane(208, 2)
check("channel pressure: 7 bits", n == 3 and #cp == 3 and cp[2].msg2 == 127 and cp[3].msg2 == 64, #cp)
lane = 0x200
local n3, m3 = Cat.sendToMidiCC(id)
check("a lane that is not supported: says so", n3 == 0 and m3:find("not supported") ~= nil, m3)
lane = 1

-- Resolution applies
local big = {}
for i = 0, 100 do local t = i / 100 big[#big + 1] = { t, t * t * (3 - 2 * t) } end
local bid = Cat.send{ source = "Test", name = "big", points = big }
evs = {}
Cat.setResolution(12)
n = Cat.sendToMidiCC(bid)
check("Resolution 12: twelve events", n == 12 and #ofLane(176, 2, 1) == 12, n)
Cat.setResolution(0)
evs = {}
n = Cat.sendToMidiCC(bid)
check("no limit: all 101 points", n == 101, n)

-- a cubic segment that swings past the range stays inside 0..127
local oid = Cat.send{ source = "Test", name = "overshoot", points = { { 0, 0.5, 5, 1.4, -0.4 }, { 1, 0.5, 0 } } }
evs = {}
n = Cat.sendToMidiCC(oid)
local lo, hi = 999, -1
for _, ev in ipairs(evs) do lo, hi = math.min(lo, ev.msg3), math.max(hi, ev.msg3) end
check("a cubic that swings past 0..1 stays inside 0..127", n == 13 and lo >= 0 and hi <= 127, lo .. ".." .. hi)

-- no editor, a rule
editorOpen = false
local n4, m4 = Cat.sendToMidiCC(id)
check("no MIDI editor open: says so", n4 == 0 and m4:find("MIDI editor") ~= nil, m4)
editorOpen = true
local rid = Cat.send{ kind = "rule", source = "Test", name = "rule", text = "x" }
local n5, m5 = Cat.sendToMidiCC(rid)
check("a rule is not written", n5 == 0 and m5:find("not a curve") ~= nil, m5)

os.execute("rm -rf '" .. root .. "'")
print(string.format("%d checks passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
