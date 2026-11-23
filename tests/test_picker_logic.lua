-- Offline test of the logic in lib/ReaCatPicker.lua (filters, sort, clicks, selection, delete / undo). The drawing is tested in REAPER
-- (tests/window_smoke.lua). Run from the repo root:  lua5.4 tests/test_picker_logic.lua   (TMPDIR chooses the scratch folder)

package.path = "lib/?.lua;" .. package.path
local root = (os.getenv("TMPDIR") or "/tmp") .. "/reacat_pl_" .. os.time() .. "_" .. math.random(100000)
os.execute("mkdir -p '" .. root .. "'")
local ext = {}
reaper = {
  GetResourcePath = function() return root end,
  RecursiveCreateDirectory = function(p) os.execute("mkdir -p '" .. p .. "'") return 1 end,
  EnumerateFiles = function(dir, i)
    if i < 0 then return nil end
    local p = io.popen("find '" .. dir .. "' -maxdepth 1 -type f 2>/dev/null | sort")
    local k = 0
    for path in p:lines() do if k == i then p:close() return (path:match("([^/]+)$")) end k = k + 1 end
    p:close()
    return nil
  end,
  GetExtState = function(s, k) return ext[s .. "/" .. k] or "" end,
  SetExtState = function(s, k, v) ext[s .. "/" .. k] = v end,
  time_precise = function() return os.clock() end,
}
local Cat = require("ReaCat")
local P = require("ReaCatPicker")

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1 else failed = failed + 1 print("FAIL: " .. name .. (detail and (" -- " .. tostring(detail)) or "")) end
end

local line = { { 0, 0 }, { 1, 1 } }
local a = Cat.send{ source = "Zeta", name = "one", points = line, tags = "lfo" }
local b = Cat.send{ source = "Alpha", name = "two", points = { { 0, 0, 1 }, { 0.5, 1, 1 }, { 1, 0 } }, tags = "gate,lfo" }
local c = Cat.send{ source = "Mid", name = "three", points = { { 0, 0, 2 }, { 1, 1 } } }
local r = Cat.send{ kind = "rule", source = "Markov", name = "State", rulekind = "value", text = "mv,a{0}" }
local r2 = Cat.send{ kind = "rule", source = "Sieve", name = "Pulse", rulekind = "rhythm", text = "ps,3@0" }

local st = P.new()
local function names(s) local o = {} for i, e in ipairs(s.list) do o[i] = e.name end return table.concat(o, ",") end

