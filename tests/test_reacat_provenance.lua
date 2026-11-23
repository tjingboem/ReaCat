-- Offline test of the project id, restore and usage parts of lib/ReaCat.lua (spec section 11). Run from the repo root:
--   lua5.4 tests/test_reacat_provenance.lua     (TMPDIR chooses the scratch folder)
package.path = "lib/?.lua;" .. package.path
local root = (os.getenv("TMPDIR") or "/tmp") .. "/reacat_prov_" .. os.time() .. "_" .. math.random(100000)
os.execute("mkdir -p '" .. root .. "'")
local ext, persisted, proj = {}, {}, {}
local guidN = 0
local items = {}
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
  SetExtState = function(s, k, v, persist) ext[s .. "/" .. k] = v if persist then persisted[s .. "/" .. k] = true end end,
  GetProjExtState = function(_, s, k) local v = proj[s .. "/" .. k] return v and 1 or 0, v or "" end,
  SetProjExtState = function(_, s, k, v) proj[s .. "/" .. k] = v return 1 end,
  genGuid = function() guidN = guidN + 1 return "{AAAA-" .. guidN .. "}" end,
  GetProjectName = function() return "Prov Test.RPP" end,
  GetSetMediaItemInfo_String = function(item, parm, val, set)
    local it = items[item]
    if parm == "GUID" then return true, it.guid end
    if parm == "P_NOTES" then if set then it.notes = val return true end return true, it.notes end
  end,
  GetActiveTake = function(item) return items[item].take end,
  GetSetMediaItemTakeInfo_String = function(take, parm, val, set)
    if parm == "P_NAME" then if set then take.name = val return true end return true, take.name end
  end,
}
local Cat = require("ReaCat")

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then passed = passed + 1 else failed = failed + 1 print("FAIL: " .. name .. (detail and (" -- " .. tostring(detail)) or "")) end
end
local function readAll(p) local f = io.open(p, "rb") if not f then return nil end local s = f:read("a") f:close() return s end
local line = { { 0, 0 }, { 1, 1 } }

