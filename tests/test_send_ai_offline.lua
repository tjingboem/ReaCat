-- test_send_ai_offline.lua (26 Nov 2026): Cat.sendToAutomationItems with a stand-in `reaper` that holds fake automation items.
-- Run from the repo root:  lua5.4 tests/test_send_ai_offline.lua
-- It checks OUR logic (the mapping, the replacing, the Resolution, the usage record); how REAPER itself reads the times of an automation item's
-- points (relative to its start, with start offset and play rate) is the assumption that only a real REAPER can confirm.
package.path = "lib/?.lua;" .. package.path
local root = (os.getenv("TMPDIR") or "/tmp") .. "/reacat_sendai_" .. os.time() .. "_" .. math.random(100000)
os.execute("mkdir -p '" .. root .. "'")
local ext, proj = {}, {}
local relativeStore = false   -- true: the stand-in treats times as counted from the item start (the other possible truth)
local env = { guid = "{ENV-1}", name = "Cutoff", pmin = 100, pmax = 5100, mode = 0,
  ais = { { pos = 4, len = 8, rate = 1, off = 0, sel = true, pts = { { 0, 1, 0 } } },
          { pos = 20, len = 4, rate = 2, off = 1, sel = false, pts = {} } } }
local undo = {}
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
  MarkProjectDirty = function() end,
  GetProjectName = function() return "" end,
  genGuid = function() return "{TEST-PROJECT-ID}" end,
  GetMasterTrack = function() return "master" end,
  CountTracks = function() return 0 end,
  CountTrackEnvelopes = function(tr) return tr == "master" and 1 or 0 end,
  GetTrackEnvelope = function() return env end,
  GetEnvelopeName = function() return true, env.name end,
  GetSetEnvelopeInfo_String = function() return true, env.guid end,
  GetEnvelopeScalingMode = function() return env.mode end,
  GetEnvelopeInfo_Value = function(_, what) return what == "PARM_MIN" and env.pmin or env.pmax end,
  GetEnvelopeStateChunk = function() return true, "<PARMENV 1:cutoff 100 5100 100\\n>" end,
  CountAutomationItems = function() return #env.ais end,
  GetSetAutomationItemInfo = function(_, i, what)
    local a = env.ais[i + 1]
    if what == "D_UISEL" then return a.sel and 1 or 0 end
    if what == "D_LENGTH" then return a.len end
    if what == "D_POSITION" then return a.pos end
    if what == "D_PLAYRATE" then return a.rate end
    if what == "D_STARTOFFS" then return a.off end
    return 0
  end,
  DeleteEnvelopePointRangeEx = function(_, i, a, b) env.ais[i + 1].pts = {} return true end,
  InsertEnvelopePointEx = function(_, i, t, v, shape) local p = env.ais[i + 1].pts p[#p + 1] = { t, v, shape } return true end,
  Envelope_SortPointsEx = function(_, i) table.sort(env.ais[i + 1].pts, function(a, b) return a[1] < b[1] end) end,
  CountEnvelopePointsEx = function(_, i)
    local a, n = env.ais[i + 1], 0
    for _, p in ipairs(a.pts) do
      local lo, hi = a.pos, a.pos + a.len
      if relativeStore then lo, hi = a.off, a.off + a.len * a.rate end
      if p[1] >= lo - 1e-9 and p[1] <= hi + 1e-9 then n = n + 1 end
    end
    return n
  end,
  Undo_BeginBlock = function() undo[#undo + 1] = "begin" end,
  Undo_EndBlock = function(name) undo[#undo + 1] = name end,
  UpdateArrange = function() end,
}, { __index = function() return function() end end })

local Cat = require("ReaCat")
local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1 else failed = failed + 1 print("FAIL: " .. name .. (detail and (" -- " .. tostring(detail)) or "")) end
end
local function near(a, b, tol) return math.abs(a - b) < (tol or 1e-6) end

local id = Cat.send{ source = "Test", name = "ramp", points = { { 0, 0, 0 }, { 0.5, 1, 1 }, { 1, 0.5, 0 } } }
local n, msg = Cat.sendToAutomationItems(id)
local pts = env.ais[1].pts
check("one automation item written", n == 1, msg)
check("the old point is replaced by the three of the curve", #pts == 3, #pts)
check("times are PROJECT times over the item (position 4, 8 s long)", near(pts[1][1], 4) and near(pts[2][1], 8) and near(pts[3][1], 12, 1e-3), pts[2] and pts[2][1])
check("values scaled to the envelope's range 100..5100", near(pts[1][2], 100) and near(pts[2][2], 5100) and near(pts[3][2], 2600), pts[3] and pts[3][2])
check("the step shape is kept (REAPER 1 = square)", pts[2][3] == 1 and pts[1][3] == 0)
check("the item that was not selected is untouched", #env.ais[2].pts == 0)
local e = Cat.get(id)
check("the item is recorded as a place (red border)", Cat.usedHashes()[e.hash] == 1)
local by = Cat.usedBy(e.hash)
check("the place is ai:<envelope guid>:<index>", by[1] and by[1].what == "ai" and by[1].guid == "ai:{ENV-1}:0", by[1] and by[1].guid)
check("one undo step with a name", undo[#undo] == "ReaCat: curve to automation item")

-- the other possible truth (times counted from the item start): the first try does not count right, the second does
relativeStore = true
env.ais[1].sel, env.ais[2].sel = false, true
n = Cat.sendToAutomationItems(id)
pts = env.ais[2].pts
check("times counted from the item start: found by the second try (start offset 1, rate 2)", n == 1 and near(pts[1][1], 1) and near(pts[3][1], 9, 1e-3), pts[3] and pts[3][1])
relativeStore = false

-- Resolution applies
env.ais[2].sel, env.ais[1].sel = false, true
local big = {}
for i = 0, 100 do local t = i / 100 big[#big + 1] = { t, t * t * (3 - 2 * t) } end
local bid = Cat.send{ source = "Test", name = "big", points = big }
Cat.setResolution(12)
n = Cat.sendToAutomationItems(bid)
check("Resolution 12: twelve points written", n == 1 and #env.ais[1].pts == 12, #env.ais[1].pts)
Cat.setResolution(0)
n = Cat.sendToAutomationItems(bid)
check("no limit: all 101 points", n == 1 and #env.ais[1].pts == 101, #env.ais[1].pts)

-- a cubic segment becomes small pieces
local cid = Cat.send{ source = "Test", name = "cubic", points = { { 0, 0, 5, 0.2, 0.8 }, { 1, 1, 0 } } }
n = Cat.sendToAutomationItems(cid)
check("a cubic segment is written as 13 points", n == 1 and #env.ais[1].pts == 13, #env.ais[1].pts)
check("and ends where the curve ends", near(env.ais[1].pts[13][2], 5100))

-- handles that swing past the lane (c1 = 1.4, c2 = -0.4) stay inside the lane
local oid = Cat.send{ source = "Test", name = "overshoot", points = { { 0, 0.5, 5, 1.4, -0.4 }, { 1, 0.5, 0 } } }
n = Cat.sendToAutomationItems(oid)
local lowest, highest = math.huge, -math.huge
for _, p in ipairs(env.ais[1].pts) do lowest, highest = math.min(lowest, p[2]), math.max(highest, p[2]) end
check("a cubic that swings past 0..1 stays inside the envelope's range 100..5100", n == 1 and lowest >= 100 - 1e-9 and highest <= 5100 + 1e-9, lowest .. " .. " .. highest)

-- fader scaling (a volume envelope): the points are stored in fader units, the top of the lane (volenvrange=6: 4x, +12 dB) is 1000
env.mode = 1
reaper.ScaleToEnvelopeMode = function(mode, amp) return amp * 250 end      -- the stand-in: amplitude 4 = 1000 fader units
reaper.get_ini_file = function() return root .. "/reaper.ini" end
local fi = io.open(root .. "/reaper.ini", "w") fi:write("[REAPER]\nvolenvrange=6\n") fi:close()
n = Cat.sendToAutomationItems(id)
check("fader mode: the top of the curve is the top of the lane (1000 fader units)", n == 1 and near(env.ais[1].pts[2][2], 1000.0), env.ais[1].pts[2] and env.ais[1].pts[2][2])
check("fader mode: the bottom of the curve is the bottom of the lane", near(env.ais[1].pts[1][2], 0))
check("fader mode: the middle is linear in fader units", near(env.ais[1].pts[3][2], 500.0, 1e-6), env.ais[1].pts[3] and env.ais[1].pts[3][2])
env.mode = 0

-- nothing selected, and not a curve
env.ais[1].sel = false
local n0, m0 = Cat.sendToAutomationItems(id)
check("nothing selected: says so", n0 == 0 and m0:find("select an automation item") ~= nil, m0)
local rid = Cat.send{ kind = "rule", source = "Test", name = "rule", text = "x" }
env.ais[1].sel = true
local n1, m1 = Cat.sendToAutomationItems(rid)
check("a rule is not written", n1 == 0 and m1:find("not a curve") ~= nil, m1)

os.execute("rm -rf '" .. root .. "'")
print(string.format("%d checks passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
