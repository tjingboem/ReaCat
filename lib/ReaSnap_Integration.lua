-- ============================================================
--   ReaSnap_Integration.lua  (ReaCat)
--   Pieces 2 and 5 of the ReaSnap Integration Contract: the window title with an instance number (cosmetic) and Close All.
--   Pieces 1, 3 and 4 (serializer, settings on an item, settings applied at startup) do not apply: ReaCat's catalogue is not tied to an item
--   (a snapshot's Capture and Restore of the catalogue entries is done by ReaSnap itself, spec section 11.5). Written after ReaNvelopes' version.
--   Without ReaSnap, or when the window is opened from the Actions list, nothing here does anything: the title is "ReaCat" and Close All never fires.
--
--   Used by ReaCat.lua:
--     ReaSnap.windowTitle("ReaCat")   the window title
--     ReaSnap.shouldClose()           true once ReaSnap's Close All asked this instance to close
-- ============================================================

local TOOL_NAME = "ReaCat"

local M = {}

-- Piece 2: the instance number, put there by ReaSnap's launcher (read once, then cleared).
M.instance_number = nil
if reaper.HasExtState("ReaSculpt_Registry", "pending_" .. TOOL_NAME .. "_instance_number") then
  M.instance_number = reaper.GetExtState("ReaSculpt_Registry", "pending_" .. TOOL_NAME .. "_instance_number")
  reaper.DeleteExtState("ReaSculpt_Registry", "pending_" .. TOOL_NAME .. "_instance_number", false)
end

-- Piece 5: Close All. Only an instance launched through ReaSnap has a project identity and can be closed this way.
M.project_identity = nil
if reaper.HasExtState("ReaSculpt_Registry", "pending_" .. TOOL_NAME .. "_project_identity") then
  M.project_identity = reaper.GetExtState("ReaSculpt_Registry", "pending_" .. TOOL_NAME .. "_project_identity")
  reaper.DeleteExtState("ReaSculpt_Registry", "pending_" .. TOOL_NAME .. "_project_identity", false)
end

M.birth_time = reaper.time_precise()

-- Cheap enough to call every frame (checked at most every 0.25 s). True only if the signal is for this instance's project and is newer
-- than this instance, so an old signal never closes a new window.
local _last_close_check = 0
function M.shouldClose()
  if not M.project_identity then return false end
  local now = reaper.time_precise()
  if now - _last_close_check < 0.25 then return false end
  _last_close_check = now

  local raw = reaper.GetExtState("ReaSculpt_Registry", "close_" .. TOOL_NAME .. "_signal")
  if raw == "" then return false end
  local sig_project, sig_time = raw:match("^(.-)|([%d%.]+)$")
  sig_time = tonumber(sig_time)
  if not (sig_project and sig_time) then return false end
  if sig_project ~= M.project_identity then return false end
  if sig_time <= M.birth_time then return false end
  return true
end

function M.windowTitle(base_name)
  if M.instance_number then return base_name .. " #" .. M.instance_number end
  return base_name
end

return M