P._refresh(st, {})
check("all five listed, newest first", #st.list == 5 and st.total == 5 and st.list[1].id == r2, names(st))
check("tags counted over the whole catalogue", (function() for _, t in ipairs(st.tags) do if t.tag == "lfo" and t.count == 2 then return true end end end)())
check("the project name is a flagged chip", (function() for _, t in ipairs(st.tags) do if t.tag == "Unsaved Project" and t.project and t.count == 5 then return true end end end)())
st.query, st.dirty = 'tag:"unsaved project"', true
P._refresh(st, {})
check("clicking the project chip filters on it", #st.list == 5)
st.query, st.dirty = "", true
P._refresh(st, { kind = "rule" })
check("opts.kind filters", #st.list == 2 and st.total == 5)
P._refresh(st, { kind = "rule", rulekind = "rhythm" })
check("opts.rulekind filters", #st.list == 1 and st.list[1].id == r2)
P._refresh(st, { kind = "curve" })
check("curves only", #st.list == 3)
P._refresh(st, {})
check("no change, no new work: dirty is off", st.dirty == false)

st.query, st.dirty = "tag:lfo", true
P._refresh(st, {})
check("query filters", #st.list == 2)
st.query, st.dirty = "tag:lfo NOT tag:gate", true
P._refresh(st, {})
check("boolean query", #st.list == 1 and st.list[1].id == a)
st.query, st.dirty = "(lfo", true
P._refresh(st, {})
check("a bad query shows the problem and does not filter", st.qerr ~= nil and #st.list == 5)
st.query, st.dirty = "", true
P._refresh(st, {})
check("the problem goes away", st.qerr == nil)

st.dateMode, st.dirty = 1, true            -- today
P._refresh(st, {})
check("date: today finds all of today's", #st.list == 5)
st.dateMode, st.from, st.to, st.dirty = 4, "2999-01-01", "", true
P._refresh(st, {})
check("date: a range in the future finds nothing", #st.list == 0)
st.from, st.to, st.dirty = "garbage", "", true
P._refresh(st, {})
check("date: an invalid range date is ignored", #st.list == 5)
st.dateMode, st.dirty = 0, true

st.sort, st.dirty = 1, true
P._refresh(st, {})
check("sort: oldest first", st.list[1].id == a and st.list[#st.list].id == r2)
st.sort, st.dirty = 2, true
P._refresh(st, {})
check("sort: by source", st.list[1].source == "Alpha" and st.list[#st.list].source == "Zeta", st.list[1].source)
st.sort, st.dirty = 0, true
P._refresh(st, {})

-- a change in the catalogue (the edit counter / the stamp) refreshes without being asked
Cat.update(a, { addtags = { "later" } })
P._refresh(st, {})
check("an edit refreshes the list", (function() for _, e in ipairs(st.list) do if e.id == a then for _, t in ipairs(e.tags) do if t == "later" then return true end end end end end)())
local d = Cat.send{ source = "New", name = "x", points = line }
P._refresh(st, {})
check("a send refreshes the list", st.list[1].id == d and #st.list == 6)

-- clicks
local function entry(id) for _, e in ipairs(st.list) do if e.id == id then return e end end end
local ea, eb, ec = entry(a), entry(b), entry(c)
check("picker click takes", (P._click(st, {}, ea, false, false) or {}).id == a)
check("picker click: Original range only when the entry has one", P._click(st, {}, ea, false, false).originalRange == false)
st.useRange = true
Cat.send{ source = "Ranged", name = "r", points = line, range = { 0, 100 } }
P._refresh(st, {})
local er
for _, e in ipairs(st.list) do if e.name == "r" then er = e end end
check("picker click: Original range when wanted and available", P._click(st, {}, er, false, false).originalRange == true and P._click(st, {}, ea, false, false).originalRange == false)
check("picker Shift+click only looks", P._click(st, {}, eb, false, true) == nil and st.focus == b)
local br = { browser = true }
check("browser click looks, takes nothing", P._click(st, br, ea, false, false) == nil and st.focus == a and not next(st.sel))
P._click(st, br, eb, true, false)
check("Ctrl+click: the one looked at joins, the new one too", st.sel[a] and st.sel[b] and st.focus == b)
P._click(st, br, ec, true, false)
check("Ctrl+click adds a third", st.sel[c] and #P._selectedIds(st) == 3)
P._click(st, br, ec, true, false)
check("Ctrl+click again takes it out", not st.sel[c] and #P._selectedIds(st) == 2)
check("tag edits go to all selected when the focus is one of them", #P._tagTargets(st) == 2)
P._click(st, br, ec, false, false)
check("a plain click clears the selection", not next(st.sel) and #P._tagTargets(st) == 1 and P._tagTargets(st)[1] == c)

-- send again
local before = Cat.list()[1].id
P._sendAgain(st, ea)
check("double-click: sent again, now the newest", Cat.list()[1].id == a and Cat.last() == a and before ~= a)
check("a message is shown", st.msg and st.msg:find("sent again") ~= nil)

-- delete and undo
P._refresh(st, {})
local n0 = #Cat.list()
P._click(st, br, ea, false, false)
local done = P._delete(st, ea)
check("right-click deletes one", #done == 1 and #Cat.list() == n0 - 1 and st.focus == nil)
P._click(st, br, eb, false, false)
P._click(st, br, ec, true, false)
local done2 = P._delete(st, ec)
check("right-click on a selected entry deletes the whole selection", #done2 == 2 and #Cat.list() == n0 - 3 and not next(st.sel))
check("the deletions are kept for Undo delete", #st.deleted == 2)
for _, id in ipairs(table.remove(st.deleted)) do Cat.undelete(id) end
check("Undo delete brings back the last deletion", #Cat.list() == n0 - 1)

os.execute("rm -rf '" .. root .. "'")
print(string.format("%d checks passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
