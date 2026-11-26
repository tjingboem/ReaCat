-- dump_automation_item.lua (26 Nov 2026): prints what REAPER says about the SELECTED automation item(s) to REAPER's console: the envelope, its range,
-- the item's position, length, start offset, play rate, baseline, amplitude, loop, pool, and every point (time, value, shape), plus the value
-- Envelope_Evaluate gives at 5 places inside the item. Load it in the Actions list (Actions, Show action list, New action, Load ReaScript), select
-- the automation item, run it, and send the text to Claude. It changes nothing.
local function line(...) reaper.ShowConsoleMsg(table.concat({ ... }, " ") .. "\n") end
reaper.ClearConsole()
local tracks = { reaper.GetMasterTrack(0) }
for i = 0, reaper.CountTracks(0) - 1 do tracks[#tracks + 1] = reaper.GetTrack(0, i) end
local found = 0
for _, tr in ipairs(tracks) do
  for k = 0, reaper.CountTrackEnvelopes(tr) - 1 do
    local env = reaper.GetTrackEnvelope(tr, k)
    local _, name = reaper.GetEnvelopeName(env)
    for a = 0, reaper.CountAutomationItems(env) - 1 do
      if reaper.GetSetAutomationItemInfo(env, a, "D_UISEL", 0, false) ~= 0 then
        found = found + 1
        local function info(w) return reaper.GetSetAutomationItemInfo(env, a, w, 0, false) end
        line("== envelope", name, " item index", a)
        line("scaling mode", reaper.GetEnvelopeScalingMode(env), " PARM_MIN", tostring(reaper.GetEnvelopeInfo_Value(env, "PARM_MIN")), " PARM_MAX", tostring(reaper.GetEnvelopeInfo_Value(env, "PARM_MAX")))
        local _, chunk = reaper.GetEnvelopeStateChunk(env, "", false)
        line("chunk head:", (chunk or ""):match("^[^\n]*"), " MINVAL", tostring((chunk or ""):match("\nMINVAL ([%-%.%d]+)")), " MAXVAL", tostring((chunk or ""):match("\nMAXVAL ([%-%.%d]+)")))
        line("position", info("D_POSITION"), " length", info("D_LENGTH"), " startoffs", info("D_STARTOFFS"), " playrate", info("D_PLAYRATE"))
        line("baseline", info("D_BASELINE"), " amplitude", info("D_AMPLITUDE"), " loop", info("D_LOOPSRC"), " pool id", info("D_POOL_ID"), " pool QN length", info("D_POOL_QNLEN"))
        local n = reaper.CountEnvelopePointsEx(env, a)
        line("points in the item:", n)
        -- the first 12 and the last 4 points, and the lowest and highest value (the console would not hold a thousand lines)
        local lowest, highest = math.huge, -math.huge
        for p = 0, n - 1 do
          local ok, t, v, sh, ten = reaper.GetEnvelopePointEx(env, a, p)
          if ok then lowest, highest = math.min(lowest, v), math.max(highest, v) end
          if p < 12 or p >= n - 4 then line(string.format("  %4d  time %.4f  value %.5f  shape %s", p, t, v, tostring(sh))) end
          if p == 12 and n > 16 then line("  ...") end
        end
        line(string.format("lowest value %.5f   highest value %.5f", lowest, highest))
        local pos, len = info("D_POSITION"), info("D_LENGTH")
        for _, f in ipairs({ 0, 0.25, 0.5, 0.75, 0.999 }) do
          local ok, v = reaper.Envelope_Evaluate(env, pos + f * len, 44100, 1)
          line(string.format("  evaluated at %5.1f%% of the item: %.5f", f * 100, v or -1))
        end
      end
    end
  end
end
if found == 0 then line("no automation item is selected") end
