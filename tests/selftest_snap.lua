-- selftest_snap.lua (23 Nov 2026): ReaCat as a ReaSnap member: the window title carries the instance number that ReaSnap's launcher left, and ReaSnap's
-- Close All closes the window (also one for another project does not). Inside a REAPER of its own (ReaImGui). RT_REACAT = the ReaCat folder, RT_OUT = results folder.
local REPO, out_dir = os.getenv("RT_REACAT"), os.getenv("RT_OUT")
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
reaper.get_action_context = function() return true, REPO .. "/ReaCat.lua", 0, 0, 0, 0, 0 end
local queue = {}
reaper.defer = function(f) queue[#queue + 1] = f end
local titles = {}
local realBegin = reaper.ImGui_Begin
reaper.ImGui_Begin = function(ctx, title, ...) titles[#titles + 1] = title return realBegin(ctx, title, ...) end
local function frames(n)
  for _ = 1, n do
    local q = queue; queue = {}
    for _, f in ipairs(q) do
      local ok, err = pcall(f)
      if not ok then report(false, "a frame ran without error", err); return false end
    end
  end
  return true
end
local ok0, err0 = pcall(function()
  -- what ReaSnap's launcher leaves just before it starts the script
  reaper.SetExtState("ReaSculpt_Registry", "pending_ReaCat_instance_number", "3", false)
  reaper.SetExtState("ReaSculpt_Registry", "pending_ReaCat_project_identity", "proj-A", false)
  local ok, err = pcall(dofile, REPO .. "/ReaCat.lua")
  report(ok, "ReaCat starts", err)
  report(reaper.GetExtState("ReaSculpt_Registry", "pending_ReaCat_instance_number") == "" and reaper.GetExtState("ReaSculpt_Registry", "pending_ReaCat_project_identity") == "", "the launcher's keys were read once and cleared")
  report(frames(10), "frames are drawn")
  report(titles[#titles] == "ReaCat #3", "the window title carries the instance number", titles[#titles])
  report(#queue == 1, "the window is open (it has its next frame)")

  -- one window: a second start while this one is open hands over and ends (it still reads and clears the launcher's keys)
  reaper.SetExtState("ReaSculpt_Registry", "pending_ReaCat_instance_number", "4", false)
  package.loaded["ReaSnap_Integration"] = nil
  local okSecond = pcall(dofile, REPO .. "/ReaCat.lua")
  report(okSecond and #queue == 1, "a second start while the window is open opens no second window", #queue)
  report(reaper.GetExtState("ReaCat_Window", "focus") == "1", "it asks the open window to come to the front")
  report(reaper.GetExtState("ReaSculpt_Registry", "pending_ReaCat_instance_number") == "", "and it cleared the launcher's key")
  frames(2)
  report(reaper.GetExtState("ReaCat_Window", "focus") == "", "the open window answered the request")
  report(reaper.GetExtState("ReaCat_Window", "open") == "1" and tonumber(reaper.GetExtState("ReaCat_Window", "stamp")) ~= nil, "and keeps its stamp")

  -- a Close All for another project leaves it alone
  local t = reaper.time_precise() + 1
  reaper.SetExtState("ReaSculpt_Registry", "close_ReaCat_signal", "proj-B|" .. string.format("%.3f", t), false)
  frames(40)
  report(#queue == 1, "a Close All for another project is ignored")
  -- a signal older than the window is ignored too
  reaper.SetExtState("ReaSculpt_Registry", "close_ReaCat_signal", "proj-A|1.0", false)
  frames(40)
  report(#queue == 1, "an old Close All signal is ignored")
  -- Close All for this project closes the window
  reaper.SetExtState("ReaSculpt_Registry", "close_ReaCat_signal", "proj-A|" .. string.format("%.3f", reaper.time_precise() + 1), false)
  local closed = false
  for _ = 1, 400 do
    frames(1)
    if #queue == 0 then closed = true break end
    local t0 = reaper.time_precise() while reaper.time_precise() - t0 < 0.01 do end
  end
  report(closed, "Close All for this project ends the window's frame loop")
  report(reaper.GetExtState("ReaCat_Window", "open") == "", "a closed window removes its stamp (a new one can open)")
  reaper.DeleteExtState("ReaSculpt_Registry", "close_ReaCat_signal", false)

  -- opened the old way (no keys): a plain title, and Close All never fires
  queue, titles = {}, {}
  package.loaded["ReaSnap_Integration"] = nil          -- every script run has a Lua state of its own in REAPER; this test shares one
  local ok2 = pcall(dofile, REPO .. "/ReaCat.lua")
  frames(10)
  report(ok2 and titles[#titles] == "ReaCat", "opened from the Actions list: the title is plain", titles[#titles])
  reaper.SetExtState("ReaSculpt_Registry", "close_ReaCat_signal", "proj-A|" .. string.format("%.3f", reaper.time_precise() + 1), false)
  frames(40)
  report(#queue == 1, "and a Close All does not reach it (only windows launched through ReaSnap)")
  reaper.DeleteExtState("ReaSculpt_Registry", "close_ReaCat_signal", false)
end)
if not ok0 then report(false, "the test ran without a script error", err0) end
finish()
