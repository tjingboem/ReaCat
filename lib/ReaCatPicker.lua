-- ============================================================
--   ReaCatPicker.lua  —  the catalogue as thumbnails (ReaImGui). One widget for every tool and for the ReaCat window.
--   Spec: doc/ReaCat_Spec.md, sections 7 and 8. Needs lib/ReaCat.lua (the pure Lua core) and ReaImGui.
--
--     local st = Picker.new()                                  -- once
--     local taken = Picker.draw(ctx, st, { height = 420 })     -- every frame, inside a window or a popup
--         -> nil, or { id = "...", originalRange = true|false }   (a receiver then calls ReaCat.get(id))
--     Picker.draw(ctx, st, { browser = true, height = 600 })   -- the ReaCat window: edit, delete, cleanup, settings
--
--   Picker mode: click = take, Shift+click = look at it / edit its tags.
--   Browser mode: click = look at it, double-click = send it again (it becomes the newest), Ctrl+click = select
--   several, right-click = delete (to the trash; "Undo delete" brings it back).
--   Information comes up on screen in the panel under the grid, not as a tooltip.
-- ============================================================

local okCat, Cat = pcall(require, "ReaCat")
if not okCat then Cat = require("core.ReaCat") end        -- a tool that keeps the lib in core/ (ReaAC)
local R = reaper

local P = {}

local C = {
  bg = 0x14181CFF, line = 0x7FB6FFFF, border = 0x3C4650FF, hover = 0xFFFFFFFF, sel = 0xF0A030FF, focus = 0x58D68DFF,
  dim = 0x9AA4AEFF, err = 0xFF7070FF, ok = 0x70D090FF, ruletext = 0xC8B8F0FF, fav = 0xFFD040FF, used = 0xE04848FF, amber = 0xA86A00FF, amberOn = 0xD98C00FF,
}

-- a tag is a small button with round ends (a pill)
local function pill(ctx, label)
  R.ImGui_PushStyleVar(ctx, R.ImGui_StyleVar_FrameRounding(), 10)
  local clicked = R.ImGui_SmallButton(ctx, label)
  R.ImGui_PopStyleVar(ctx)
  return clicked
end

local DATE_ITEMS = "All dates\0Today\0Last 7 days\0Last 30 days\0Range\0"
local SORT_ITEMS = "Newest first\0Oldest first\0By source\0"
local HINT = "search: lorenz AND smooth NOT step   (tag:  source:  name:  note:  \"phrase\"  brackets)"

-- ---------------------------------------------------------------- state

function P.new()
  return {
    query = "", qerr = nil, dateMode = 0, from = "", to = "", sort = 0,
    list = {}, total = 0, tags = {}, cache = {},
    sel = {}, focus = nil, hover = nil, useRange = false,
    tagInput = "", noteBuf = nil, noteFor = nil,
    deleted = {}, msg = nil, msgAt = 0, dirty = true,
    lastStamp = nil, lastEdit = nil, kind = nil, rulekind = nil, cleanupOpen = false, cleanupPick = nil,
  }
end

local function say(st, text) st.msg, st.msgAt = text, R.time_precise() end

local function validDate(s) return s and s:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil end

local function dayAgo(n) return os.date("%Y-%m-%d", os.time() - n * 86400) end

