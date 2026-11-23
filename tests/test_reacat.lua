-- Offline test of lib/ReaCat.lua with a stand-in `reaper`. Run from the repo root:  lua5.4 tests/test_reacat.lua
-- (set TMPDIR to choose where the scratch catalogue is made)

package.path = "lib/?.lua;" .. package.path

local root = (os.getenv("TMPDIR") or "/tmp") .. "/reacat_test_" .. os.time() .. "_" .. math.random(100000)
local cat = root .. "/Data/ReaCat"
os.execute("mkdir -p '" .. root .. "'")

local ext = {}
local persisted = {}
reaper = {
  GetResourcePath = function() return root end,
  RecursiveCreateDirectory = function(p) os.execute("mkdir -p '" .. p .. "'") return 1 end,
  EnumerateFiles = function(dir, i)
    if i < 0 then return nil end
    local p = io.popen("find '" .. dir .. "' -maxdepth 1 -type f 2>/dev/null | sort")
    local k = 0
    for path in p:lines() do
      if k == i then p:close() return (path:match("([^/]+)$")) end
      k = k + 1
    end
    p:close()
    return nil
  end,
  GetExtState = function(s, k) return ext[s .. "/" .. k] or "" end,
  SetExtState = function(s, k, v, persist) ext[s .. "/" .. k] = v if persist then persisted[s .. "/" .. k] = true end end,
}

local projectName = ""
reaper.GetProjectName = function() return projectName end
local Cat = require("ReaCat")

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1 else failed = failed + 1 print("FAIL: " .. name .. (detail and (" -- " .. tostring(detail)) or "")) end
end
local function same(a, b) return math.abs(a - b) < 1e-6 end

local function readAll(path) local f = io.open(path, "rb") local s = f:read("a") f:close() return s end
local function ids(list) local o = {} for i, e in ipairs(list) do o[i] = e.id end return o end

local saw = {
  { 0, 0.5, 2 }, { 0.25, 0.8 }, { 0.5, 0.1, 5, 0.4, 0.6 }, { 1, 0.5 },
}

-- ------------------------------------------------ send and read back
local id1, err = Cat.send{ source = "ReaNvelopes", name = "RAND", points = saw, beats = 16, range = { -20, 20 }, unit = "x", tags = "bridge, idea", note = "first idea\nsecond line" }
check("send returns an id", id1 and id1:match("^%d%d%d%d%d%d%d%d_%d%d%d%d%d%d_%d%d%d$"), err or id1)
check("file exists with the extension", io.open(cat .. "/" .. id1 .. ".reacat", "rb") ~= nil)
local text = readAll(cat .. "/" .. id1 .. ".reacat")
check("first line", text:match("^ReaCat 1\n") ~= nil)
check("points marker and last line", text:find("\npoints\n", 1, true) and text:find("1.000000,0.500000\n", 1, true))
check("cubic point line", text:find("0.500000,0.100000,5,0.400000,0.600000", 1, true) ~= nil)
check("no temp file left", io.open(cat .. "/" .. id1 .. ".reacat.tmp", "rb") == nil)

