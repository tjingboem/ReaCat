-- ReaCat — the catalogue of envelopes. Load this into the Actions list once (ReaScript: Load...) and run it.
-- Every tool that makes a curve can "Send to ReaCat and the world"; every tool that needs a curve can take one from here.
-- Spec: doc/ReaCat_Spec.md. The files are in <REAPER resource folder>/Data/ReaCat/.

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

local ctx = reaper.ImGui_CreateContext("ReaCat")
local st = Picker.new()

local function loop()
  reaper.ImGui_SetNextWindowSize(ctx, 980, 760, reaper.ImGui_Cond_FirstUseEver())
  reaper.ImGui_SetNextWindowSizeConstraints(ctx, 560, 420, 2400, 1600)
  local visible, open = reaper.ImGui_Begin(ctx, "ReaCat", true)
  if visible then
    Picker.draw(ctx, st, { browser = true })
    reaper.ImGui_End(ctx)
  end
  if open then
    reaper.defer(loop)
  elseif reaper.ImGui_DestroyContext then
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)
