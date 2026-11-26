-- trash_rules.lua (26 Nov 2026): moves every RULE entry of the catalogue into the trash (ReaCat is a catalogue of shapes; rules are no longer sent).
-- Nothing is deleted for good: the files go to <resource path>/Data/ReaCat/_trash and can be brought back (move them back by hand).
-- Run from the repo root, with any REAPER closed or open:   lua5.4 tools/trash_rules.lua [REAPER resource path]   (default ~/.config/REAPER)
package.path = "lib/?.lua;" .. package.path
local res = arg[1] or ((os.getenv("HOME") or "") .. "/.config/REAPER")
local ext = {}
reaper = {
  GetResourcePath = function() return res end,
  RecursiveCreateDirectory = function(p) os.execute("mkdir -p '" .. p .. "'") return 1 end,
  EnumerateFiles = function(dir, i)
    if i < 0 then return nil end
    local p = io.popen("find '" .. dir .. "' -maxdepth 1 -type f 2>/dev/null | sort")
    local k = 0
    for path in p:lines() do if k == i then p:close() return (path:match("([^/]+)$")) end k = k + 1 end
    p:close() return nil
  end,
  GetExtState = function(s, k) return ext[s .. "/" .. k] or "" end,
  SetExtState = function(s, k, v) ext[s .. "/" .. k] = v end,
}
local Cat = require("ReaCat")
local n = 0
for _, e in ipairs(Cat.list{ kind = "rule" }) do
  local ok, err = Cat.delete(e.id)
  print((ok and "to the trash: " or "FAILED: ") .. e.id .. "  " .. tostring(e.source) .. " - " .. tostring(e.name) .. (ok and "" or ("  " .. tostring(err))))
  if ok then n = n + 1 end
end
print(n .. " rule entr" .. (n == 1 and "y" or "ies") .. " moved to the trash")