local e = Cat.get(id1)
check("get: source/name", e and e.source == "ReaNvelopes" and e.name == "RAND")
check("get: 4 points", e and #e.points == 4)
check("get: shape and handles", e and e.points[1].shape == 2 and e.points[3].shape == 5 and same(e.points[3].c1, 0.4) and same(e.points[3].c2, 0.6))
check("get: beats / range / unit", e and e.beats == 16 and e.range[1] == -20 and e.range[2] == 20 and e.unit == "x")
check("get: note with a line end survives", e and e.note == "first idea\nsecond line", e and e.note)
local tagset = {}
for _, t in ipairs(e.tags) do tagset[t:lower()] = true end
check("auto tags: source, name, shape word", tagset.reanvelopes and tagset.rand and tagset.smooth)
check("own tags added", tagset.bridge and tagset.idea)
check("stamp went up", Cat.stamp() == "1", Cat.stamp())
check("last = id", Cat.last() == id1)

-- ------------------------------------------------ validation
check("no source refused", select(1, Cat.send{ name = "x", points = saw }) == nil)
check("one point refused", select(1, Cat.send{ source = "a", name = "b", points = { { 0, 0 } } }) == nil)
check("first t must be 0", select(1, Cat.send{ source = "a", name = "b", points = { { 0.1, 0 }, { 1, 1 } } }) == nil)
check("last t must be 1", select(1, Cat.send{ source = "a", name = "b", points = { { 0, 0 }, { 0.9, 1 } } }) == nil)
check("t must ascend", select(1, Cat.send{ source = "a", name = "b", points = { { 0, 0 }, { 0.6, 1 }, { 0.5, 1 }, { 1, 1 } } }) == nil)
check("v outside 0..1 refused", select(1, Cat.send{ source = "a", name = "b", points = { { 0, 0 }, { 1, 1.5 } } }) == nil)
check("shape 5 needs handles", select(1, Cat.send{ source = "a", name = "b", points = { { 0, 0, 5 }, { 1, 1 } } }) == nil)
check("unknown kind refused", select(1, Cat.send{ kind = "poem", source = "a", name = "b" }) == nil)
local many = {}
for i = 0, Cat.MAX_POINTS do many[#many + 1] = { i / Cat.MAX_POINTS, 0.5 } end
check("too many points refused", select(1, Cat.send{ source = "a", name = "b", points = many }) == nil)
check("a refused send does not bump the stamp", Cat.stamp() == "1")

-- ------------------------------------------------ the same thing again
local before = Cat.get(id1)
local id1b = Cat.send{ source = "ReaNvelopes", name = "RAND", points = saw }
check("same content: same id, no new file", id1b == id1 and #Cat.list() == 1, id1b)
check("same content: stamp went up", Cat.stamp() == "2")
local after = Cat.get(id1)
check("same content: saved kept, tags and note kept", after.saved == before.saved and after.note == before.note and #after.tags == #before.tags)

-- ------------------------------------------------ several in one second, ordering, newest
local idStep = Cat.send{ source = "Sieve", name = "Gate", points = { { 0, 0, 1 }, { 0.5, 1, 1 }, { 1, 0 } } }
local idB = Cat.send{ source = "ReaNvelopes", name = "RAND", points = { { 0, 0 }, { 1, 1 } } }
check("three entries", #Cat.list() == 3)
check("ids differ within a second", idStep ~= idB and idStep ~= id1 and idB ~= id1)
local step = Cat.get(idStep)
local hasStep = false
for _, t in ipairs(step.tags) do if t == "step" then hasStep = true end end
check("step tag", hasStep)
check("newest(source,name) is the latest send of it", Cat.newest("ReaNvelopes", "RAND") == idB)
Cat.send{ source = "ReaNvelopes", name = "RAND", points = saw }       -- the first one again: it becomes the newest
check("sending identical content again makes it the newest", Cat.newest("ReaNvelopes", "RAND") == id1)
check("newest of nothing", Cat.newest("nobody", "x") == nil)
check("list is newest first", Cat.list()[1].sent >= Cat.list()[3].sent)

-- ------------------------------------------------ rules
local idR = Cat.send{ kind = "rule", source = "Markov", name = "State", rulekind = "value", text = "mv,a{0}b{1}:{a=1|b=1}a:{a=1|b=1},(c,0)\nsecond line" }
check("rule sent", idR ~= nil)
local r = Cat.get(idR)
check("rule read back, two lines", r and r.kind == "rule" and r.text == "mv,a{0}b{1}:{a=1|b=1}a:{a=1|b=1},(c,0)\nsecond line" and r.rulekind == "value")
check("rule has the rule tag", (function() for _, t in ipairs(r.tags) do if t == "rule" then return true end end end)())
check("empty rule refused", select(1, Cat.send{ kind = "rule", source = "a", name = "b", text = "  " }) == nil)
check("filter by kind", #Cat.list{ kind = "rule" } == 1 and #Cat.list{ kind = "curve" } == 3)

-- ------------------------------------------------ update: tags, note, fav
local editBefore = Cat.editStamp()
check("update ok", Cat.update(id1, { addtags = { "Later", "bridge", "x,y" } }))
local u = Cat.get(id1)
local lows = {}
for _, t in ipairs(u.tags) do lows[t:lower()] = (lows[t:lower()] or 0) + 1 end
check("added tag later, deduplicated without case", lows.later == 1 and lows.bridge == 1, table.concat(u.tags, "|"))
check("comma in a tag becomes a space", lows["x y"] == 1)
check("edit counter went up, send stamp did not", Cat.editStamp() ~= editBefore and Cat.stamp() == tostring(tonumber(Cat.stamp())))
Cat.update(id1, { removetags = { "BRIDGE", "smooth" } })
u = Cat.get(id1)
lows = {}
for _, t in ipairs(u.tags) do lows[t:lower()] = true end
check("removed tags without case, also an automatic one", not lows.bridge and not lows.smooth and lows.later)
Cat.update(id1, { note = "", fav = true })
u = Cat.get(id1)
check("note cleared, fav set", (u.note == nil or u.note == "") and u.fav == true)
check("edit keeps saved, sent, points, hash", u.saved == after.saved and #u.points == 4 and u.hash == after.hash and u.sent == after.sent or u.sent ~= nil)
Cat.update(id1, { tags = { "only" } })
u = Cat.get(id1)
check("tags replaced", #u.tags == 1 and u.tags[1] == "only")
check("update of nothing", select(1, Cat.update("nope", {})) == nil)

-- unknown header keys survive a rewrite
local path = cat .. "/" .. id1 .. ".reacat"
local f = io.open(path, "wb")
f:write("ReaCat 1\nkind=curve\nsource=Future\nname=z\nsaved=2026-01-01 00:00:00\nsent=2026-01-01 00:00:00\nfuturekey=keep me\nhash=00000000\npoints\n0.000000,0.000000\n1.000000,1.000000\n")
f:close()
Cat.update(id1, { addtags = { "t" } })
check("unknown key kept on rewrite", readAll(path):find("futurekey=keep me", 1, true) ~= nil)
check("old saved date is kept", Cat.get(id1).saved == "2026-01-01 00:00:00")

-- a file of another major version, and a broken file, are skipped in a list and refused by get
local g = io.open(cat .. "/20000101_000000_001.reacat", "wb") g:write("ReaCat 2\nkind=curve\n") g:close()
local g2 = io.open(cat .. "/20000101_000000_002.reacat", "wb") g2:write("hello\n") g2:close()
local n = #Cat.list()
check("foreign files are not listed", n == 4, n)
check("get of a newer major refuses with a message", select(2, Cat.get("20000101_000000_001")) ~= nil and select(1, Cat.get("20000101_000000_001")) == nil)
check("the foreign files are left alone", io.open(cat .. "/20000101_000000_002.reacat", "rb") ~= nil)

-- ------------------------------------------------ delete, undelete
local cnt = #Cat.list()
check("delete ok", Cat.delete(idStep))
check("deleted entry is gone from the list and in _trash", #Cat.list() == cnt - 1 and io.open(cat .. "/_trash/" .. idStep .. ".reacat", "rb") ~= nil)
check("undelete ok", Cat.undelete(idStep) and #Cat.list() == cnt)
check("delete of nothing", select(1, Cat.delete("nope")) == nil)

-- ------------------------------------------------ tags()
local tg = Cat.tags()
check("tags() has counts", #tg > 0 and tg[1].count >= tg[#tg].count)

-- ------------------------------------------------ date filter
check("filter from the future finds nothing", #Cat.list{ from = "2999-01-01" } == 0)
check("filter to the past finds nothing of today", #Cat.list{ to = "2000-01-01" } == 0)
check("filter from today finds the new ones", #Cat.list{ from = os.date("%Y-%m-%d") } >= 3)

-- ------------------------------------------------ cleanup
check("default cleanup limit is 2000", Cat.cleanupLimit() == 2000)
Cat.setCleanupLimit(2)
check("cleanup limit is changeable and persistent", Cat.cleanupLimit() == 2 and persisted["ReaCat/cleanup_after"] == true)
local cand, total = Cat.cleanupCandidates()
check("cleanup candidates: the count over the limit", #cand == total - 2, #cand .. " of " .. total)
Cat.update(Cat.list()[#Cat.list()].id, { fav = true })
local cand2 = Cat.cleanupCandidates()
local anyFav = false
for _, c in ipairs(cand2) do if c.fav then anyFav = true end end
check("cleanup never proposes a fav", not anyFav)
Cat.setCleanupLimit(0)
check("limit 0 = never suggest", #Cat.cleanupCandidates() == 0)
Cat.setCleanupLimit(2000)

-- ------------------------------------------------ boolean search
local function H(name, source, tagsStr, note)
  local t = {}
  for w in (tagsStr or ""):gmatch("[^,]+") do t[#t + 1] = w end
  return { name = name, source = source, tags = t, note = note or "" }
end
local lorenz = H("x", "Strange Attractor", "Lorenz,smooth,bridge", "first idea")
local rossler = H("y", "Strange Attractor", "Rossler,smooth", "")
local sieve = H("Gate", "Xenakis Sieve", "step,sieve", "for the bridge")

local function q(text, h) local m, err = Cat.query(text) if not m then return nil, err end return m(h) end
check("empty search matches all", q("", lorenz) == true and q("   ", sieve) == true)
check("word matches tag", q("lorenz", lorenz) == true and q("lorenz", rossler) == false)
check("word is a part of a word, case ignored", q("LOREN", lorenz) == true)
check("word matches source", q("attractor", rossler) == true)
check("word matches note", q("idea", lorenz) == true)
check("space is AND", q("smooth lorenz", lorenz) == true and q("smooth lorenz", rossler) == false)
check("AND", q("smooth AND lorenz", lorenz) == true and q("smooth AND lorenz", rossler) == false)
check("OR", q("lorenz OR rossler", rossler) == true and q("lorenz OR rossler", sieve) == false)
check("NOT", q("NOT step", lorenz) == true and q("NOT step", sieve) == false)
check("minus is NOT", q("smooth -lorenz", rossler) == true and q("smooth -lorenz", lorenz) == false)
check("smooth NOT lorenz (NOT after a space)", q("smooth NOT lorenz", rossler) == true and q("smooth NOT lorenz", lorenz) == false)
check("brackets", q("(lorenz OR rossler) AND smooth", rossler) == true and q("(lorenz OR rossler) AND smooth", sieve) == false)
check("precedence: AND before OR", q("step OR lorenz smooth", lorenz) == true and q("step OR lorenz smooth", rossler) == false and q("step OR lorenz smooth", sieve) == true)
check("NOT binds first", q("NOT lorenz AND smooth", rossler) == true and q("NOT lorenz AND smooth", lorenz) == false)
check("phrase", q('"first idea"', lorenz) == true and q('"idea first"', lorenz) == false)
check("tag: is the whole tag", q("tag:smooth", lorenz) == true and q("tag:smoo", lorenz) == false)
check("tag: with a phrase", q('tag:"my tag"', H("n", "s", "my tag")) == true and q('tag:"my tag"', lorenz) == false)
check("source: is a part of the source", q("source:attractor", lorenz) == true and q("source:attractor", sieve) == false)
check("name:", q("name:gate", sieve) == true and q("name:gate", lorenz) == false)
check("note:", q("note:bridge", sieve) == true and q("note:bridge", rossler) == false)
check("a word search does not need to be in the tag field", q("bridge", sieve) == true)
check("and / or / not in lower case are words", q("and", H("band", "s", "")) == true and q("or", H("band", "s", "")) == false)

local function bad(text) local m, err = Cat.query(text) return m == nil and type(err) == "string" end
check("open bracket", bad("(lorenz"))
check("closing bracket alone", bad("lorenz)"))
check("open quote", bad('"first'))
check("open quote after a field", bad('tag:"abc'))
check("field without a value", bad("tag: "))
check("dangling AND", bad("lorenz AND"))
check("dangling OR", bad("lorenz OR"))
check("dangling NOT", bad("lorenz NOT"))
check("OR first", bad("OR lorenz"))

-- the query works as a list filter
local hit = Cat.list{ query = Cat.query("tag:rule") }
check("list with a query", #hit == 1 and hit[1].id == idR)
local both = Cat.list{ query = Cat.query("reanvelopes OR sieve") }
check("list with OR", #both >= 2)

-- ------------------------------------------------ the project name: a fixed tag
check("unsaved project: 'Unsaved Project'", Cat.projectName() == "Unsaved Project")
local pU = Cat.send{ source = "Proj", name = "unsaved", points = { { 0, 0.2 }, { 1, 0.8 } } }
check("an unsaved project is named 'Unsaved Project'", Cat.get(pU).project == "Unsaved Project")
projectName = "My Song.RPP"
check("the project name loses .RPP", Cat.projectName() == "My Song")
projectName = "other.rpp"
check("also in lower case", Cat.projectName() == "other")
projectName = "My Song.RPP"
local pS = Cat.send{ source = "Proj", name = "saved", points = { { 0, 0.3 }, { 1, 0.7 } } }
check("a saved project gives its name", Cat.get(pS).project == "My Song")
check("the name is stored in the file", readAll(cat .. "/" .. pS .. ".reacat"):find("\nproject=My Song\n", 1, true) ~= nil)
check("the project is not among the normal tags", (function() for _, t in ipairs(Cat.get(pS).tags) do if t == "My Song" then return false end end return true end)())
check("tag: finds the project", Cat.query('tag:"my song"')(Cat.get(pS)) == true and Cat.query('tag:"my song"')(Cat.get(pU)) == false)
check("project: field", Cat.query("project:song")(Cat.get(pS)) == true and Cat.query("project:song")(Cat.get(pU)) == false)
check("a plain word finds the project", Cat.query("song")(Cat.get(pS)) == true)
check("tag: of a part of the project name does not match", Cat.query("tag:song")(Cat.get(pS)) == false)
local counted
for _, t in ipairs(Cat.tags()) do if t.tag == "My Song" then counted = t end end
check("tags() counts the project, flagged", counted and counted.count == 1 and counted.project == true)
Cat.update(pS, { tags = { "x" }, note = "n" })
check("an edit keeps the project", Cat.get(pS).project == "My Song")
check("tags can not remove the project", (function() Cat.update(pS, { removetags = { "My Song" } }) return Cat.get(pS).project == "My Song" end)())
projectName = "Another.RPP"
Cat.send{ source = "Proj", name = "saved", points = { { 0, 0.3 }, { 1, 0.7 } } }
check("sending the same thing again keeps the first project", Cat.get(pS).project == "My Song")
check("the project can be given by the sender", Cat.get(Cat.send{ source = "Proj", name = "given", points = { { 0, 0 }, { 1, 1 } }, project = "Chosen" }).project == "Chosen")

-- ------------------------------------------------ touch: a click in the window makes an entry the newest
local others = Cat.list{ query = Cat.query("tag:rule") }
local old1 = Cat.list()[#Cat.list()].id          -- the oldest entry
local stBefore = Cat.stamp()
check("touch ok", Cat.touch(old1) == old1)
check("touch makes it the newest", Cat.list()[1].id == old1 and Cat.last() == old1)
check("touch moves the stamp", Cat.stamp() ~= stBefore)
check("touch keeps the content", #Cat.get(old1).points >= 2)
check("touch of nothing", select(1, Cat.touch("nope")) == nil)

-- ------------------------------------------------ clean up the scratch folder and report
os.execute("rm -rf '" .. root .. "'")
print(string.format("%d checks passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
