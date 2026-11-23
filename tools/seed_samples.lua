-- ReaCat: put a few SAMPLE curves into the catalogue, so the ReaCat window has something to show before any tool sends.
-- Run it from the Actions list (ReaScript: Load...). Every sample has the tag "sample": search  tag:sample  and delete them when you are done.
-- Running it twice adds nothing new (the same curve from the same source and name is stored once).

local here = ({ reaper.get_action_context() })[2]:match("^(.*)[/\\][^/\\]*$") or "."
package.path = here .. "/../lib/?.lua;" .. package.path
local Cat = require("ReaCat")

local function wave(n, f)
  local pts = {}
  for i = 0, n do local t = i / n pts[#pts + 1] = { t, math.max(0, math.min(1, f(t))) } end
  return pts
end

local samples = {
  { "Sample Tool", "sine",       wave(48, function(t) return 0.5 + 0.45 * math.sin(t * 2 * math.pi * 2) end), "smooth,lfo" },
  { "Sample Tool", "ramp up",    { { 0, 0 }, { 1, 1 } }, "ramp" },
  { "Sample Tool", "ramp down",  { { 0, 1 }, { 1, 0 } }, "ramp" },
  { "Sample Tool", "triangle",   { { 0, 0 }, { 0.5, 1 }, { 1, 0 } }, "lfo" },
  { "Sample Tool", "staircase",  { { 0, 0.1, 1 }, { 0.25, 0.4, 1 }, { 0.5, 0.7, 1 }, { 0.75, 1, 1 }, { 1, 1 } }, "steps,gate" },
  { "Sample Tool", "gate",       { { 0, 1, 1 }, { 0.2, 0, 1 }, { 0.4, 1, 1 }, { 0.6, 0, 1 }, { 0.8, 1, 1 }, { 1, 0 } }, "gate,rhythm" },
  { "Sample Tool", "swell",      { { 0, 0, 2 }, { 0.5, 1, 2 }, { 1, 0 } }, "smooth,dynamics" },
  { "Sample Tool", "bounce",     { { 0, 1, 3 }, { 0.3, 0, 3 }, { 0.55, 0.6, 3 }, { 0.75, 0, 3 }, { 0.88, 0.3, 3 }, { 1, 0 } }, "smooth" },
  { "Sample Tool", "random walk", (function()
      local v, pts = 0.5, {}
      math.randomseed(7)
      for i = 0, 40 do pts[#pts + 1] = { i / 40, v } v = math.max(0, math.min(1, v + (math.random() - 0.5) * 0.3)) end
      return pts
    end)(), "walk,random" },
  { "Sample Tool", "bezier S",   { { 0, 0, 5, 0.9, 0.1 }, { 1, 1 } }, "smooth" },
}

local made = 0
for _, s in ipairs(samples) do
  local id, err = Cat.send{ source = s[1], name = s[2], points = s[3], beats = 8, tags = (s[4] or "") .. ",sample" }
  if id then made = made + 1 else reaper.ShowConsoleMsg("ReaCat sample: " .. tostring(err) .. "\n") end
end
reaper.MB(made .. " sample curves are in the catalogue (tag: sample).\nOpen ReaCat to see them.", "ReaCat", 0)
