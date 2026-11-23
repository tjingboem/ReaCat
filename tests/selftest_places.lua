-- selftest_places.lua (23 Nov 2026): finding a used place again with REAPER's own API: an item by its GUID and an automation item by its envelope GUID and index;
-- selecting them; noticing that they are gone; forgetting them. Inside a REAPER of its own. RT_REACAT = the ReaCat folder, RT_OUT = results folder.
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
  reaper.InsertTrackAtIndex(0, true)
  local tr = reaper.GetTrack(0, 0)
  reaper.SetOnlyTrackSelected(tr)
  reaper.Main_OnCommand(40406, 0)                                  -- the volume lane
  local vol = reaper.GetTrackEnvelopeByName(tr, "Volume")
  local item = reaper.CreateNewMIDIItemInProj(tr, 20, 24, false)
  local ai0 = reaper.InsertAutomationItem(vol, -1, 30, 4)
  local ai1 = reaper.InsertAutomationItem(vol, -1, 40, 4)
  report(ai0 == 0 and ai1 == 1, "two automation items on the volume lane")

  local id = Cat.send{ source = "Places", name = "p", points = { { 0, 0.2 }, { 1, 0.8 } } }
  local entry = Cat.get(id)
  local ok, guid = Cat.markItem(item, entry, { tool = "Test" })
  report(ok and guid:match("^{.+}$") ~= nil, "markItem gets the item's real GUID", guid)
  report(Cat.findItem(guid) == item, "findItem finds the item by its GUID")
  local gE = ""
  for _, v in ipairs({ reaper.GetSetEnvelopeInfo_String(vol, "GUID", "", false) }) do if type(v) == "string" then gE = v end end
  Cat.useAdd{ hash = entry.hash, what = "ai", guid = "ai:" .. gE .. ":1", tool = "Test", label = "p" }
  local used = Cat.usedBy(entry.hash)
  report(#used == 2, "two places are recorded", #used)
  for _, rec in ipairs(used) do report(Cat.placeExists(rec), "placeExists: " .. rec.what) end

  -- select the item
  reaper.SelectAllMediaItems(0, false)
  reaper.SetEditCurPos(0, false, false)
  local sel = Cat.selectPlace({ what = "item", guid = guid })
  report(sel and reaper.IsMediaItemSelected(item) and math.abs(reaper.GetCursorPosition() - 20) < 1e-6, "selectPlace selects the item and moves the edit cursor to its start", reaper.GetCursorPosition())
  -- select the automation item
  local sel2 = Cat.selectPlace({ what = "ai", guid = "ai:" .. gE .. ":1" })
  report(sel2 and reaper.GetSetAutomationItemInfo(vol, 1, "D_UISEL", 0, false) ~= 0 and math.abs(reaper.GetCursorPosition() - 40) < 1e-6, "selectPlace selects the automation item and moves the cursor to it", reaper.GetCursorPosition())
  report(Cat.placeExists({ what = "ai", guid = "ai:" .. gE .. ":2" }) == false, "an automation item that does not exist is not found")

  -- the item is deleted: its place is gone, and a forget removes only that line
  reaper.DeleteTrackMediaItem(tr, item)
  local gone, why = Cat.selectPlace({ what = "item", guid = guid })
  report(gone == false and why:find("gone", 1, true) ~= nil, "a deleted item: selectPlace says it is gone", why)
  report(Cat.usePrune(Cat.placeExists) == 1 and #Cat.usedBy(entry.hash) == 1 and Cat.usedBy(entry.hash)[1].what == "ai", "forgetting the places that are gone keeps the automation item")
end)
if not ok0 then report(false, "the test ran without a script error", err0) end
finish()
