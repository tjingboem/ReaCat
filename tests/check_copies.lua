-- check_copies.lua: every tool's copy of lib/ReaCat.lua (and ReaCatPicker.lua) is identical to this repo's. Run from the repo root:
--   lua5.4 tests/check_copies.lua
-- Copies that do not exist yet are skipped; add a path to COPIES when a tool gets its own.
local COPIES = {
  { "lib/ReaCat.lua", "../ReaNvelopes/lib/ReaCat.lua" },
  { "lib/ReaCat.lua", "../ReaAC/core/ReaCat.lua" },
  { "lib/ReaCatPicker.lua", "../ReaAC/core/ReaCatPicker.lua" },
  { "lib/ReaCat.lua", "../ReaMaskM/ReaCat.lua" },
  { "lib/ReaCatPicker.lua", "../ReaMaskM/ReaCatPicker.lua" },
  { "lib/ReaCat.lua", "../ReaShapeM/ReaCat.lua" },
  { "lib/ReaCatPicker.lua", "../ReaShapeM/ReaCatPicker.lua" },
}
local function read(p) local f = io.open(p, "rb") if not f then return nil end local s = f:read("a") f:close() return s end
local bad = 0
for _, c in ipairs(COPIES) do
  local a, b = read(c[1]), read(c[2])
  if not b then print("skipped (no copy): " .. c[2])
  elseif a ~= b then print("DIFFERENT: " .. c[2]) bad = bad + 1
  else print("same: " .. c[2]) end
end
os.exit(bad == 0 and 0 or 1)