local function refresh(st, opts)
  local stamp, edit = Cat.stamp(), Cat.editStamp()
  if st.kind ~= opts.kind or st.rulekind ~= opts.rulekind or st.acceptKey ~= opts.acceptKey then
    st.kind, st.rulekind, st.acceptKey, st.dirty = opts.kind, opts.rulekind, opts.acceptKey, true
  end
  if not st.dirty and stamp == st.lastStamp and edit == st.lastEdit then return end
  st.dirty, st.lastStamp, st.lastEdit = false, stamp, edit

  local match, err = Cat.query(st.query)
  st.qerr = err
  local from, to
  if st.dateMode == 1 then from, to = dayAgo(0), nil
  elseif st.dateMode == 2 then from = dayAgo(7)
  elseif st.dateMode == 3 then from = dayAgo(30)
  elseif st.dateMode == 4 then
    if validDate(st.from) then from = st.from end
    if validDate(st.to) then to = st.to end
  end

  local all = Cat.list()
  st.total = #all
  st.used = Cat.usedHashes()                       -- which entries are used in this project (the red borders)
  st.nUsed = 0
  for _, e in ipairs(all) do if st.used[e.hash] then st.nUsed = st.nUsed + 1 end end
  local out, counts, spelling, projects = {}, {}, {}, {}
  for _, e in ipairs(all) do
    local day = e.sent:sub(1, 10)
    local keep = true
    if opts.kind and e.kind ~= opts.kind then keep = false end
    if keep and opts.rulekind and e.rulekind ~= opts.rulekind then keep = false end
    if keep and opts.accept and not opts.accept(e) then keep = false end
    if keep and from and day < from then keep = false end
    if keep and to and day > to then keep = false end
    if keep and match and not match(e) then keep = false end
    if keep then out[#out + 1] = e end
    if e.project and e.project ~= "" then            -- the project name is a fixed tag, shown in amber
      local pk = e.project:lower()
      counts[pk] = (counts[pk] or 0) + 1
      spelling[pk] = spelling[pk] or e.project
      projects[pk] = true
    end
    for _, t in ipairs(e.tags) do                      -- the chips show every tag of the catalogue
      local k = t:lower()
      counts[k] = (counts[k] or 0) + 1
      spelling[k] = spelling[k] or t
    end
  end
  if st.sort == 1 then
    local rev = {}
    for i = #out, 1, -1 do rev[#rev + 1] = out[i] end
    out = rev
  elseif st.sort == 2 then
    table.sort(out, function(a, b)
      local sa, sb = a.source:lower(), b.source:lower()
      if sa ~= sb then return sa < sb end
      if a.name:lower() ~= b.name:lower() then return a.name:lower() < b.name:lower() end
      return a.sent > b.sent
    end)
  end
  st.list = out
  local tags = {}
  for k, c in pairs(counts) do tags[#tags + 1] = { tag = spelling[k], count = c, project = projects[k] or nil } end
  table.sort(tags, function(a, b) if a.count ~= b.count then return a.count > b.count end return a.tag:lower() < b.tag:lower() end)
  st.tags = tags
end

-- the points (or the rule text) of an entry, loaded when the thumbnail is first drawn
local function full(st, id)
  local e = st.cache[id]
  if e == nil then
    local n = 0
    for _ in pairs(st.cache) do n = n + 1 end
    if n > 600 then st.cache = {} end
    e = Cat.get(id) or false
    st.cache[id] = e
  end
  return e or nil
end

-- ---------------------------------------------------------------- the picture

local function segValue(a, b, u)
  local sh = a.shape or 0
  if sh == 2 then u = u * u * (3 - 2 * u)
  elseif sh == 3 then u = 1 - (1 - u) * (1 - u)
  elseif sh == 4 then u = u * u
  elseif sh == 5 then
    local c1 = a.c1 or (a.v + (b.v - a.v) / 3)
    local c2 = a.c2 or (a.v + (b.v - a.v) * 2 / 3)
    local w = 1 - u
    return w * w * w * a.v + 3 * w * w * u * c1 + 3 * w * u * u * c2 + u * u * u * b.v
  end
  return a.v + (b.v - a.v) * u
end

-- A curve (or a rule) drawn small, from the entry's points. `e` = the full entry (ReaCat.get) or nil while it is not loaded.
function P.picture(dl, x, y, w, h, e, border)
  R.ImGui_DrawList_AddRectFilled(dl, x, y, x + w, y + h, C.bg, 3)
  if e and e.kind == "curve" and e.points then
    local pad = 3
    local function X(t) return x + pad + t * (w - 2 * pad) end
    local function Y(v) return y + h - pad - math.max(0, math.min(1, v)) * (h - 2 * pad) end
    local pts, many = e.points, #e.points > 150
    local px, py = X(pts[1].t), Y(pts[1].v)
    local function to(t, v)
      local nx, ny = X(t), Y(v)
      R.ImGui_DrawList_AddLine(dl, px, py, nx, ny, C.line, 1.5)
      px, py = nx, ny
    end
    for i = 1, #pts - 1 do
      local a, b = pts[i], pts[i + 1]
      local sh = a.shape or 0
      if many or sh == 0 then to(b.t, b.v)
      elseif sh == 1 then to(b.t, a.v) to(b.t, b.v)
      else
        for k = 1, 10 do local u = k / 10 to(a.t + (b.t - a.t) * u, segValue(a, b, u)) end
      end
    end
  elseif e and e.kind == "rule" then
    R.ImGui_DrawList_AddText(dl, x + 5, y + 4, C.ruletext, "rule" .. ((e.rulekind and e.rulekind ~= "") and (" - " .. e.rulekind) or ""))
    local t = (e.text or ""):gsub("\n", " ")
    local per = math.max(4, math.floor((w - 10) / 7))
    for i = 0, 2 do
      local s = t:sub(i * per + 1, (i + 1) * per)
      if s == "" then break end
      R.ImGui_DrawList_AddText(dl, x + 5, y + 20 + i * 14, C.dim, s)
    end
  end
  R.ImGui_DrawList_AddRect(dl, x, y, x + w, y + h, border or C.border, 3, 0, border and 2 or 1)
end

local function shorten(s, maxChars)
  if #s <= maxChars then return s end
  return s:sub(1, math.max(1, maxChars - 1)) .. "…"
end

-- "Lorenz Attractor x": the module (the source) first, then the name. When the room is short the source gives way, so that
-- the name (the x, y, z of an attractor) always stays readable.
function P.label(e, maxChars)
  local name = shorten(e.name, math.max(3, math.floor(maxChars * 0.6)))
  local room = maxChars - (utf8.len(name) or #name) - 1
  if room < 4 then return name end
  return shorten(e.source, room) .. " " .. name
end

-- ---------------------------------------------------------------- small controls

local function chipsRow(ctx, st)
  local avail = R.ImGui_GetContentRegionAvail(ctx)
  local used = 0
  local shown = 0
  for i, t in ipairs(st.tags) do
    if shown >= 40 then break end
    local label = t.tag .. " " .. t.count
    local w = R.ImGui_CalcTextSize(ctx, label) + 14
    if used > 0 then
      if used + w + 4 > avail then used = 0 else R.ImGui_SameLine(ctx, 0, 4) end
    end
    local needle = 'tag:"' .. t.tag .. '"'
    local on = st.query:find(needle, 1, true) ~= nil
    local tint = t.project and (on and C.amberOn or C.amber) or (on and 0x2E6BA8FF) or nil
    if tint then R.ImGui_PushStyleColor(ctx, R.ImGui_Col_Button(), tint) end
    if pill(ctx, label .. "##chip" .. i) then
      if on then
        local a, b = st.query:find(needle, 1, true)
        st.query = (st.query:sub(1, a - 1) .. st.query:sub(b + 1)):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
      else
        st.query = (st.query ~= "" and (st.query .. " ") or "") .. needle
      end
      st.dirty = true
    end
    if tint then R.ImGui_PopStyleColor(ctx) end
    used = used + w + 4
    shown = shown + 1
  end
  if shown == 0 then R.ImGui_TextColored(ctx, C.dim, "no tags yet") end
end

local function selectedIds(st)
  local ids = {}
  for id in pairs(st.sel) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

local function tagTargets(st)         -- the entries a tag edit goes to: all selected ones when the focus is one of them
  if st.focus and st.sel[st.focus] and next(st.sel, next(st.sel)) ~= nil then return selectedIds(st) end
  return { st.focus }
end

local function infoPanel(ctx, st, opts, shown, h)
  if not R.ImGui_BeginChild(ctx, "##info", 0, h, R.ImGui_ChildFlags_Borders()) then return end
  local e = shown and full(st, shown.id)
  if not shown then
    R.ImGui_TextColored(ctx, C.dim, opts.browser and "Click an entry to look at it and edit its tags." or "Click an entry to take it. Shift+click: look at it and edit its tags.")
    R.ImGui_EndChild(ctx)
    return
  end
  local editing = (st.focus == shown.id)
  R.ImGui_BeginGroup(ctx)                         -- left: the picture; right: the words (a group, so that the right side starts at the top)
  local x, y = R.ImGui_GetCursorScreenPos(ctx)
  R.ImGui_Dummy(ctx, 240, 120)
  P.picture(R.ImGui_GetWindowDrawList(ctx), x, y, 240, 120, e)
  -- under the picture: what 0 and 1 stood for, and the Original range choice
  if shown.range then
    R.ImGui_TextColored(ctx, C.dim, string.format("0 = %.6g, 1 = %.6g %s", shown.range[1], shown.range[2], shown.unit or ""))
    if not opts.browser and not opts.noRange then
      local ch, v = R.ImGui_Checkbox(ctx, "Original range##orig", st.useRange)
      if ch then st.useRange = v end
    end
  end
  R.ImGui_EndGroup(ctx)
  R.ImGui_SameLine(ctx, 0, 16)
  R.ImGui_BeginGroup(ctx)
  R.ImGui_Text(ctx, shown.source .. "  -  " .. shown.name)
  R.ImGui_TextColored(ctx, C.dim, "saved " .. shown.saved .. "     sent " .. shown.sent)
  local facts = shown.kind
  if shown.rulekind and shown.rulekind ~= "" then facts = facts .. " (" .. shown.rulekind .. ")" end
  if shown.beats then facts = facts .. string.format("     %.6g beats", shown.beats) end
  if e and e.points then facts = facts .. "     " .. #e.points .. " points" end
  R.ImGui_TextColored(ctx, C.dim, facts)
  if shown.note and shown.note ~= "" and not editing then
    R.ImGui_PushTextWrapPos(ctx, 0)
    R.ImGui_TextWrapped(ctx, shown.note)
    R.ImGui_PopTextWrapPos(ctx)
  end
  -- the tags; while this entry is the one being edited they can be removed and added
  local function projectChip()
    if shown.project and shown.project ~= "" then
      R.ImGui_PushStyleColor(ctx, R.ImGui_Col_Button(), C.amber)
      if pill(ctx, shown.project .. "##proj") then
        local needle = 'tag:"' .. shown.project .. '"'
        if not st.query:find(needle, 1, true) then st.query = (st.query ~= "" and (st.query .. " ") or "") .. needle st.dirty = true end
      end
      R.ImGui_PopStyleColor(ctx)
      return true
    end
  end
  if editing then
    local i = 0
    local avail = R.ImGui_GetContentRegionAvail(ctx)
    local hasProj = projectChip()
    local used = hasProj and (R.ImGui_CalcTextSize(ctx, shown.project) + 18) or 0
    for _, t in ipairs(shown.tags) do
      local label = t .. "  x"
      local cw = R.ImGui_CalcTextSize(ctx, label) + 14
      if used > 0 then
        if used + cw + 4 > avail then used = 0 else R.ImGui_SameLine(ctx, 0, 4) end
      end
      used = used + cw + 4
      if pill(ctx, label .. "##rm" .. i) then
        for _, id in ipairs(tagTargets(st)) do Cat.update(id, { removetags = { t } }) end
        st.dirty = true
      end
      i = i + 1
    end
    if i == 0 and not hasProj then R.ImGui_TextColored(ctx, C.dim, "no tags") end
    local targets = tagTargets(st)
    R.ImGui_SetNextItemWidth(ctx, 200)
    local ch, v = R.ImGui_InputTextWithHint(ctx, "##addtag", (#targets > 1) and ("add a tag to " .. #targets .. " entries") or "add a tag (Enter)", st.tagInput,
      R.ImGui_InputTextFlags_EnterReturnsTrue())
    st.tagInput = v
    if ch and v:match("%S") then
      for _, id in ipairs(targets) do Cat.update(id, { addtags = { v } }) end
      st.tagInput, st.dirty = "", true
    end
    -- suggestions: tags of the catalogue that start with what is typed
    if st.tagInput:match("%S") then
      local have, low, n = {}, st.tagInput:lower(), 0
      for _, t in ipairs(shown.tags) do have[t:lower()] = true end
      for k, t in ipairs(st.tags) do
        local tl = t.tag:lower()
        if not have[tl] and tl:sub(1, #low) == low and n < 6 then
          R.ImGui_SameLine(ctx, 0, 4)
          if pill(ctx, t.tag .. "##sug" .. k) then
            for _, id in ipairs(targets) do Cat.update(id, { addtags = { t.tag } }) end
            st.tagInput, st.dirty = "", true
          end
          n = n + 1
        end
      end
    end
    -- the note, kept when the field is left
    if st.noteFor ~= shown.id then st.noteFor, st.noteBuf = shown.id, shown.note or "" end
    R.ImGui_SetNextItemWidth(ctx, 360)
    local nch, nv = R.ImGui_InputTextWithHint(ctx, "##note", "note", st.noteBuf)
    if nch then st.noteBuf = nv end
    if R.ImGui_IsItemDeactivatedAfterEdit(ctx) then Cat.update(shown.id, { note = st.noteBuf }) st.dirty = true end
    local fch, fv = R.ImGui_Checkbox(ctx, "keep (a cleanup never proposes it)##fav", shown.fav)
    if fch then Cat.update(shown.id, { fav = fv }) st.dirty = true end
  else
    if projectChip() and #shown.tags > 0 then R.ImGui_SameLine(ctx, 0, 6) end
    if #shown.tags > 0 then
      R.ImGui_PushTextWrapPos(ctx, 0)
      R.ImGui_TextWrapped(ctx, table.concat(shown.tags, ", "))
      R.ImGui_PopTextWrapPos(ctx)
    end
  end
  -- where this entry is used in the open project: a click selects the place in REAPER
  local places = (st.used and st.used[shown.hash]) and Cat.usedBy(shown.hash) or {}
  if #places > 0 then
    local now = R.time_precise()
    st.pc = st.pc or {}
    local pc = st.pc[shown.hash]
    if not pc or pc.edit ~= st.lastEdit or now - pc.t > 2 then      -- looked up again every two seconds, and when the usage changes
      pc = { edit = st.lastEdit, t = now, exists = {} }
      for i, rec in ipairs(places) do pc.exists[i] = Cat.placeExists(rec) end
      st.pc[shown.hash] = pc
    end
    R.ImGui_TextColored(ctx, C.used, string.format("used in this project: %d place%s", #places, #places == 1 and "" or "s"))
    local gone = 0
    for i, rec in ipairs(places) do
      if i > 8 then R.ImGui_TextColored(ctx, C.dim, "...") break end
      local exists = pc.exists[i] ~= false
      if not exists then gone = gone + 1 end
      local what = (rec.what == "item") and "item" or (rec.what == "ai") and "automation item" or ("in " .. ((rec.tool ~= "") and rec.tool or "a tool"))
      R.ImGui_TextColored(ctx, exists and C.dim or C.err, string.format("%s: %s, %s%s", rec.tool, what, rec.date, exists and "" or "  (gone)"))
      if exists and rec.what ~= "param" then
        R.ImGui_SameLine(ctx, 0, 8)
        if pill(ctx, "select##use" .. i) then
          local ok, why = Cat.selectPlace(rec)
          if not ok then say(st, why) end
        end
      end
    end
    if gone > 0 and opts.browser and pill(ctx, "Forget the places that are gone##forget") then
      Cat.usePrune(Cat.placeExists)
      st.dirty, st.pc = true, nil
    end
  end
  R.ImGui_EndGroup(ctx)
  R.ImGui_EndChild(ctx)
end

-- ---------------------------------------------------------------- what a click does (also called by the tests)

-- Left click. Browser: look at it (Ctrl: add to / take from the selection). Picker: take it; Shift: look at it, to edit its tags.
-- Returns what a receiver takes, or nil.
function P._click(st, opts, e, ctrl, shift)
  if opts.browser then
    if ctrl then
      if not next(st.sel) and st.focus then st.sel[st.focus] = true end     -- the one looked at joins the selection
      if st.sel[e.id] then
        st.sel[e.id] = nil
        st.focus = selectedIds(st)[1] or e.id          -- the focus stays on something that is still selected
      else
        st.sel[e.id] = true
        st.focus = e.id
      end
    else
      st.sel = {}
      st.focus = e.id
    end
    return nil
  end
  if shift then st.focus = e.id return nil end
  return { id = e.id, originalRange = (st.useRange and e.range ~= nil) and true or false }
end

function P._sendAgain(st, e)
  Cat.touch(e.id)
  st.dirty = true
  say(st, "sent again: " .. e.source .. " - " .. e.name .. " (now the newest)")
end

-- Right click: delete this entry, or the whole selection when this entry is one of several selected.
function P._delete(st, e)
  local ids = (st.sel[e.id] and next(st.sel)) and selectedIds(st) or { e.id }
  local done = {}
  for _, id in ipairs(ids) do if Cat.delete(id) then done[#done + 1] = id end end
  if #done > 0 then
    st.deleted[#st.deleted + 1] = done
    for _, id in ipairs(done) do st.sel[id] = nil if st.focus == id then st.focus = nil end end
    say(st, #done == 1 and "deleted (Undo delete brings it back)" or (#done .. " deleted (Undo delete brings them back)"))
    st.dirty = true
  end
  return done
end

-- ---------------------------------------------------------------- the grid

local function grid(ctx, st, opts, h)
  local tw, th = opts.thumbW or 96, opts.thumbH or 54
  local gap, labelH = 6, 16
  local rowH = th + labelH + gap
  if not R.ImGui_BeginChild(ctx, "##grid", 0, h, R.ImGui_ChildFlags_Borders()) then return nil end
  local taken
  local availW = R.ImGui_GetContentRegionAvail(ctx)
  local cols = math.max(1, math.floor((availW + gap) / (tw + gap)))
  local x0, y0 = R.ImGui_GetCursorScreenPos(ctx)
  local scroll = R.ImGui_GetScrollY(ctx)
  local first = math.max(0, math.floor(scroll / rowH) - 1)
  local last = math.floor((scroll + h) / rowH) + 1
  local dl = R.ImGui_GetWindowDrawList(ctx)
  local n = #st.list
  local rows = math.ceil(n / cols)
  local mods = R.ImGui_GetKeyMods(ctx)
  local ctrl, shift = (mods & R.ImGui_Mod_Ctrl()) ~= 0, (mods & R.ImGui_Mod_Shift()) ~= 0
  local deleteNow
  for r = first, math.min(last, rows - 1) do
    for c = 0, cols - 1 do
      local i = r * cols + c + 1
      local e = st.list[i]
      if not e then break end
      local x, y = x0 + c * (tw + gap), y0 + r * rowH
      R.ImGui_SetCursorScreenPos(ctx, x, y)
      R.ImGui_PushID(ctx, e.id)
      R.ImGui_InvisibleButton(ctx, "##t", tw, th + labelH)
      local hovered = R.ImGui_IsItemHovered(ctx)
      local border
      local isUsed = st.used and st.used[e.hash] ~= nil
      if st.sel[e.id] then border = C.sel elseif st.focus == e.id then border = C.focus elseif isUsed then border = C.used end
      if hovered then st.hover, border = e, C.hover end
      P.picture(dl, x, y, tw, th, full(st, e.id), border)
      if isUsed then R.ImGui_DrawList_AddCircleFilled(dl, x + 7, y + 7, 4, C.used) end        -- red also when another border wins
      if e.fav then R.ImGui_DrawList_AddText(dl, x + tw - 14, y + 2, C.fav, "*") end
      R.ImGui_DrawList_AddText(dl, x + 2, y + th + 1, C.dim, P.label(e, math.floor(tw / 7)))
      if hovered then
        if opts.browser and R.ImGui_IsMouseDoubleClicked(ctx, 0) then
          P._sendAgain(st, e)
        elseif R.ImGui_IsItemClicked(ctx, 0) then
          taken = P._click(st, opts, e, ctrl, shift) or taken
        elseif opts.browser and R.ImGui_IsItemClicked(ctx, 1) then
          deleteNow = e
        end
      end
      R.ImGui_PopID(ctx)
    end
  end
  R.ImGui_SetCursorScreenPos(ctx, x0, y0 + rows * rowH)
  R.ImGui_Dummy(ctx, 1, 1)
  R.ImGui_EndChild(ctx)

  if deleteNow then P._delete(st, deleteNow) end
  return taken
end

-- ---------------------------------------------------------------- cleanup and settings (browser)

local function cleanupLine(ctx, st)
  local limit = Cat.cleanupLimit()
  R.ImGui_SetNextItemWidth(ctx, 90)
  local ch, v = R.ImGui_InputInt(ctx, "suggest a cleanup above this many entries (0 = never)##limit", limit, 0, 0)
  if ch then Cat.setCleanupLimit(v) limit = Cat.cleanupLimit() end
  if limit > 0 and st.total > limit then
    R.ImGui_SameLine(ctx, 0, 12)
    R.ImGui_TextColored(ctx, C.err, string.format("%d entries (limit %d)", st.total, limit))
    R.ImGui_SameLine(ctx, 0, 6)
    if R.ImGui_SmallButton(ctx, "Clean up...##cl") then
      st.cleanupOpen = true
      st.cleanupPick = {}
      for _, e in ipairs(Cat.cleanupCandidates(limit)) do st.cleanupPick[#st.cleanupPick + 1] = { e = e, on = true } end
      R.ImGui_OpenPopup(ctx, "Clean up##cleanup")
    end
  end
  if st.cleanupOpen and R.ImGui_BeginPopupModal(ctx, "Clean up##cleanup", nil, R.ImGui_WindowFlags_AlwaysAutoResize()) then
    R.ImGui_Text(ctx, "The oldest entries over your limit, without a star. They go to the trash (Undo delete).")
    if R.ImGui_BeginChild(ctx, "##cl", 520, 220, R.ImGui_ChildFlags_Borders()) then
      for i, p in ipairs(st.cleanupPick or {}) do
        local ch2, v2 = R.ImGui_Checkbox(ctx, p.e.sent .. "   " .. p.e.source .. " - " .. p.e.name .. "##cp" .. i, p.on)
        if ch2 then p.on = v2 end
      end
      R.ImGui_EndChild(ctx)
    end
    local n = 0
    for _, p in ipairs(st.cleanupPick or {}) do if p.on then n = n + 1 end end
    if R.ImGui_Button(ctx, "Move " .. n .. " to the trash##cdo") and n > 0 then
      local done = {}
      for _, p in ipairs(st.cleanupPick) do if p.on and Cat.delete(p.e.id) then done[#done + 1] = p.e.id end end
      if #done > 0 then st.deleted[#st.deleted + 1] = done end
      say(st, #done .. " moved to the trash")
      st.cleanupOpen, st.dirty = false, true
      R.ImGui_CloseCurrentPopup(ctx)
    end
    R.ImGui_SameLine(ctx)
    if R.ImGui_Button(ctx, "Cancel##cno") then st.cleanupOpen = false R.ImGui_CloseCurrentPopup(ctx) end
    R.ImGui_EndPopup(ctx)
  end
end

-- ---------------------------------------------------------------- the widget

function P.draw(ctx, st, opts)
  opts = opts or {}
  refresh(st, opts)
  st.hover = nil

  -- search
  local w = R.ImGui_GetContentRegionAvail(ctx)
  R.ImGui_SetNextItemWidth(ctx, w)
  local ch, v = R.ImGui_InputTextWithHint(ctx, "##query", HINT, st.query)
  if ch then st.query, st.dirty = v, true end
  if st.qerr then R.ImGui_TextColored(ctx, C.err, "search: " .. st.qerr .. " (the list is not filtered)") end

  -- date and sort
  R.ImGui_SetNextItemWidth(ctx, 120)
  local dch, dv = R.ImGui_Combo(ctx, "##date", st.dateMode, DATE_ITEMS)
  if dch then st.dateMode, st.dirty = dv, true end
  if st.dateMode == 4 then
    R.ImGui_SameLine(ctx, 0, 6)
    R.ImGui_SetNextItemWidth(ctx, 100)
    local fch, fv = R.ImGui_InputTextWithHint(ctx, "##from", "YYYY-MM-DD", st.from)
    if fch then st.from, st.dirty = fv, true end
    R.ImGui_SameLine(ctx, 0, 6)
    R.ImGui_SetNextItemWidth(ctx, 100)
    local tch, tv = R.ImGui_InputTextWithHint(ctx, "##to", "YYYY-MM-DD", st.to)
    if tch then st.to, st.dirty = tv, true end
  end
  R.ImGui_SameLine(ctx, 0, 12)
  R.ImGui_SetNextItemWidth(ctx, 120)
  local sch, sv = R.ImGui_Combo(ctx, "##sort", st.sort, SORT_ITEMS)
  if sch then st.sort, st.dirty = sv, true end
  R.ImGui_SameLine(ctx, 0, 12)
  R.ImGui_TextColored(ctx, C.dim, string.format("%d of %d", #st.list, st.total))
  if (st.nUsed or 0) > 0 then
    R.ImGui_SameLine(ctx, 0, 8)
    R.ImGui_TextColored(ctx, C.used, string.format("%d used in this project", st.nUsed))
  end
  if st.query ~= "" or st.dateMode ~= 0 then
    R.ImGui_SameLine(ctx, 0, 12)
    if R.ImGui_SmallButton(ctx, "Clear##clr") then st.query, st.dateMode, st.dirty = "", 0, true end
  end

  chipsRow(ctx, st)

  -- the grid takes what the panel and the bottom line leave
  local panelH = opts.panelH or (opts.browser and 250 or 196)   -- the browser also lists where an entry is used
  local bottomH = opts.browser and 58 or 0
  local used = select(2, R.ImGui_GetContentRegionAvail(ctx))
  local gridH = opts.gridH or math.max(80, (opts.height and math.min(opts.height, used) or used) - panelH - bottomH - 12)
  local taken = grid(ctx, st, opts, gridH)

  infoPanel(ctx, st, opts, st.hover or (st.focus and (function() for _, e in ipairs(st.list) do if e.id == st.focus then return e end end end)()), panelH)

  if opts.browser then
    cleanupLine(ctx, st)
    if #st.deleted > 0 then
      R.ImGui_SameLine(ctx, 0, 12)
      if R.ImGui_SmallButton(ctx, "Undo delete##undo") then
        local ids = table.remove(st.deleted)
        for _, id in ipairs(ids) do Cat.undelete(id) end
        st.dirty = true
        say(st, #ids == 1 and "brought back" or (#ids .. " brought back"))
      end
    end
    if st.msg and R.time_precise() - st.msgAt < 6 then
      R.ImGui_SameLine(ctx, 0, 12)
      R.ImGui_TextColored(ctx, C.ok, st.msg)
    end
    -- the setting of ReaCat.markItem: besides the line in the item's notes, the curve's name is added to the item's name (off by default)
    local suffixOn = Cat.nameSuffixOn()
    local sch, sv = R.ImGui_Checkbox(ctx, "Also add the curve to the item's name when a tool uses it on an item##namesuffix", suffixOn)
    if sch then Cat.setNameSuffixOn(sv) end
  end
  return taken
end

-- ---------------------------------------------------------------- the receiver's two ways to take

-- opts: kind / rulekind / accept(header) -> true: what this receiver can take (accept needs an acceptKey, a word that changes with it)
local function accepted(h, opts)
  if opts.kind and h.kind ~= opts.kind then return false end
  if opts.rulekind and h.rulekind ~= opts.rulekind then return false end
  if opts.accept and not opts.accept(h) then return false end
  return true
end

-- The newest entry the receiver can take, from any source (the header only), or nil.
function P.latest(opts)
  opts = opts or {}
  for _, h in ipairs(Cat.list()) do            -- newest first
    if accepted(h, opts) then return h end
  end
  return nil
end

-- Two buttons: "Latest" takes the newest entry the receiver accepts; "ReaCat..." opens the picker under the buttons.
-- Returns nil, or { id =, entry = (ReaCat.get), originalRange = true | false, how = "latest" | "picked" } on the frame something was taken.
function P.receiver(ctx, st, opts)
  opts = opts or {}
  local taken
  local bh = opts.buttonH or 0
  if R.ImGui_Button(ctx, "Latest##rclatest", 80, bh) then
    local h = P.latest(opts)
    local e = h and Cat.get(h.id)
    if e then taken = { id = h.id, entry = e, originalRange = false, how = "latest" } st.rOpen, st.rmsg = false, nil
    else st.rmsg = "nothing to take yet" end
  end
  R.ImGui_SameLine(ctx, 0, 6)
  local on = st.rOpen and not opts.popup
  if on then R.ImGui_PushStyleColor(ctx, R.ImGui_Col_Button(), 0x2E6BA8FF) end
  if R.ImGui_Button(ctx, "ReaCat...##rcopen", 90, bh) then
    st.rmsg = nil
    if opts.popup then R.ImGui_OpenPopup(ctx, opts.popup) st.rOpen = true else st.rOpen = not st.rOpen end
  end
  if on then R.ImGui_PopStyleColor(ctx) end
  if st.rmsg then
    R.ImGui_SameLine(ctx, 0, 10)
    R.ImGui_TextColored(ctx, C.dim, st.rmsg)
  end
  local drawOpts = { kind = opts.kind, rulekind = opts.rulekind, accept = opts.accept, acceptKey = opts.acceptKey,
                     gridH = opts.gridH or 230, panelH = opts.panelH, noRange = opts.noRange }
  local function pick()
    R.ImGui_Dummy(ctx, opts.width or 680, 1)
    local t = P.draw(ctx, st, drawOpts)
    if t then
      local e = Cat.get(t.id)
      if e then taken = { id = t.id, entry = e, originalRange = t.originalRange, how = "picked" } st.rOpen = false end
    end
  end
  if opts.popup then
    -- the picker in a popup of its own (for a tool whose window is too narrow to hold it)
    if R.ImGui_BeginPopup(ctx, opts.popup) then
      pick()
      if taken then R.ImGui_CloseCurrentPopup(ctx) end
      R.ImGui_EndPopup(ctx)
    end
  elseif st.rOpen then
    pick()
  end
  return taken
end

P._refresh = refresh
P._selectedIds = selectedIds
P._tagTargets = tagTargets

return P
