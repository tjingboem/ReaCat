-- selftest_save.lua (23 Nov 2026): does the usage record (the red borders) and the project id survive saving and re-opening the project?
-- And does a take mark the project as changed (so REAPER asks to save)? Inside a REAPER of its own. RT_REACAT = the ReaCat folder, RT_OUT = results folder.
local REPO, out_dir = os.getenv("RT_REACAT"), os.getenv("RT_OUT")
package.path = REPO .. "/lib/?.lua;" .. package.path
local lines, pass, fail = {}, 0, 0
local function report(ok, name, detail)
  if ok then pass = pass + 1 else fail = fail + 1 end
  lines[#lines + 1] = string.format("%s  %s%s", ok and "PASS" or "FAIL", name, detail and ("  -- " .. tostring(detail)) or "")
end
local function finish()
  lines[#lines + 1] = ""
  lines[#lines + 1] = string.format("RESULT: %d passed, %d failed", pass, fail)
  lines[#lines + 1] = "DONE"
  local f = io.open(out_dir .. "/results.txt", "w"); f:write(table.concat(lines, "\n"), "\n"); f:close()
end
local ok0, err0 = pcall(function()
  local Cat = require("ReaCat")
  local id = Cat.send{ source = "Save Test", name = "s", points = { { 0, 0.1 }, { 1, 0.9 } } }
  local entry = Cat.get(id)
  local pid = Cat.projectId()
  local clean = reaper.IsProjectDirty(0) == 0
  Cat.useAdd{ hash = entry.hash, what = "param", guid = "saved-place", tool = "Test", label = "Save Test s" }
  report(true, "info: before the take the project was " .. (clean and "unchanged" or "already changed") .. "; after it IsProjectDirty = " .. tostring(reaper.IsProjectDirty(0)))
  local dirtyAfter = reaper.IsProjectDirty(0) ~= 0
  report(dirtyAfter, "a take marks the project as changed (REAPER will ask to save it)", "IsProjectDirty = " .. tostring(reaper.IsProjectDirty(0)))

  local path = out_dir .. "/savetest.rpp"
  reaper.Main_SaveProjectEx(0, path, 0)
  local f = io.open(path, "r")
  local text = f and f:read("a") or ""
  if f then f:close() end
  report(text:find("saved%-place") ~= nil and text:find(pid, 1, true) ~= nil, "the saved project file contains the usage record and the project id", #text .. " bytes")

  -- a new empty project has none of it
  reaper.Main_OnCommand(40859, 0)                       -- File: New project tab
  report(#Cat.usage() == 0, "another (new) project has no usage record")
  -- open the saved one again
  reaper.Main_openProject("noprompt:" .. path)
  local u = Cat.usage()
  report(#u == 1 and u[1].guid == "saved-place" and u[1].hash == entry.hash, "after opening the saved project the usage record is back", #u)
  report(reaper.IsProjectDirty(0) == 0, "the project just opened is clean", reaper.IsProjectDirty(0))
  Cat.useAdd{ hash = entry.hash, what = "param", guid = "second-place", tool = "Test", label = "second" }
  report(reaper.IsProjectDirty(0) ~= 0, "a take alone (nothing else changed) marks a clean project as changed", reaper.IsProjectDirty(0))
  Cat.usePrune(function(r) return r.guid ~= "second-place" end)
  report(Cat.projectId() == pid, "and so is the project id", tostring(Cat.projectId()))
  report(Cat.usedHashes()[entry.hash] == 1, "so the entry is marked red again")
end)
if not ok0 then report(false, "the test ran without a script error", err0) end
finish()
