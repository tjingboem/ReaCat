-- ReaCat — the catalogue of envelopes. Load this into the Actions list once (ReaScript: Load...) and run it.
-- Every tool that makes a curve can "Send to ReaCat and the world"; every tool that needs a curve can take one from here.
-- Spec: doc/ReaCat_Spec.md. The files are in <REAPER resource folder>/Data/ReaCat/.
-- ReaSnap (optional): the window title carries the instance number and Close All closes it (pieces 2 and 5 of the Integration Contract).

local missing = {}
if not reaper.ImGui_CreateContext then missing[#missing + 1] = "ReaImGui (install it with ReaPack)" end
if #missing > 0 then
  reaper.MB("ReaCat needs: " .. table.concat(missing, ", "), "ReaCat", 0)
  return
end

local here = ({ reaper.get_action_context() })[2]:match("^(.*)[/\\][^/\\]*$") or "."
package.path = here .. "/lib/?.lua;" .. package.path
local Cat = require("ReaCat")
local Picker = require("ReaCatPicker")

-- ReaSnap Integration Contract pieces 2 and 5. Without the file (or without ReaSnap) the window is simply "ReaCat".
local ReaSnap = (function()
  local ok, mod = pcall(require, "ReaSnap_Integration")
  if ok and type(mod) == "table" then return mod end
  return { windowTitle = function(name) return name end, shouldClose = function() return false end }
end)()

-- One window at a time (ReaCat is one view of one catalogue; two windows would only confuse): when another ReaCat window is open, this start
-- asks that one to come to the front and ends. The open window renews a time stamp from its own frame loop (nothing runs in the background);
-- a stamp older than two seconds counts as gone, so a window that crashed never blocks a new one. (REAPER's "Terminate or New instance?" question
-- has to be answered "New instance" for a second start to get this far, as with the other tools.)
local SEC = "ReaCat_Window"
do
  local stamp = tonumber(reaper.GetExtState(SEC, "stamp"))
  if stamp and reaper.GetExtState(SEC, "open") == "1" and reaper.time_precise() - stamp < 2.0 then
    reaper.SetExtState(SEC, "focus", "1", false)
    return
  end
end
local function stampWindow()
  reaper.SetExtState(SEC, "stamp", string.format("%.3f", reaper.time_precise()), false)
  reaper.SetExtState(SEC, "open", "1", false)
end
local function unstampWindow()
  reaper.DeleteExtState(SEC, "stamp", false)
  reaper.DeleteExtState(SEC, "open", false)
end
stampWindow()
reaper.atexit(unstampWindow)

local ctx = reaper.ImGui_CreateContext("ReaCat")
local st = Picker.new()
local lastStamp = reaper.time_precise()

local function loop()
  local now = reaper.time_precise()
  if now - lastStamp > 0.5 then stampWindow() lastStamp = now end
  if reaper.GetExtState(SEC, "focus") == "1" then
    reaper.DeleteExtState(SEC, "focus", false)
    reaper.ImGui_SetNextWindowFocus(ctx)                  -- another start asked for this window to come to the front
  end
  reaper.ImGui_SetNextWindowSize(ctx, 980, 760, reaper.ImGui_Cond_FirstUseEver())
  reaper.ImGui_SetNextWindowSizeConstraints(ctx, 560, 420, 2400, 1600)
  local visible, open = reaper.ImGui_Begin(ctx, ReaSnap.windowTitle("ReaCat"), true)
  -- ReaSnap's Close All: checked outside the visible gate, so it also works while the window is collapsed.
  if ReaSnap.shouldClose() then open = false end
  if visible then
    Picker.draw(ctx, st, { browser = true })
    reaper.ImGui_End(ctx)
  end
  if open then
    reaper.defer(loop)
  else
    unstampWindow()
    if reaper.ImGui_DestroyContext then reaper.ImGui_DestroyContext(ctx) end
  end
end

reaper.defer(loop)
