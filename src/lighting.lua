local dither = require("src.dither")

---@class LightingRamp
---@field dither DitherRamp
---@field colors integer[]
local LightingRamp = {}
LightingRamp.__index = LightingRamp


local lighting = {}

function lighting.new()
  self = setmetatable({}, LightingRamp)

  -- self.dither = dither.new_hatched(true, true)
  -- self.dither = dither.new_hatched(false, true)
  self.dither = dither.new_hatched(false, false)
  -- self.colors = {33, 34, 35, 36, 37}
  self.colors = {34, 35, 36}

  return self
end

---@param t number value in [0,1]
function LightingRamp:set_lighting(t)
  t = mid(-1, t, 1)
  t = (t+1) / 2
  printh(t)
  
  local len = #self.colors - 1
  local c0_idx = flr(t * len)
  local c1_idx = flr(t * len) + 1

  local c0 = self.colors[c0_idx+1]
  local c1 = self.colors[c1_idx+1]

  local col = (c1 << 8) | c0

  color(col)
  local dither_t = (t * len) % 1
  self.dither:set_dither(dither_t)
end

function LightingRamp:clear()
  color()
  fillp()
end

return lighting
