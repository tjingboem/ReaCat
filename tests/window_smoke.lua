-- window_smoke.lua: the real ReaCat window and the picker draw frames in a REAPER of its own, without an error, on a catalogue of samples.
-- Run:  RT_REACAT=<repo> SHOT=<png> tests/run_in_reaper.sh tests/window_smoke.lua
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

local Cat = require("ReaCat")
local Picker = require("ReaCatPicker")

-- the samples (tools/seed_samples.lua without its message box), plus a rule
local seed = io.open(REPO .. "/tools/seed_samples.lua", "r"):read("a"):gsub("reaper%.MB%b()", "local _ = 0")
reaper.get_action_context = function() return true, REPO .. "/tools/seed_samples.lua", 0, 0, 0, 0, 0 end
local ok, err = pcall(load(seed, "seed"))
report(ok, "the sample script runs", err)
report(#Cat.list() == 10, "10 samples in the catalogue", #Cat.list())
Cat.send{ kind = "rule", source = "Markov", name = "State", rulekind = "value", text = "mv,a{0}b{1}:{a=1|b=1}a:{a=1|b=1},(c,0)" }
Cat.send{ source = "ReaNvelopes", name = "RAND", points = { { 0, 0.5, 2 }, { 0.3, 0.9, 2 }, { 0.6, 0.1, 2 }, { 1, 0.6 } }, range = { -12, 12 }, unit = "semitones", tags = "bridge" }
report(#Cat.list() == 12, "12 entries", #Cat.list())

-- the real window: ReaCat.lua itself, its frame loop watched
reaper.get_action_context = function() return true, REPO .. "/ReaCat.lua", 0, 0, 0, 0, 0 end
local frames, errors = 0, {}
local realDefer = reaper.defer
reaper.defer = function(f)
  realDefer(function()
    local ok2, e = pcall(f)
    if ok2 then frames = frames + 1 else errors[#errors + 1] = tostring(e) end
  end)
end
local chunk, lerr = loadfile(REPO .. "/ReaCat.lua")
report(chunk ~= nil, "ReaCat.lua loads", lerr)
local pok, perr = pcall(chunk)
report(pok, "ReaCat.lua starts", perr)

-- the picker in receiver mode, in a window of its own
local ctx2 = reaper.ImGui_CreateContext("ReaCat picker test")
local st2 = Picker.new()
local taken
local function loop2()
  reaper.ImGui_SetNextWindowPos(ctx2, 1320, 20, reaper.ImGui_Cond_FirstUseEver())
  reaper.ImGui_SetNextWindowSize(ctx2, 640, 560, reaper.ImGui_Cond_FirstUseEver())
  local vis, open = reaper.ImGui_Begin(ctx2, "picker test", true)
  if vis then
    local t = Picker.draw(ctx2, st2, { height = 500 })
    if t then taken = t end
    reaper.ImGui_End(ctx2)
  end
  if open then reaper.defer(loop2) end
end
reaper.defer(loop2)

-- the browser mode (what ReaCat.lua draws) in a second window, away from the mouse, with an entry in focus so that the edit panel is drawn
local ctx3 = reaper.ImGui_CreateContext("ReaCat browser test")
local st3 = Picker.new()
local function loop3()
  reaper.ImGui_SetNextWindowPos(ctx3, 1320, 590, reaper.ImGui_Cond_FirstUseEver())
  reaper.ImGui_SetNextWindowSize(ctx3, 900, 470, reaper.ImGui_Cond_FirstUseEver())
  local vis, open = reaper.ImGui_Begin(ctx3, "browser test", true)
  if vis then
    Picker.draw(ctx3, st3, { browser = true })
    reaper.ImGui_End(ctx3)
  end
  if open then reaper.defer(loop3) end
end
reaper.defer(loop3)

-- the receiver buttons (Latest / ReaCat...) with the picker open, as a tool draws them inside a popup-like window
local ctx4 = reaper.ImGui_CreateContext("ReaCat receiver test")
local st4 = Picker.new()
st4.rOpen = true
local took
local function loop4()
  reaper.ImGui_SetNextWindowPos(ctx4, 2400, 20, reaper.ImGui_Cond_FirstUseEver())
  reaper.ImGui_SetNextWindowSize(ctx4, 720, 520, reaper.ImGui_Cond_FirstUseEver())
  local vis, open = reaper.ImGui_Begin(ctx4, "receiver test", true)
  if vis then
    reaper.ImGui_Text(ctx4, "Take a curve or a rule")
    local t = Picker.receiver(ctx4, st4, { accept = function(e) return e.kind == "curve" end, acceptKey = "smoke" })
    if t then took = t end
    reaper.ImGui_End(ctx4)
  end
  if open then reaper.defer(loop4) end
end
reaper.defer(loop4)

-- after some frames: a search, a tag, a bad search; then the screenshot; then the end
local step = 0
local function watch()
  step = step + 1
  if step == 20 then st2.query, st2.dirty = 'smooth OR tag:gate', true end
  if step == 40 then report(#st2.list >= 4 and #st2.list < 12, "picker: a boolean search filters the list", #st2.list) end
  if step == 45 then st2.query, st2.dirty = "(smooth", true end
  if step == 50 then report(st2.qerr ~= nil and #st2.list == 12, "picker: a bad search shows a problem and leaves the list", st2.qerr) end
  if step == 55 then
    st2.query, st2.dirty = "", true
    st2.focus = Cat.list()[1].id
    st3.focus = Cat.list()[2].id
    st3.sel[Cat.list()[2].id] = true
    st3.tagInput = "sm"
    st3.msg, st3.msgAt = "a message in the bottom line", reaper.time_precise()
  end
  if step == 60 then
    local f = io.open(out_dir .. "/READY", "w") f:write("1") f:close()
  end
  if step > 60 and io.open(out_dir .. "/GO", "r") then
    report(frames > 100, "frames drawn without an error", frames .. " frames")
    report(#errors == 0, "no script error in the frame loops", errors[1])
    finish()
    return
  end
  if step > 1500 then report(false, "the screenshot step was reached") finish() return end
  realDefer(watch)
end
realDefer(watch)