-- ------------------------------------------------ the project id
local pid = Cat.projectId()
check("a project id is made", type(pid) == "string" and pid ~= "", pid)
check("it is kept in the project's ExtState", proj["ReaCat/projectid"] == pid)
check("and stays the same", Cat.projectId() == pid)
local a = Cat.send{ source = "Prov", name = "a", points = line }
check("a send carries it as projectid=", Cat.get(a).projectid == pid and readAll(root .. "/Data/ReaCat/" .. a .. ".reacat"):find("\nprojectid=" .. pid:gsub("%p", "%%%0") .. "\n") ~= nil)
check("projectid is not a tag", (function() for _, t in ipairs(Cat.get(a).tags) do if t == pid then return false end end return true end)())
check("the sender can give it", Cat.get(Cat.send{ source = "Prov", name = "given", points = line, projectid = "XYZ" }).projectid == "XYZ")
proj = {}                                              -- another project
local pid2 = Cat.projectId()
check("another project has another id", pid2 ~= pid)
local saved = reaper.GetProjExtState
reaper.GetProjExtState, reaper.SetProjExtState = nil, nil
local noProj = Cat.send{ source = "Prov", name = "noproj", points = line }
check("without a project API a send still works, without an id", noProj and Cat.get(noProj).projectid == nil)
check("usage without a project API is empty and refuses to add", #Cat.usage() == 0 and Cat.useAdd{ hash = "x" } == nil)
reaper.GetProjExtState = saved
reaper.SetProjExtState = function(_, s, k, v) proj[s .. "/" .. k] = v return 1 end

-- ------------------------------------------------ export and restore
local b = Cat.send{ source = "Prov", name = "b", points = { { 0, 0, 1 }, { 0.5, 1, 1 }, { 1, 0 } }, tags = "keep, me", note = "a note", projectid = pid }
Cat.update(b, { fav = true })
local ra = Cat.send{ kind = "rule", source = "Prov", name = "rule", rulekind = "value", text = "vs,3@0", projectid = pid }
local exported = Cat.exportProject(pid)
local ids = {}
for _, x in ipairs(exported) do ids[#ids + 1] = x.id end
check("exportProject: the entries of that project, oldest first", #exported == 3 and exported[1].id == a and exported[3].id == ra, table.concat(ids, ","))
check("exportProject: none for another id or none", #Cat.exportProject("nope") == 0 and #Cat.exportProject(nil) == 0)
check("export gives the file text", Cat.export(b) == readAll(root .. "/Data/ReaCat/" .. b .. ".reacat"))
local before = {}
for _, h in ipairs(Cat.list()) do before[h.id] = h end
local lastBefore, stampBefore = Cat.last(), Cat.stamp()

os.execute("rm -rf '" .. root .. "/Data/ReaCat'")        -- a new machine: no catalogue
check("the catalogue is empty", #Cat.list() == 0)
local rid, how = Cat.restore(exported[2].id, exported[2].text)
check("restore adds the entry with its own id", rid == b and how == "added", tostring(rid) .. " " .. tostring(how))
local rb = Cat.get(b)
check("with its dates, tags, note, favourite and project", rb.saved == before[b].saved and rb.sent == before[b].sent and rb.note == "a note" and rb.fav == true and rb.project == before[b].project and rb.projectid == pid)
check("its tags are back", (function() local have = {} for _, t in ipairs(rb.tags) do have[t] = true end return have.keep and have.me end)())
check("its points are back with their shapes", #rb.points == 3 and rb.points[1].shape == 1)
check("restore does not make it the newest or send anything", Cat.last() == lastBefore and Cat.stamp() == stampBefore)
check("the file is the text that was stored", Cat.export(b) == exported[2].text)
local rid2, how2 = Cat.restore("other_id", exported[2].text)
check("the same content again is not added twice", rid2 == b and how2 == "exists" and #Cat.list() == 1)
Cat.restore(exported[1].id, exported[1].text)
Cat.restore(exported[3].id, exported[3].text)
check("all three are back", #Cat.list() == 3)
check("a restored rule keeps its text and kind", Cat.get(ra).text == "vs,3@0" and Cat.get(ra).rulekind == "value")
-- an id that is taken by other content gets a new id
local other = Cat.send{ source = "Prov", name = "other", points = { { 0, 0.3 }, { 1, 0.9 } } }
local clash, how3 = Cat.restore(other, (exported[1].text:gsub("source=Prov", "source=Elsewhere")))
check("a taken id with other content: added under a new id", how3 == "added" and clash ~= other and Cat.get(other).name == "other", tostring(clash))
check("restore refuses broken text and a newer format", Cat.restore("x", "garbage") == nil and Cat.restore("x", "ReaCat 2\nkind=curve\n") == nil and Cat.restore("x", nil) == nil)
check("restore of a bad id is given a new one", (function() local id, how = Cat.restore("../evil", (exported[1].text:gsub("name=a", "name=evil"))) return how == "added" and id ~= "../evil" and id:match("^[%w_%-]+$") end)())

-- ------------------------------------------------ the usage record
proj["ReaCat/usage"] = nil
check("no usage at first", #Cat.usage() == 0 and next(Cat.usedHashes()) == nil)
local editBefore = Cat.editStamp()
check("useAdd ok", Cat.useAdd{ hash = "h1", what = "item", guid = "{G1}", tool = "MinervaCL", label = "Lorenz Attractor x" })
check("it bumps the edit counter (open windows refresh)", Cat.editStamp() ~= editBefore)
Cat.useAdd{ hash = "h1", what = "ai", guid = "tr_env_1", tool = "ReaNvelopes", label = "Lorenz Attractor x" }
Cat.useAdd{ hash = "h2", what = "param", guid = "p", tool = "MinervaCL", label = "has | and ; and % and\nnewline" }
local u = Cat.usage()
check("three lines", #u == 3)
check("fields come back", u[1].hash == "h1" and u[1].what == "item" and u[1].guid == "{G1}" and u[1].tool == "MinervaCL" and u[1].date:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"))
check("odd characters survive", u[3].label == "has | and ; and % and\nnewline", u[3].label)
check("the record has no raw separators inside a field", not proj["ReaCat/usage"]:find("\n", 1, true))
check("usedHashes counts the places", Cat.usedHashes().h1 == 2 and Cat.usedHashes().h2 == 1)
check("usedBy lists where one hash is used", #Cat.usedBy("h1") == 2 and #Cat.usedBy("zzz") == 0)
Cat.useAdd{ hash = "h1", what = "item", guid = "{G1}", tool = "MinervaCL", label = "renamed" }
check("the same place again is one line, renewed", #Cat.usage() == 3 and Cat.usedBy("h1")[2].label == "renamed")
check("useAdd refuses a missing hash", Cat.useAdd{} == nil and Cat.useAdd{ hash = "" } == nil)
check("prune removes the lines whose place is gone", Cat.usePrune(function(r) return r.guid ~= "{G1}" end) == 1 and #Cat.usage() == 2)
check("prune with nothing gone changes nothing", Cat.usePrune(function() return true end) == 0)
for i = 1, 2100 do Cat.useAdd{ hash = "bulk" .. i, what = "item", guid = "g" .. i, tool = "t" } end
check("the record is cut to the newest 2000 lines", #Cat.usage() == 2000 and Cat.usage()[2000].hash == "bulk2100")
proj["ReaCat/usage"] = nil

-- ------------------------------------------------ the notes line and the name suffix (pure)
local e = { source = "Lorenz Attractor", name = "x", hash = "hx" }
local n1 = Cat.noteWith("my own note", e, "2026-11-23 10:15", "Night Piece")
check("a notes line is added after the user's own text", n1 == "my own note\nReaCat: Lorenz Attractor x, taken 2026-11-23 10:15, project Night Piece", n1)
local n2 = Cat.noteWith(n1, e, "2026-11-24 09:00", "Night Piece")
check("a newer take of the same curve replaces its line, nothing else", n2 == "my own note\nReaCat: Lorenz Attractor x, taken 2026-11-24 09:00, project Night Piece", n2)
local n3 = Cat.noteWith(n2, { source = "Lorenz Attractor", name = "y" }, "2026-11-24 09:01", "Night Piece")
check("another curve gets its own line", select(2, n3:gsub("ReaCat:", "")) == 2 and n3:find("my own note", 1, true) == 1)
check("empty notes: just the line", Cat.noteWith("", e, "d", "p") == "ReaCat: Lorenz Attractor x, taken d, project p" and Cat.noteWith(nil, e, "d", "p") == "ReaCat: Lorenz Attractor x, taken d, project p")
check("a name gets the suffix once", Cat.nameWith("Item", e) == "Item + ReaCat: Lorenz Attractor x" and Cat.nameWith("Item + ReaCat: Lorenz Attractor x", e) == "Item + ReaCat: Lorenz Attractor x")

-- ------------------------------------------------ markItem
items["I1"] = { guid = "{ITEM-1}", notes = "", take = { name = "ReaMaskM 2026-11-22 + ReaShapeM" } }
check("the name suffix setting is off by default", Cat.nameSuffixOn() == false)
local ok, guid = Cat.markItem("I1", { source = "Lorenz Attractor", name = "x", hash = "hx" }, { tool = "MinervaCL" })
check("markItem ok, gives the item's GUID", ok == true and guid == "{ITEM-1}")
check("the usage line is there", #Cat.usedBy("hx") == 1 and Cat.usedBy("hx")[1].guid == "{ITEM-1}" and Cat.usedBy("hx")[1].what == "item" and Cat.usedBy("hx")[1].tool == "MinervaCL")
check("the item's notes have the line", items["I1"].notes:find("ReaCat: Lorenz Attractor x, taken ", 1, true) == 1 and items["I1"].notes:find("project Prov Test", 1, true) ~= nil, items["I1"].notes)
check("the name is untouched while the setting is off", items["I1"].take.name == "ReaMaskM 2026-11-22 + ReaShapeM")
Cat.markItem("I1", { source = "Lorenz Attractor", name = "x", hash = "hx" }, { tool = "MinervaCL" })
check("marking again changes nothing (one usage line, one notes line)", #Cat.usedBy("hx") == 1 and select(2, items["I1"].notes:gsub("ReaCat:", "")) == 1)
Cat.setNameSuffixOn(true)
check("the setting is kept (persistent)", Cat.nameSuffixOn() == true and persisted["ReaCat/name_suffix"] == true)
Cat.markItem("I1", { source = "Lorenz Attractor", name = "y", hash = "hy" }, { tool = "MinervaCL" })
check("with the setting on the name gets the suffix", items["I1"].take.name == "ReaMaskM 2026-11-22 + ReaShapeM + ReaCat: Lorenz Attractor y", items["I1"].take.name)
Cat.markItem("I1", { source = "Lorenz Attractor", name = "y", hash = "hy" }, { tool = "MinervaCL", nameSuffix = false })
check("opts.nameSuffix = false overrides the setting", items["I1"].take.name:find("Attractor y", 1, true) ~= nil and select(2, items["I1"].take.name:gsub("ReaCat:", "")) == 1)
check("both curves are in the notes", select(2, items["I1"].notes:gsub("ReaCat:", "")) == 2)
check("markItem refuses nothing", Cat.markItem(nil, { hash = "x" }) == nil and Cat.markItem("I1", {}) == nil)

-- ------------------------------------------------ used: in the search
Cat.setNameSuffixOn(false)
local ex = Cat.get(a)
Cat.useAdd{ hash = ex.hash, what = "item", guid = "{G9}", tool = "t" }
local qUsed, err = Cat.query("used:")
check("used: parses", qUsed ~= nil, err)
check("used: is true for an entry used in this project", qUsed(ex) == true and qUsed(Cat.get(b)) == false)
check("NOT used: is the others", Cat.query("NOT used:")(Cat.get(b)) == true and Cat.query("NOT used:")(ex) == false)
check("used: combines with other terms", Cat.query("used: prov")(ex) == true and Cat.query("used: elsewhere")(ex) == false)
local same = 0
for _, h in ipairs(Cat.list()) do if h.hash == ex.hash then same = same + 1 end end
check("used: in a list filter (identical content under other names counts too: the reference is the content)", #Cat.list{ query = Cat.query("used:") } == same and same >= 1, same)
proj["ReaCat/usage"] = nil
check("without usage nothing is used", #Cat.list{ query = Cat.query("used:") } == 0)

os.execute("rm -rf '" .. root .. "'")
print(string.format("%d checks passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
